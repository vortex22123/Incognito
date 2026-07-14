#!/bin/bash
# scripts/build/build-debian-base.sh
# Incognito OS - Debian minimal base approach
# Gantikan Phase 1-3 LFS dengan debootstrap Debian minimal
# Build time: ~30-60 menit vs 8-12 jam LFS
#
# Cara pakai:
#   sudo bash scripts/build/build-debian-base.sh
#
# Output: incognito-os-YYYYMMDD.iso di root repo

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$SCRIPT_DIR/common.sh"

# --- Konfigurasi ---
TARGET="$REPO_ROOT/build-root"      # chroot directory
ISO_DIR="$REPO_ROOT/iso-staging"    # staging ISO filesystem
ISO_OUT="$REPO_ROOT/incognito-os-$(date +%Y%m%d).iso"
DEBIAN_SUITE="bookworm"             # Debian 12 stable
DEBIAN_MIRROR="https://deb.debian.org/debian"
ARCH="amd64"

# ================================================================
# Step 1: Cek dependency host
# ================================================================
check_deps() {
    log_info "Cek dependency build host..."
    require_cmd debootstrap mksquashfs grub-mkrescue xorriso mtools wget curl
    require_root
    log_ok "Semua dependency tersedia"
}

# ================================================================
# Step 2: Bootstrap Debian minimal ke $TARGET
# ================================================================
bootstrap_base() {
    log_info "Bootstrap Debian $DEBIAN_SUITE minimal ke $TARGET ..."
    rm -rf "$TARGET"
    mkdir -p "$TARGET"

    debootstrap \
        --arch="$ARCH" \
        --variant=minbase \
        --include=systemd,systemd-sysv,dbus,ca-certificates,apt-transport-https,wget,curl,sudo,locales,console-setup,keyboard-configuration \
        "$DEBIAN_SUITE" \
        "$TARGET" \
        "$DEBIAN_MIRROR"

    log_ok "Bootstrap selesai: $(du -sh "$TARGET" | cut -f1)"
}

# ================================================================
# Step 3: Setup chroot (mount virtual filesystems)
# ================================================================
mount_chroot() {
    log_info "Mount virtual filesystems untuk chroot..."
    mount --bind /dev  "$TARGET/dev"
    mount --bind /dev/pts "$TARGET/dev/pts"
    mount -t proc  proc  "$TARGET/proc"
    mount -t sysfs sysfs "$TARGET/sys"
    mount -t tmpfs tmpfs "$TARGET/run"
}

umount_chroot() {
    log_info "Umount virtual filesystems..."
    for mnt in run sys proc dev/pts dev; do
        umount -lf "$TARGET/$mnt" 2>/dev/null || true
    done
}

# ================================================================
# Step 4: Jalankan script di dalam chroot
# ================================================================
run_in_chroot() {
    chroot "$TARGET" /bin/bash -c "$1"
}

configure_base() {
    log_info "Konfigurasi base system di dalam chroot..."

    # Hostname & hosts
    echo "incognito" > "$TARGET/etc/hostname"
    cat > "$TARGET/etc/hosts" <<'EOF'
127.0.0.1   localhost incognito
::1         localhost ip6-localhost ip6-loopback
EOF

    # Locale - tulis langsung ke file, hindari update-locale yang butuh dbus
    echo "en_US.UTF-8 UTF-8" >> "$TARGET/etc/locale.gen"
    run_in_chroot "locale-gen"
    echo "LANG=en_US.UTF-8" > "$TARGET/etc/locale.conf"
    echo "LANG=en_US.UTF-8" > "$TARGET/etc/default/locale"

    # Minimal fstab
    cat > "$TARGET/etc/fstab" <<'EOF'
proc            /proc           proc    defaults        0 0
sysfs           /sys            sysfs   defaults        0 0
tmpfs           /tmp            tmpfs   defaults,noatime 0 0
EOF

    log_ok "Base config selesai"
}

install_repos() {
    log_info "Setup APT repos: Debian only dulu..."
    cat > "$TARGET/etc/apt/sources.list" <<EOF
deb $DEBIAN_MIRROR $DEBIAN_SUITE main contrib non-free non-free-firmware
deb https://security.debian.org/debian-security $DEBIAN_SUITE-security main contrib non-free non-free-firmware
EOF

    # Install gnupg + wget - tidak ada di minbase
    run_in_chroot "apt-get update -qq && apt-get install -y --no-install-recommends gnupg wget"
    log_ok "Debian repo siap"
}

add_kali_repo() {
    log_info "Tambah Kali rolling repo..."
    # Import Kali GPG key
    run_in_chroot "wget -qO- https://archive.kali.org/archive-key.asc | gpg --dearmor -o /usr/share/keyrings/kali-archive-keyring.gpg"

    cat > "$TARGET/etc/apt/sources.list.d/kali.list" <<'EOF'
deb [signed-by=/usr/share/keyrings/kali-archive-keyring.gpg] https://http.kali.org/kali kali-rolling main contrib non-free non-free-firmware
EOF

    # Pin: Debian selalu menang untuk semua packages kecuali yang eksplisit dari Kali
    cat > "$TARGET/etc/apt/preferences.d/kali-pin" <<'EOF'
Package: *
Pin: release o=Debian
Pin-Priority: 900

Package: *
Pin: release o=Kali
Pin-Priority: 50

# Paksa packages TPM/systemd dari Debian saja - Kali versinya break dependency
Package: libtss2-* systemd-tpm libtss2-esys-* libtss2-tcti-* libtss2-mu-* libtss2-rc* libtss2-sys*
Pin: release o=Kali
Pin-Priority: -1
EOF

    run_in_chroot "apt-get update -qq"
    log_ok "Kali repo + APT pin siap"
}

install_desktop() {
    log_info "Install desktop stack (Xorg + Openbox + Polybar + Rofi + Picom)..."
    run_in_chroot "DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        xorg openbox obconf \
        polybar rofi picom \
        feh nitrogen \
        x11-utils x11-xserver-utils \
        fonts-jetbrains-mono fonts-inter \
        papirus-icon-theme \
        alacritty \
        pcmanfm \
        network-manager network-manager-gnome \
        pulseaudio \
        i3lock \
        neofetch htop"
    log_ok "Desktop stack terinstall"
}

install_tor_privacy() {
    log_info "Install Tor + privacy tools..."
    run_in_chroot "DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        tor tor-geoipdb \
        iptables \
        proxychains4 \
        obfs4proxy"

    # Copy config Tor dari repo
    cp -v "$REPO_ROOT/configs/tor/torrc" "$TARGET/etc/tor/torrc"
    log_ok "Tor terinstall"
}

install_security_tools() {
    log_info "Install security tools dari kali-tools.list..."
    local list="$REPO_ROOT/packages/kali-tools.list"
    [ -f "$list" ] || die "Tidak ketemu $list"

    # Fix tcpdump dpkg bug
    run_in_chroot "rm -f /usr/lib/sysusers.d/tcpdump.conf" 2>/dev/null || true

    local failed=()
    while IFS= read -r pkg; do
        [[ -z "$pkg" || "$pkg" == \#* ]] && continue

        # Fix nama paket yang salah/virtual/tidak tersedia
        case "$pkg" in
            ettercap)           pkg="ettercap-text-only" ;;
            arpspoof|dnsspoof)  pkg="dsniff" ;;
            rockyou)            pkg="wordlists" ;;
            mimikatz|powersploit|empire) log_warn "  -> $pkg: dilewati (Windows-only/deprecated)"; continue ;;
            linpeas)            log_warn "  -> $pkg: install manual dari github.com/carlospolop/PEASS-ng"; continue ;;
        esac

        log_info "  -> $pkg"
        # Pakai -t kali-rolling eksplisit supaya apt ambil dari Kali, bukan Debian
        # --no-install-recommends cegah tarik dependency Kali yang break base Debian
        if ! run_in_chroot "DEBIAN_FRONTEND=noninteractive apt-get install -y \
            --no-install-recommends \
            --no-install-suggests \
            -t kali-rolling \
            $pkg" 2>/dev/null; then
            log_warn "     gagal: $pkg"
            failed+=("$pkg")
        fi
    done < "$list"

    if [ ${#failed[@]} -gt 0 ]; then
        log_warn "Paket gagal (${#failed[@]}): ${failed[*]}"
    fi
    log_ok "Security tools selesai"
}

install_configs() {
    log_info "Install configs desktop (openbox/polybar/rofi/picom)..."
    local skel="$TARGET/etc/skel"
    mkdir -p "$skel/.config"

    for cfg in openbox polybar rofi picom; do
        [ -d "$REPO_ROOT/configs/$cfg" ] && \
            cp -rv "$REPO_ROOT/configs/$cfg" "$skel/.config/"
    done

    # .xinitrc
    cat > "$skel/.xinitrc" <<'EOF'
#!/bin/bash
picom --config ~/.config/picom/picom.conf &
polybar main -c ~/.config/polybar/config.ini &
exec openbox-session
EOF
    chmod +x "$skel/.xinitrc"

    # Auto-startx on TTY1
    cat >> "$skel/.bash_profile" <<'EOF'
if [ -z "$DISPLAY" ] && [ "$(tty)" = "/dev/tty1" ]; then
    exec startx
fi
EOF

    # Wallpaper
    mkdir -p "$TARGET/usr/share/backgrounds/incognito"
    [ -f "$REPO_ROOT/assets/wallpapers/default.png" ] && \
        cp "$REPO_ROOT/assets/wallpapers/default.png" "$TARGET/usr/share/backgrounds/incognito/"

    # Install scripts
    mkdir -p "$TARGET/usr/local/bin"
    cp "$REPO_ROOT/scripts/tools/tor-toggle.sh" "$TARGET/usr/local/bin/tor-toggle"
    cp "$REPO_ROOT/scripts/tools/incognito-firewall-base.sh" "$TARGET/usr/local/sbin/incognito-firewall-base.sh"
    chmod +x "$TARGET/usr/local/bin/tor-toggle" "$TARGET/usr/local/sbin/incognito-firewall-base.sh"

    # Systemd units
    cp "$REPO_ROOT/configs/systemd/incognito-firewall.service" "$TARGET/etc/systemd/system/"
    cp "$REPO_ROOT/configs/systemd/tor.service"               "$TARGET/etc/systemd/system/tor-incognito.service"
    run_in_chroot "systemctl enable incognito-firewall.service" 2>/dev/null || true

    # Welcome script
    cp "$REPO_ROOT/scripts/config/incognito-welcome.sh" "$TARGET/etc/profile.d/incognito-welcome.sh"
    chmod +x "$TARGET/etc/profile.d/incognito-welcome.sh"

    log_ok "Configs terpasang"
}

setup_bootloader() {
    log_info "Install GRUB di dalam chroot..."
    run_in_chroot "DEBIAN_FRONTEND=noninteractive apt-get install -y grub-pc linux-image-amd64 initramfs-tools"

    # Copy GRUB config & theme
    cp "$REPO_ROOT/configs/grub/grub" "$TARGET/etc/default/grub"
    mkdir -p "$TARGET/boot/grub/themes/incognito"
    [ -d "$REPO_ROOT/assets/grub-theme" ] && \
        cp -rv "$REPO_ROOT/assets/grub-theme/"* "$TARGET/boot/grub/themes/incognito/"

    run_in_chroot "update-grub" 2>/dev/null || true
    log_ok "GRUB siap"
}

# ================================================================
# Step 5: Strip bloat - buang paket yang makan RAM
# ================================================================
strip_bloat() {
    log_info "Strip bloatware untuk capai target idle RAM < 300MB..."

    # Fix broken state dulu kalau ada sisa konflik Kali/Debian
    run_in_chroot "apt-get --fix-broken install -y --no-install-recommends 2>/dev/null || true"

    # Remove TPM packages yang bikin konflik (tidak dibutuhkan untuk Incognito OS)
    run_in_chroot "apt-get remove -y --purge \
        libtss2-esys-3.0.2-0t64 libtss2-tcti-cmd0t64 systemd-tpm \
        avahi-daemon cups bluetooth bluez modemmanager \
        2>/dev/null || true"

    run_in_chroot "apt-get autoremove -y --purge 2>/dev/null || true"
    run_in_chroot "apt-get clean"
    rm -rf "$TARGET/var/cache/apt/archives/"*.deb 2>/dev/null || true
    log_ok "Bloat dibuang"
}

# ================================================================
# Step 6: Build ISO
# ================================================================
build_iso() {
    log_info "Build squashfs + ISO..."
    mkdir -p "$ISO_DIR"/{live,boot/grub}

    # Squash filesystem
    mksquashfs "$TARGET" "$ISO_DIR/live/filesystem.squashfs" \
        -comp xz -e boot 2>/dev/null
    log_ok "Squashfs: $(du -sh "$ISO_DIR/live/filesystem.squashfs" | cut -f1)"

    # Copy kernel & initrd - pakai find karena nama file ada versi kernel di dalamnya
    local vmlinuz
    vmlinuz="$(find "$TARGET/boot" -maxdepth 1 -name 'vmlinuz-*' | sort | tail -1)"
    local initrd
    initrd="$(find "$TARGET/boot" -maxdepth 1 -name 'initrd.img-*' | sort | tail -1)"

    [ -f "$vmlinuz" ] || die "Kernel tidak ditemukan di $TARGET/boot - pastikan linux-image-amd64 terinstall"
    [ -f "$initrd"  ] || die "Initrd tidak ditemukan di $TARGET/boot"

    cp "$vmlinuz" "$ISO_DIR/boot/vmlinuz"
    cp "$initrd"  "$ISO_DIR/boot/initrd.img"
    log_ok "Kernel: $(basename "$vmlinuz")"
    log_ok "Initrd: $(basename "$initrd")"

    # GRUB config untuk live ISO
    cat > "$ISO_DIR/boot/grub/grub.cfg" <<'EOF'
set default=0
set timeout=5

menuentry "Incognito OS" --class incognito {
    linux /boot/vmlinuz boot=live quiet splash
    initrd /boot/initrd.img
}

menuentry "Incognito OS (Tor Enabled at Boot)" --class incognito {
    linux /boot/vmlinuz boot=live quiet splash tor=on
    initrd /boot/initrd.img
}

menuentry "Incognito OS (Safe Mode)" --class incognito {
    linux /boot/vmlinuz boot=live
    initrd /boot/initrd.img
}
EOF

    # Build ISO pakai grub-mkrescue
    grub-mkrescue -o "$ISO_OUT" "$ISO_DIR" -volid "INCOGNITO_OS"

    local iso_size
    iso_size=$(du -sh "$ISO_OUT" | cut -f1)
    log_ok "ISO selesai: $ISO_OUT ($iso_size)"
}

# ================================================================
# Main
# ================================================================
main() {
    require_root

    trap 'log_err "Build gagal"; umount_chroot; exit 1' ERR

    check_deps
    bootstrap_base
    mount_chroot
    configure_base
    install_repos        # Debian only
    install_desktop      # dari Debian
    install_tor_privacy  # dari Debian
    setup_bootloader     # kernel + grub dari Debian SEBELUM Kali repo masuk
    add_kali_repo        # baru tambah Kali repo
    install_security_tools
    install_configs
    strip_bloat
    umount_chroot

    build_iso

    log_ok "=============================="
    log_ok "BUILD SUKSES!"
    log_ok "ISO: $ISO_OUT"
    log_ok "Size: $(du -sh "$ISO_OUT" | cut -f1)"
    log_ok "=============================="
}

main "$@"
