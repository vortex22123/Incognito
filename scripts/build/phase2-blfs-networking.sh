#!/bin/bash
# phase2-blfs-networking.sh
# Fase 2: Networking stack + systemd (BLFS)
# Dijalankan DI DALAM chroot LFS setelah phase1 selesai.

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

install_systemd() {
    log_info "Build & install systemd (BLFS ch. systemd)..."
    log_warn "Isi step build systemd dari source di sini (meson + ninja),"
    log_warn "atau taruh sebagai sub-script di scripts/tools/blfs-packages/systemd.sh"
    # su - lfs -c "$SCRIPT_DIR/../tools/blfs-packages/systemd.sh"
}

setup_networking_base() {
    log_info "Konfigurasi network dasar (iproute2, dhcpcd, resolv.conf)..."

    cat > /etc/hostname <<'EOF'
incognito
EOF

    cat > /etc/hosts <<'EOF'
127.0.0.1  localhost incognito
::1        localhost ip6-localhost ip6-loopback
EOF

    mkdir -p /etc/systemd/network
    cat > /etc/systemd/network/20-wired.network <<'EOF'
[Match]
Name=en*

[Network]
DHCP=yes
EOF

    systemctl enable systemd-networkd 2>/dev/null || log_warn "systemctl belum tersedia (jalankan setelah systemd terpasang penuh)"
    systemctl enable systemd-resolved 2>/dev/null || true
}

install_tor() {
    log_info "Build & install Tor..."
    log_warn "Tambahkan build script Tor dari source (butuh libevent, openssl, zlib)"
    # su - lfs -c "$SCRIPT_DIR/../tools/blfs-packages/tor.sh"

    mkdir -p /etc/tor
    local torrc_src="$REPO_ROOT/configs/tor/torrc"
    [ -f "$torrc_src" ] || die "Tidak ketemu $torrc_src"
    cp -v "$torrc_src" /etc/tor/torrc
    log_ok "Config Tor disalin dari $torrc_src ke /etc/tor/torrc"

    local unit_src="$REPO_ROOT/configs/systemd/tor.service"
    if [ -f "$unit_src" ]; then
        cp -v "$unit_src" /etc/systemd/system/tor.service
        systemctl enable tor.service 2>/dev/null || true
    fi
}

setup_iptables_base() {
    log_info "Setup iptables rules dasar (deny-by-default, akan di-override oleh tor-toggle)..."

    local unit_src="$REPO_ROOT/configs/systemd/incognito-firewall.service"
    local script_src="$REPO_ROOT/scripts/tools/incognito-firewall-base.sh"
    [ -f "$unit_src" ] || die "Tidak ketemu $unit_src"
    [ -f "$script_src" ] || die "Tidak ketemu $script_src"

    cp -v "$unit_src" /etc/systemd/system/incognito-firewall.service
    mkdir -p /usr/local/sbin
    cp -v "$script_src" /usr/local/sbin/incognito-firewall-base.sh
    chmod +x /usr/local/sbin/incognito-firewall-base.sh

    systemctl enable incognito-firewall.service 2>/dev/null || true
}

main() {
    require_root
    install_systemd
    setup_networking_base
    install_tor
    setup_iptables_base
    log_ok "Phase 2 selesai. Lanjut ke phase3-desktop-openbox.sh"
}

main "$@"
