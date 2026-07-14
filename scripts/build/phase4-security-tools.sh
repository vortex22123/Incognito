#!/bin/bash
# phase4-security-tools.sh
# Fase 4: Install security/pentest tools yang disebut di README.
#
# CATATAN: build tools sekelas metasploit-framework, burpsuite, wireshark dari source
# murni ala LFS itu sangat berat (banyak dependency Ruby gems, Qt, dsb). Pendekatan
# paling realistis dipakai distro seperti Kali sendiri: ambil paket .deb dari repo
# Kali/Debian dan install lewat apt di dalam chroot. Script ini pakai pendekatan itu.
# Kalau kamu tetap mau full from-source, tiap tool butuh sub-script sendiri di
# scripts/tools/security-packages/.

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

# Daftar tool sesuai README (bagian "Security Tools")
# Baca daftar tool dari packages/kali-tools.list (lebih lengkap dari inline list)
# Format: satu nama paket per baris, baris # diabaikan
_load_package_list() {
    local list="$REPO_ROOT/packages/kali-tools.list"
    [ -f "$list" ] || die "Tidak ketemu $list"
    grep -v '^\s*#' "$list" | grep -v '^\s*$'
}

mapfile -t SECURITY_PACKAGES < <(_load_package_list)

add_kali_repo() {
    log_info "Tambah Kali rolling repo (sumber paket security tools)..."
    if [ ! -f /etc/apt/sources.list.d/kali.list ]; then
        cat > /etc/apt/sources.list.d/kali.list <<'EOF'
deb https://http.kali.org/kali kali-rolling main contrib non-free non-free-firmware
EOF
        log_warn "Kalau base system BUKAN Debian-based, ganti pendekatan ini dengan"
        log_warn "build-from-source per tool, atau pull binary release resmi masing-masing."
    fi

    # WAJIB: tanpa keyring ini, apt-get update gagal dengan NO_PUBKEY
    # karena repo Kali di-signed dan key-nya belum ada di keyring host/chroot.
    if ! apt-key list 2>/dev/null | grep -qi kali && \
       [ ! -f /usr/share/keyrings/kali-archive-keyring.gpg ]; then
        log_info "Import GPG key repo Kali..."
        local tmp_key="/tmp/kali-archive-keyring.gpg"
        wget -qO "$tmp_key" https://archive.kali.org/archive-key.asc \
            || die "Gagal download Kali archive key"
        gpg --dearmor < "$tmp_key" > /usr/share/keyrings/kali-archive-keyring.gpg \
            || die "Gagal import Kali archive key"
        rm -f "$tmp_key"

        # Pastikan sources.list.d entry pakai signed-by supaya konsisten dengan APT modern
        sed -i 's#^deb #deb [signed-by=/usr/share/keyrings/kali-archive-keyring.gpg] #' \
            /etc/apt/sources.list.d/kali.list
    fi

    apt-get update || die "apt-get update gagal - cek koneksi & GPG key repo Kali"
}

install_packages() {
    log_info "Install ${#SECURITY_PACKAGES[@]} security tools..."
    local failed=()
    for pkg in "${SECURITY_PACKAGES[@]}"; do
        log_info "  -> $pkg"
        if ! apt-get install -y --no-install-recommends "$pkg"; then
            log_warn "     gagal install $pkg, dicatat untuk ditinjau manual"
            failed+=("$pkg")
        fi
    done

    if [ ${#failed[@]} -gt 0 ]; then
        log_warn "Paket yang gagal: ${failed[*]}"
        log_warn "Cek nama paket di distro target (beberapa nama beda antara Debian/Kali/Arch)."
    else
        log_ok "Semua security tool berhasil terpasang"
    fi
}

record_installed_list() {
    log_info "Catat daftar versi terpasang ke packages/security-tools.lock..."
    mkdir -p "$REPO_ROOT/packages"
    {
        echo "# Auto-generated - installed $(date -u +%Y-%m-%dT%H:%M:%SZ)"
        for pkg in "${SECURITY_PACKAGES[@]}"; do
            dpkg -l "$pkg" 2>/dev/null | awk -v p="$pkg" '$2==p{print p"="$3}'
        done
    } > "$REPO_ROOT/packages/security-tools.lock"
}

main() {
    require_root
    require_cmd apt-get wget gpg
    add_kali_repo
    install_packages
    record_installed_list
    log_ok "Phase 4 selesai. Lanjut ke phase5-finalize-iso.sh"
}

main "$@"
