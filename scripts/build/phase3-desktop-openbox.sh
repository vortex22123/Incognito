#!/bin/bash
# phase3-desktop-openbox.sh
# Fase 3: Desktop environment - Xorg + Openbox + Polybar + Rofi + Picom

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

build_xorg() {
    log_info "Build Xorg server minimal (BLFS ch. X Window System)..."
    log_warn "Tambahkan build script xorg-server + driver di scripts/tools/blfs-packages/xorg.sh"
}

build_wm_stack() {
    log_info "Build Openbox, Polybar, Rofi, Picom dari source..."
    log_warn "Tambahkan masing-masing sebagai sub-script:"
    log_warn "  scripts/tools/blfs-packages/openbox.sh"
    log_warn "  scripts/tools/blfs-packages/polybar.sh"
    log_warn "  scripts/tools/blfs-packages/rofi.sh"
    log_warn "  scripts/tools/blfs-packages/picom.sh"
}

install_configs() {
    log_info "Copy config dari repo ke /etc/skel dan /root (jadi default untuk user baru)..."
    local CFG="$REPO_ROOT/configs"

    for target in /etc/skel /root; do
        mkdir -p "$target/.config"
        [ -d "$CFG/openbox" ] && cp -rv "$CFG/openbox" "$target/.config/"
        [ -d "$CFG/polybar" ] && cp -rv "$CFG/polybar" "$target/.config/"
        [ -d "$CFG/rofi" ]    && cp -rv "$CFG/rofi"    "$target/.config/"
        [ -d "$CFG/picom" ]   && cp -rv "$CFG/picom"   "$target/.config/"
    done
    log_ok "Config desktop tersalin (kalau file config sumbernya ada di $CFG)"
}

install_assets() {
    log_info "Pasang wallpaper default ke /usr/share/backgrounds/incognito/..."
    local wall_src="$REPO_ROOT/assets/wallpapers"
    if [ -d "$wall_src" ] && [ -n "$(ls -A "$wall_src" 2>/dev/null)" ]; then
        mkdir -p /usr/share/backgrounds/incognito
        cp -v "$wall_src/"* /usr/share/backgrounds/incognito/
    else
        log_warn "Tidak ada file di $wall_src - lewati instalasi wallpaper"
    fi
}

setup_xinitrc() {
    log_info "Tulis default .xinitrc..."
    cat > /etc/skel/.xinitrc <<'EOF'
#!/bin/bash
picom --config ~/.config/picom/picom.conf &
polybar main -c ~/.config/polybar/config.ini &
exec openbox-session
EOF
    chmod +x /etc/skel/.xinitrc
    cp /etc/skel/.xinitrc /root/.xinitrc
}

setup_display_manager() {
    log_info "Setup autostart X on TTY1 login (tanpa DM berat, sesuai filosofi ringan)..."
    cat >> /etc/skel/.bash_profile <<'EOF'

if [ -z "$DISPLAY" ] && [ "$(tty)" = "/dev/tty1" ]; then
    exec startx
fi
EOF
}

main() {
    require_root
    build_xorg
    build_wm_stack
    install_configs
    install_assets
    setup_xinitrc
    setup_display_manager
    log_ok "Phase 3 selesai. Lanjut ke phase4-security-tools.sh"
}

main "$@"
