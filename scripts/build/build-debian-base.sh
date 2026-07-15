#!/bin/bash
# scripts/build/build-debian-base.sh
# Incognito OS - pakai live-build (lb) tool resmi Debian
# Ini cara yang BENAR untuk build live ISO Debian - semua hooks otomatis benar

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$SCRIPT_DIR/common.sh"

BUILD_DIR="$REPO_ROOT/lb-build"
ISO_OUT="$REPO_ROOT/incognito-os-$(date +%Y%m%d).iso"

check_deps() {
    log_info "Cek dependency..."
    require_cmd lb debootstrap xorriso mtools wget curl
    require_root
    log_ok "Dependency OK"
}

setup_lb() {
    log_info "Setup live-build config..."
    rm -rf "$BUILD_DIR"
    mkdir -p "$BUILD_DIR"
    cd "$BUILD_DIR"

    lb config \
        --distribution bookworm \
        --architectures amd64 \
        --binary-images iso-hybrid \
        --debian-installer none \
        --mirror-bootstrap http://deb.debian.org/debian \
        --mirror-chroot http://deb.debian.org/debian \
        --mirror-binary http://deb.debian.org/debian \
        --mirror-binary-security http://security.debian.org/debian-security \
        --archive-areas "main contrib non-free non-free-firmware" \
        --apt-recommends false \
        --memtest none \
        --win32-loader false \
        --zsync false

    log_ok "lb config siap"
}

setup_package_lists() {
    log_info "Setup package lists..."
    mkdir -p "$BUILD_DIR/config/package-lists"

    # Desktop packages
    cat > "$BUILD_DIR/config/package-lists/desktop.list.chroot" <<'EOF'
xorg
openbox
polybar
rofi
picom
feh
nitrogen
x11-utils
x11-xserver-utils
fonts-jetbrains-mono
alacritty
pcmanfm
network-manager
pulseaudio
i3lock
neofetch
htop
EOF

    # Privacy/Tor packages
    cat > "$BUILD_DIR/config/package-lists/privacy.list.chroot" <<'EOF'
tor
iptables
proxychains4
EOF

    # Kali repo + security tools
    cat > "$BUILD_DIR/config/package-lists/security.list.chroot" <<'EOF'
nmap
hydra
sqlmap
nikto
gobuster
dirb
netcat-traditional
tcpdump
john
hashcat
aircrack-ng
wireshark
dsniff
macchanger
wordlists
EOF

    log_ok "Package lists siap"
}

setup_kali_repo() {
    log_info "Setup Kali repo untuk security tools..."
    mkdir -p "$BUILD_DIR/config/archives"

    cat > "$BUILD_DIR/config/archives/kali.list.chroot" <<'EOF'
deb [signed-by=/usr/share/keyrings/kali-archive-keyring.gpg] https://http.kali.org/kali kali-rolling main contrib non-free non-free-firmware
EOF

    # Script untuk import GPG key Kali
    mkdir -p "$BUILD_DIR/config/hooks/live"
    cat > "$BUILD_DIR/config/hooks/live/0001-kali-key.hook.chroot" <<'EOF'
#!/bin/bash
wget -qO- https://archive.kali.org/archive-key.asc | gpg --dearmor -o /usr/share/keyrings/kali-archive-keyring.gpg
EOF
    chmod +x "$BUILD_DIR/config/hooks/live/0001-kali-key.hook.chroot"

    # APT pin - Debian selalu menang
    mkdir -p "$BUILD_DIR/config/apt"
    cat > "$BUILD_DIR/config/apt/preferences" <<'EOF'
Package: *
Pin: release o=Debian
Pin-Priority: 900

Package: *
Pin: release o=Kali
Pin-Priority: 50

Package: linux-image-* linux-headers-* libtss2-* systemd-tpm
Pin: release o=Kali
Pin-Priority: -1
EOF

    log_ok "Kali repo config siap"
}

setup_configs() {
    log_info "Setup configs desktop..."
    mkdir -p "$BUILD_DIR/config/includes.chroot/etc/skel/.config"
    mkdir -p "$BUILD_DIR/config/includes.chroot/etc/tor"
    mkdir -p "$BUILD_DIR/config/includes.chroot/usr/local/bin"
    mkdir -p "$BUILD_DIR/config/includes.chroot/usr/share/backgrounds/incognito"
    mkdir -p "$BUILD_DIR/config/includes.chroot/etc/profile.d"

    # Copy configs dari repo
    for cfg in openbox polybar rofi picom; do
        [ -d "$REPO_ROOT/configs/$cfg" ] && \
            cp -rv "$REPO_ROOT/configs/$cfg" \
            "$BUILD_DIR/config/includes.chroot/etc/skel/.config/"
    done

    cp "$REPO_ROOT/configs/tor/torrc" \
        "$BUILD_DIR/config/includes.chroot/etc/tor/torrc"

    cp "$REPO_ROOT/scripts/tools/tor-toggle.sh" \
        "$BUILD_DIR/config/includes.chroot/usr/local/bin/tor-toggle"
    chmod +x "$BUILD_DIR/config/includes.chroot/usr/local/bin/tor-toggle"

    [ -f "$REPO_ROOT/assets/wallpapers/default.png" ] && \
        cp "$REPO_ROOT/assets/wallpapers/default.png" \
        "$BUILD_DIR/config/includes.chroot/usr/share/backgrounds/incognito/"

    # .xinitrc
    cat > "$BUILD_DIR/config/includes.chroot/etc/skel/.xinitrc" <<'EOF'
#!/bin/bash
picom --config ~/.config/picom/picom.conf &
polybar main -c ~/.config/polybar/config.ini &
exec openbox-session
EOF
    chmod +x "$BUILD_DIR/config/includes.chroot/etc/skel/.xinitrc"

    # Auto startx on TTY1
    cat >> "$BUILD_DIR/config/includes.chroot/etc/skel/.bash_profile" <<'EOF'
if [ -z "$DISPLAY" ] && [ "$(tty)" = "/dev/tty1" ]; then
    exec startx
fi
EOF

    # Welcome script
    cp "$REPO_ROOT/scripts/config/incognito-welcome.sh" \
        "$BUILD_DIR/config/includes.chroot/etc/profile.d/"
    chmod +x "$BUILD_DIR/config/includes.chroot/etc/profile.d/incognito-welcome.sh"

    log_ok "Configs siap"
}

build() {
    log_info "Build ISO (ini butuh ~30-60 menit)..."
    cd "$BUILD_DIR"
    lb build 2>&1
    log_ok "Build selesai"
}

collect_iso() {
    local built_iso
    built_iso="$(find "$BUILD_DIR" -maxdepth 1 -name "*.iso" | head -1)"
    [ -f "$built_iso" ] || die "ISO tidak ditemukan setelah build"
    cp "$built_iso" "$ISO_OUT"
    log_ok "ISO: $ISO_OUT ($(du -sh "$ISO_OUT" | cut -f1))"
}

main() {
    require_root
    check_deps
    setup_lb
    setup_package_lists
    setup_kali_repo
    setup_configs
    build
    collect_iso

    log_ok "=============================="
    log_ok "BUILD SUKSES!"
    log_ok "ISO: $ISO_OUT"
    log_ok "=============================="
}

main "$@"
