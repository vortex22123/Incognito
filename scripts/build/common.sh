#!/bin/bash
# common.sh - Shared helpers untuk semua phase build script Incognito OS
# Di-source (bukan dijalankan langsung) oleh phase1-5

set -euo pipefail

# --- Warna output ---
C_RESET='\033[0m'
C_GREEN='\033[0;32m'
C_RED='\033[0;31m'
C_YELLOW='\033[1;33m'
C_CYAN='\033[0;36m'

log_info()  { echo -e "${C_CYAN}[INFO]${C_RESET} $*"; }
log_ok()    { echo -e "${C_GREEN}[ OK ]${C_RESET} $*"; }
log_warn()  { echo -e "${C_YELLOW}[WARN]${C_RESET} $*"; }
log_err()   { echo -e "${C_RED}[FAIL]${C_RESET} $*" >&2; }

die() { log_err "$*"; exit 1; }

# --- Path dasar (sesuaikan LFS var jika sudah ada di environment) ---
export LFS="${LFS:-/mnt/lfs}"
export LFS_TGT="${LFS_TGT:-$(uname -m)-lfs-linux-gnu}"
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
export REPO_ROOT
LOG_DIR="$REPO_ROOT/logs"
mkdir -p "$LOG_DIR"

require_root() {
    [ "$(id -u)" -eq 0 ] || die "Script ini harus dijalankan sebagai root (sudo)."
}

require_lfs_mount() {
    mountpoint -q "$LFS" || die "$LFS belum di-mount. Mount partisi build LFS dulu."
}

require_cmd() {
    for cmd in "$@"; do
        command -v "$cmd" >/dev/null 2>&1 || die "Command '$cmd' tidak ditemukan di PATH. Install dulu di host."
    done
}

step() {
    local name="$1"; shift
    log_info "=== $name ==="
    if "$@" 2>&1 | tee -a "$LOG_DIR/$(date +%Y%m%d)-build.log"; then
        log_ok "$name selesai"
    else
        die "$name gagal, cek log di $LOG_DIR"
    fi
}

confirm() {
    read -r -p "$1 [y/N] " ans
    [[ "$ans" =~ ^[Yy]$ ]]
}
