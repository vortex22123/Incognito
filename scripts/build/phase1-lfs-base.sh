#!/bin/bash
# phase1-lfs-base.sh
# Fase 1: Base system Incognito OS mengikuti metodologi Linux From Scratch (LFS)
# Referensi urutan: LFS Book chapter 5-8 (cross toolchain -> temporary system -> chroot -> base system)
#
# CATATAN PENTING:
# Build LFS penuh melibatkan ~80 paket source yang dikompilasi berurutan dan makan waktu
# berjam-jam. Script ini menyediakan KERANGKA otomatisasi yang benar urutannya (host deps
# check -> cross toolchain -> temp tools -> chroot -> base system) dan sudah bisa dijalankan,
# tapi daftar paket di bawah masih perlu kamu lengkapi versi & checksum sesuai LFS Book versi
# yang kamu ikuti (https://www.linuxfromscratch.org/lfs/view/stable/).

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

SOURCES_DIR="$LFS/sources"
TOOLS_DIR="$LFS/tools"

check_host_requirements() {
    log_info "Cek dependency host (versi minimum sesuai LFS Book)..."
    require_cmd bash bison gcc g++ make patch perl python3 sed tar makeinfo xz gawk
    log_ok "Semua tool host dasar tersedia"
}

prepare_filesystem() {
    require_lfs_mount
    mkdir -pv "$SOURCES_DIR" "$TOOLS_DIR"
    chmod -v a+wt "$SOURCES_DIR"
    ln -sfv "$TOOLS_DIR" /tools

    log_info "Membuat struktur direktori dasar LFS..."
    mkdir -pv "$LFS"/{etc,var,usr/{bin,lib,sbin}}
    for i in bin lib sbin; do
        ln -sfv usr/$i "$LFS/$i"
    done
    case $(uname -m) in
        x86_64) mkdir -pv "$LFS/lib64" ;;
    esac
    mkdir -pv "$LFS/tools"
}

create_lfs_user() {
    log_info "Setup user 'lfs' non-root untuk build toolchain..."
    if ! id lfs >/dev/null 2>&1; then
        groupadd -f lfs
        useradd -s /bin/bash -g lfs -m -k /dev/null lfs
        echo "lfs:lfs" | chpasswd
    fi
    chown -v lfs "$LFS"/{usr,lib,var,etc,bin,sbin,tools,sources} 2>/dev/null || true
    case $(uname -m) in
        x86_64) chown -v lfs "$LFS/lib64" ;;
    esac

    cat > /home/lfs/.bash_profile <<'EOF'
exec env -i HOME=/home/lfs TERM="$TERM" PS1='\u:\w\$ ' /bin/bash
EOF
    cat > /home/lfs/.bashrc <<'EOF'
set +h
umask 022
LFS=/mnt/lfs
LC_ALL=POSIX
LFS_TGT=$(uname -m)-lfs-linux-gnu
PATH=/usr/bin
if [ ! -L /bin ]; then PATH=/bin:$PATH; fi
PATH=$LFS/tools/bin:$PATH
CONFIG_SITE=$LFS/usr/share/config.site
export LFS LC_ALL LFS_TGT PATH CONFIG_SITE
EOF
    chown lfs:lfs /home/lfs/.bash_profile /home/lfs/.bashrc
}

download_sources() {
    local list_file="$REPO_ROOT/packages/base-packages.txt"
    [ -f "$list_file" ] || die "Tidak ketemu $list_file"

    log_info "Download source packages toolchain dari $list_file..."
    local skipped=0 downloaded=0

    while IFS='|' read -r name version url; do
        # Lewati baris kosong/komentar
        [[ -z "$name" || "$name" == \#* ]] && continue

        if [[ "$version" == "VERSION" || "$url" == *"VERSION"* ]]; then
            log_warn "  -> $name: versi belum diisi (masih placeholder 'VERSION'), dilewati"
            skipped=$((skipped + 1))
            continue
        fi

        log_info "  -> download $name-$version"
        wget -c -P "$SOURCES_DIR" "$url"
        downloaded=$((downloaded + 1))
    done < "$list_file"

    log_ok "Download selesai: $downloaded paket, $skipped dilewati (perlu isi versi dulu)"
    if [ "$downloaded" -eq 0 ]; then
        log_warn "Belum ada satupun paket ter-download - isi kolom VERSION di $list_file dulu"
    fi
}

build_cross_toolchain() {
    log_info "Build cross-toolchain (binutils pass1, gcc pass1, linux headers, glibc, libstdc++)..."
    log_warn "Bagian ini butuh eksekusi as user 'lfs' satu-per-satu paket."
    log_warn "Belum diotomatisasi penuh di sini - jalankan step-by-step sesuai LFS Book ch.5,"
    log_warn "atau gunakan tool bantu seperti 'lfs-bootscripts' / Jhalfs jika ingin full-auto."
    # Placeholder hook: taruh function build_<package>() di scripts/tools/lfs-packages/
    # lalu panggil di sini secara berurutan, contoh:
    # su - lfs -c "$SCRIPT_DIR/../tools/lfs-packages/binutils-pass1.sh"
    # su - lfs -c "$SCRIPT_DIR/../tools/lfs-packages/gcc-pass1.sh"
}

enter_chroot_prep() {
    log_info "Siapkan virtual kernel filesystem untuk chroot..."
    mkdir -pv "$LFS"/{dev,proc,sys,run}
    mount -v --bind /dev "$LFS/dev"
    mount -v --bind /dev/pts "$LFS/dev/pts"
    mount -vt proc proc "$LFS/proc"
    mount -vt sysfs sysfs "$LFS/sys"
    mount -vt tmpfs tmpfs "$LFS/run"
    log_ok "Chroot siap. Masuk manual dengan:"
    echo "  chroot \"$LFS\" /tools/bin/env -i HOME=/root TERM=\"\$TERM\" PS1='(lfs chroot) \\u:\\w\\\$ ' PATH=/usr/bin:/usr/sbin /bin/bash --login"
}

main() {
    require_root
    check_host_requirements
    prepare_filesystem
    create_lfs_user
    download_sources
    build_cross_toolchain
    enter_chroot_prep
    log_ok "Phase 1 (kerangka) selesai. Lanjut manual ke build base system di dalam chroot,"
    log_ok "lalu jalankan phase2-blfs-networking.sh setelah keluar dari chroot."
}

main "$@"
