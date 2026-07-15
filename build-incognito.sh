#!/bin/bash
# build-incognito.sh - Main build script for Incognito OS
# This script orchestrates all build phases
#
# Usage: sudo ./build-incognito.sh [phase1|phase2|phase3|phase4|phase5|all]
#
# Build Process:
#   Phase 1: Base system (LFS or Debian minimal)
#   Phase 2: Networking & Tor integration
#   Phase 3: Desktop environment (Openbox, Polybar, etc.)
#   Phase 4: Security tools from Kali
#   Phase 5: Finalize ISO

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$SCRIPT_DIR"
BUILD_LOG="$REPO_ROOT/build-$(date +%Y%m%d-%H%M%S).log"

# Colors
C_RESET='\033[0m'
C_GREEN='\033[0;32m'
C_RED='\033[0;31m'
C_YELLOW='\033[1;33m'
C_CYAN='\033[0;36m'
C_BOLD='\033[1m'

log_info()  { echo -e "${C_CYAN}[INFO]${C_RESET} $*"; }
log_ok()    { echo -e "${C_GREEN}[ OK ]${C_RESET} $*"; }
log_warn()  { echo -e "${C_YELLOW}[WARN]${C_RESET} $*"; }
log_err()   { echo -e "${C_RED}[FAIL]${C_RESET} $*" >&2; }
log_header(){ echo -e "${C_BOLD}${C_CYAN}$*${C_RESET}"; }

die() { 
    log_err "$*"
    echo ""
    log_err "Build failed. Check $BUILD_LOG for details."
    exit 1
}

require_root() {
    [ "$(id -u)" -eq 0 ] || die "This script must be run as root (sudo)."
}

check_host_requirements() {
    log_info "Checking host system requirements..."
    
    # Check for required tools
    local missing=()
    for cmd in debootstrap mksquashfs grub-mkrescue xorriso mtools wget curl gpg; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            missing+=("$cmd")
        fi
    done
    
    if [ ${#missing[@]} -gt 0 ]; then
        log_err "Missing required tools: ${missing[*]}"
        log_err "Install them with: sudo apt install ${missing[*]}"
        exit 1
    fi
    
    # Check disk space
    local free_space
    free_space=$(df -k "$REPO_ROOT" | awk 'NR==2{print $4}')
    local required_space=$((20 * 1024 * 1024)) # 20GB
    
    if [ "$free_space" -lt "$required_space" ]; then
        log_warn "Low disk space: ${free_space}KB available, ${required_space}KB recommended"
        read -p "Continue anyway? [y/N] " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
    
    log_ok "Host system requirements met"
}

show_build_menu() {
    clear
    log_header "============================================"
    log_header "  Incognito OS Build System"
    log_header "  Fast. Private. Invisible."
    log_header "============================================"
    echo ""
    echo "Build Phases:"
    echo "  1. Base System       - Debian minimal bootstrap (30-60 min)"
    echo "  2. Networking & Tor  - Tor integration and firewall rules"
    echo "  3. Desktop           - Openbox, Polybar, Rofi, Picom"
    echo "  4. Security Tools    - Kali Linux penetration testing tools"
    echo "  5. Finalize ISO      - Create bootable ISO image"
    echo ""
    echo "  all    - Run all phases (2-4 hours total)"
    echo "  clean  - Clean build artifacts"
    echo ""
    echo "Current directory: $REPO_ROOT"
    echo "Build log: $BUILD_LOG"
    echo ""
}

run_phase() {
    local phase="$1"
    local script="$SCRIPT_DIR/scripts/build/phase${phase}.sh"
    
    if [ ! -f "$script" ]; then
        # Try the Debian-based approach
        if [ "$phase" = "1" ]; then
            script="$SCRIPT_DIR/scripts/build/build-debian-base.sh"
        fi
    fi
    
    if [ ! -f "$script" ]; then
        die "Phase $phase script not found: $script"
    fi
    
    log_info "Starting Phase $phase: $(basename "$script" .sh)..."
    
    # Run with logging
    if ! bash "$script" 2>&1 | tee -a "$BUILD_LOG"; then
        die "Phase $phase failed"
    fi
    
    log_ok "Phase $phase completed successfully"
}

clean_build() {
    log_info "Cleaning build artifacts..."
    
    # Remove build directories
    rm -rf "$REPO_ROOT/build-root" 2>/dev/null || true
    rm -rf "$REPO_ROOT/iso-staging" 2>/dev/null || true
    
    # Remove ISO files
    rm -f "$REPO_ROOT"/incognito-os-*.iso 2>/dev/null || true
    
    # Remove logs
    rm -f "$REPO_ROOT"/build-*.log 2>/dev/null || true
    
    log_ok "Build artifacts cleaned"
}

main() {
    # Initialize logging
    echo "Build started: $(date)" > "$BUILD_LOG"
    echo "Incognito OS Build Log" >> "$BUILD_LOG"
    echo "=====================" >> "$BUILD_LOG"
    echo "" >> "$BUILD_LOG"
    
    require_root
    
    local action="${1:-menu}"
    
    case "$action" in
        menu|"")
            show_build_menu
            read -p "Select phase (1-5, all, clean) or 'q' to quit: " -n 1 -r
            echo
            case "$REPLY" in
                1|2|3|4|5) run_phase "$REPLY" ;;
                all) 
                    for phase in 1 2 3 4 5; do
                        run_phase "$phase"
                    done
                    ;;
                clean) clean_build ;;
                q) exit 0 ;;
                *) 
                    log_err "Invalid selection"
                    exit 1
                    ;;
            esac
            ;;
        phase1|1) run_phase "1" ;;
        phase2|2) run_phase "2" ;;
        phase3|3) run_phase "3" ;;
        phase4|4) run_phase "4" ;;
        phase5|5) run_phase "5" ;;
        all)
            check_host_requirements
            for phase in 1 2 3 4 5; do
                run_phase "$phase"
            done
            ;;
        clean) clean_build ;;
        *)
            log_err "Unknown action: $action"
            log_err "Usage: $0 [1|2|3|4|5|all|clean|menu]"
            exit 1
            ;;
    esac
    
    echo "" >> "$BUILD_LOG"
    echo "Build completed: $(date)" >> "$BUILD_LOG"
    log_ok "Build process completed!"
    log_info "Log saved to: $BUILD_LOG"
}

main "$@"
