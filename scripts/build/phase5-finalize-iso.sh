#!/bin/bash
# phase5-finalize-iso.sh
# Fase 5: Finalisasi - bootloader, cleanup, dan build ISO bootable

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

ISO_DIR="$REPO_ROOT/iso"
ISO_NAME="incognito-os-$(date +%Y%m%d).iso"

install_grub() {
    log_info "Install & konfigurasi GRUB..."
    require_cmd grub-mkrescue

    mkdir -p /etc/default
    if [ -f "$REPO_ROOT/configs/grub/grub" ]; then
        cp -v "$REPO_ROOT/configs/grub/grub" /etc/default/grub
    fi

    # Pasang theme kalau ada
    local theme_src="$REPO_ROOT/assets/grub-theme"
    if [ -d "$theme_src" ] && [ -n "$(ls -A "$theme_src" 2>/dev/null)" ]; then
        mkdir -p /boot/grub/themes/incognito
        cp -rv "$theme_src/"* /boot/grub/themes/incognito/
    fi

    log_ok "Config GRUB disiapkan. Boot image hybrid BIOS+UEFI akan dibuat oleh grub-mkrescue di build_iso()."
    log_warn "CATATAN: script ini HARUS dijalankan di dalam chroot target (bukan host build kamu)"
    log_warn "supaya grub-mkrescue membaca /etc/default/grub milik sistem target, bukan host."
}

cleanup_build_artifacts() {
    log_info "Bersihkan file build sementara supaya ISO kecil..."
    rm -rf "$LFS/sources" 2>/dev/null || true
    rm -rf "$LFS/tools" 2>/dev/null || true
    find "$LFS" -name "*.la" -delete 2>/dev/null || true
    apt-get clean 2>/dev/null || true
    log_ok "Cleanup selesai"
}

verify_targets() {
    log_info "Verifikasi performance target dari README..."
    local ram_kb
    ram_kb=$(free | awk '/Mem:/{print $3}')
    local ram_mb=$((ram_kb / 1024))
    log_info "RAM terpakai saat ini: ${ram_mb}MB (target idle < 300MB)"
    if [ "$ram_mb" -gt 300 ]; then
        log_warn "RAM idle di atas target - cek service yang jalan (systemctl list-units --state=running)"
    fi
}

build_iso() {
    log_info "Build ISO image dengan grub-mkrescue (hybrid BIOS+UEFI, wraps xorriso dengan benar)..."
    require_cmd grub-mkrescue
    mkdir -pv "$ISO_DIR"

    grub-mkrescue -o "$REPO_ROOT/$ISO_NAME" "$ISO_DIR" \
        -volid "INCOGNITO_OS" \
        -- -iso-level 3 -full-iso9660-filenames \
        || die "grub-mkrescue gagal membuat ISO"

    log_ok "ISO dibuat: $REPO_ROOT/$ISO_NAME"
}

check_iso_size() {
    local size_mb
    size_mb=$(du -m "$REPO_ROOT/$ISO_NAME" 2>/dev/null | cut -f1)
    log_info "Ukuran ISO: ${size_mb}MB (target < 2048MB)"
    if [ "${size_mb:-0}" -gt 2048 ]; then
        log_warn "ISO melebihi target - review packages/ untuk paket yang bisa di-strip"
    fi
}

main() {
    require_root
    install_grub
    cleanup_build_artifacts
    verify_targets
    build_iso
    check_iso_size
    log_ok "Build Incognito OS selesai! ISO siap di: $REPO_ROOT/$ISO_NAME"
}

main "$@"
