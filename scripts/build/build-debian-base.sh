#!/bin/bash
# scripts/build/build-debian-base.sh
# Incognito OS - Complete rebuild dengan semua fix
# Flow: Boot -> Login TTY -> startx -> Full Desktop with Tor

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$SCRIPT_DIR/common.sh"

BUILD_DIR="$REPO_ROOT/lb-build"
ISO_OUT="$REPO_ROOT/incognito-os-$(date +%Y%m%d).iso"

# ================================================================
check_deps() {
    log_info "Cek dependency..."
    require_cmd lb debootstrap xorriso mtools wget curl
    require_root
    log_ok "OK"
}

# ================================================================
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
        --mirror-chroot-security http://security.debian.org/debian-security \
        --mirror-binary http://deb.debian.org/debian \
        --mirror-binary-security http://security.debian.org/debian-security \
        --archive-areas "main contrib non-free non-free-firmware" \
        --keyring-packages debian-archive-keyring \
        --linux-packages "" \
        --apt-recommends false \
        --memtest none \
        --win32-loader false \
        --zsync false

    log_ok "lb config siap"
}

# ================================================================
setup_packages() {
    log_info "Setup package lists..."
    mkdir -p "$BUILD_DIR/config/package-lists"

    cat > "$BUILD_DIR/config/package-lists/base.list.chroot" << 'EOF'
linux-image-amd64
live-boot
live-boot-initramfs-tools
live-config
live-config-systemd
systemd-sysv
sudo
bash
bash-completion
ca-certificates
wget
curl
gnupg
apt-transport-https
locales
console-setup
keyboard-configuration
openssh-client
man-db
less
EOF

    cat > "$BUILD_DIR/config/package-lists/desktop.list.chroot" << 'EOF'
xorg
xserver-xorg
xserver-xorg-video-vesa
xserver-xorg-video-fbdev
xserver-xorg-video-vmware
xinit
x11-xkb-utils
setxkbmap
openbox
obconf
tint2
feh
rofi
picom
alacritty
pcmanfm
network-manager
network-manager-gnome
fonts-dejavu
fonts-noto
fonts-liberation
pulseaudio
pavucontrol
i3lock
xclip
xsel
wmctrl
xdotool
numlockx
virtualbox-guest-utils
virtualbox-guest-x11
adwaita-icon-theme
gnome-themes-standard
gtk2-engines-murrine
EOF

    cat > "$BUILD_DIR/config/package-lists/privacy.list.chroot" << 'EOF'
tor
tor-geoipdb
iptables
proxychains4
EOF

    cat > "$BUILD_DIR/config/package-lists/security.list.chroot" << 'EOF'
nmap
netcat-traditional
tcpdump
wireshark
dsniff
macchanger
john
hashcat
aircrack-ng
nikto
dirb
net-tools
whois
dnsutils
EOF

    cat > "$BUILD_DIR/config/package-lists/utils.list.chroot" << 'EOF'
neofetch
htop
nano
vim
git
unzip
zip
tree
imagemagick
EOF

    log_ok "Package lists siap"
}

# ================================================================
setup_hooks() {
    log_info "Setup build hooks..."
    mkdir -p "$BUILD_DIR/config/hooks/normal"
    mkdir -p "$BUILD_DIR/config/hooks/live"

    # Hook 1: Kali repo + tools
    cat > "$BUILD_DIR/config/hooks/normal/0020-kali-tools.hook.chroot" << 'KALIHOOK'
#!/bin/bash
set -e
wget -qO- https://archive.kali.org/archive-key.asc | \
    gpg --dearmor -o /usr/share/keyrings/kali-archive-keyring.gpg
cat > /etc/apt/sources.list.d/kali.list << 'KALI'
deb [signed-by=/usr/share/keyrings/kali-archive-keyring.gpg] https://http.kali.org/kali kali-rolling main contrib non-free non-free-firmware
KALI
cat > /etc/apt/preferences.d/kali-pin << 'PIN'
Package: *
Pin: release o=Debian
Pin-Priority: 900
Package: *
Pin: release o=Kali
Pin-Priority: 50
Package: linux-image-* linux-headers-* libtss2-* systemd-tpm
Pin: release o=Kali
Pin-Priority: -1
PIN
apt-get update -qq
DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    hydra sqlmap gobuster metasploit-framework wordlists 2>/dev/null || true
KALIHOOK
    chmod +x "$BUILD_DIR/config/hooks/normal/0020-kali-tools.hook.chroot"

    # Hook 2: System setup - user, tor, firewall, wallpaper
    cat > "$BUILD_DIR/config/hooks/normal/0030-system-setup.hook.chroot" << 'SYSHOOK'
#!/bin/bash
set -e

# User setup
if ! id user >/dev/null 2>&1; then
    useradd -m -s /bin/bash -G sudo,audio,video,plugdev,netdev,cdrom user
fi
echo "user:live" | chpasswd
echo "root:toor" | chpasswd
echo "user ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/user

# Locale & Keyboard
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen en_US.UTF-8
echo "LANG=en_US.UTF-8" > /etc/default/locale
echo "XKBMODEL=pc105" > /etc/default/keyboard
echo "XKBLAYOUT=us" >> /etc/default/keyboard
echo "XKBVARIANT=" >> /etc/default/keyboard
echo "XKBOPTIONS=" >> /etc/default/keyboard

# Hostname & hosts
echo "incognito" > /etc/hostname
cat > /etc/hosts << 'HOSTS'
127.0.0.1   localhost incognito
::1         localhost ip6-localhost ip6-loopback
HOSTS

# Tor config
mkdir -p /etc/tor
cat > /etc/tor/torrc << 'TOR'
SocksPort 9050
ControlPort 9051
CookieAuthentication 1
TransPort 9040
DNSPort 5353
AutomapHostsOnResolve 1
Log notice syslog
ExitPolicy reject *:*
TOR

# Tor-toggle script
cat > /usr/local/bin/tor-toggle << 'TOGGLE'
#!/bin/bash
set -euo pipefail
[ "$(id -u)" -eq 0 ] || exec sudo "$0" "$@"

STATE_FILE="/run/incognito-tor-state"
TRANS_PORT=9040
DNS_PORT=5353

resolve_tor_uid() {
    id -u debian-tor 2>/dev/null || id -u tor 2>/dev/null || { echo "ERROR: tor user tidak ditemukan" >&2; exit 1; }
}

flush_all() {
    iptables -F; iptables -X
    iptables -t nat -F; iptables -t nat -X
    iptables -P INPUT ACCEPT
    iptables -P OUTPUT ACCEPT
    iptables -P FORWARD ACCEPT
}

tor_on() {
    local tor_uid; tor_uid="$(resolve_tor_uid)"
    systemctl start tor; sleep 2
    flush_all
    iptables -P INPUT DROP
    iptables -P FORWARD DROP
    iptables -P OUTPUT DROP
    iptables -A INPUT -i lo -j ACCEPT
    iptables -A OUTPUT -o lo -j ACCEPT
    iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
    iptables -A OUTPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
    iptables -A OUTPUT -m owner --uid-owner "$tor_uid" -j ACCEPT
    iptables -t nat -A OUTPUT -p udp --dport 53 -j REDIRECT --to-ports "$DNS_PORT"
    iptables -t nat -A OUTPUT -p tcp --syn -m owner ! --uid-owner "$tor_uid" -j REDIRECT --to-ports "$TRANS_PORT"
    echo "on" > "$STATE_FILE"
    echo "🟢 TOR ON"
}

tor_off() {
    systemctl stop tor 2>/dev/null || true
    flush_all
    iptables -P INPUT DROP
    iptables -P FORWARD DROP
    iptables -P OUTPUT ACCEPT
    iptables -A INPUT -i lo -j ACCEPT
    iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
    echo "off" > "$STATE_FILE"
    echo "🔴 TOR OFF"
}

case "${1:-toggle}" in
    on)     tor_on ;;
    off)    tor_off ;;
    status) [ -f "$STATE_FILE" ] && cat "$STATE_FILE" || echo "off" ;;
    toggle) systemctl is-active --quiet tor 2>/dev/null && tor_off || tor_on ;;
    *) echo "Usage: $0 {on|off|status|toggle}"; exit 1 ;;
esac
TOGGLE
chmod +x /usr/local/bin/tor-toggle

# Firewall baseline
cat > /usr/local/sbin/incognito-firewall-base.sh << 'FW'
#!/bin/bash
iptables -F; iptables -X
iptables -t nat -F; iptables -t nat -X
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT ACCEPT
iptables -A INPUT -i lo -j ACCEPT
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
FW
chmod +x /usr/local/sbin/incognito-firewall-base.sh

# Firewall systemd service - auto-start
cat > /etc/systemd/system/incognito-firewall.service << 'SVC'
[Unit]
Description=Incognito OS baseline firewall
Before=tor.service
After=network.target

[Service]
Type=oneshot
ExecStart=/usr/local/sbin/incognito-firewall-base.sh
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
SVC
systemctl enable incognito-firewall.service
systemctl start incognito-firewall.service 2>/dev/null || true

# Create wallpaper - gradient pattern dengan convert
mkdir -p /usr/share/backgrounds/incognito
if command -v convert >/dev/null 2>&1; then
    # Create 1920x1200 dark gradient wallpaper
    convert -size 1920x1200 \
        gradient:rgba\(13,17,23,1\)-rgba\(30,54,87,1\) \
        /usr/share/backgrounds/incognito/default.png
else
    # Fallback: create solid color
    convert -size 1920x1200 \
        xc:"#0d1117" \
        /usr/share/backgrounds/incognito/default.png
fi

# Disable live-config autologin
mkdir -p /etc/live/config.conf.d/
cat > /etc/live/config.conf.d/noautologin.conf << 'NOAUTO'
LIVE_CONFIG_NOAUTOLOGIN=true
LIVE_CONFIG_NOEJECT=true
NOAUTO

# Reset getty
rm -f /etc/systemd/system/getty@tty1.service.d/autologin.conf
systemctl enable getty@tty1 2>/dev/null || true

echo "System setup done"
SYSHOOK
    chmod +x "$BUILD_DIR/config/hooks/normal/0030-system-setup.hook.chroot"

    # Hook 3: Desktop config - openbox, tint2, rofi, shortcuts
    cat > "$BUILD_DIR/config/hooks/normal/0040-desktop-config.hook.chroot" << 'DESKHOOKUNDEF'
#!/bin/bash
set -e
USER_HOME="/home/user"
mkdir -p "$USER_HOME/.config/openbox"
mkdir -p "$USER_HOME/.config/tint2"
mkdir -p "$USER_HOME/.config/rofi"
mkdir -p "$USER_HOME/.config/picom"
mkdir -p "$USER_HOME/Desktop"

# Openbox rc.xml dengan proper menu + theme
cat > "$USER_HOME/.config/openbox/rc.xml" << 'RCXML'
<?xml version="1.0" encoding="UTF-8"?>
<openbox_config xmlns="http://openbox.org/3.4/rc">
  <resistance><strength>10</strength><screen_edge_strength>20</screen_edge_strength></resistance>
  <focus><focusNew>yes</focusNew><followMouse>no</followMouse></focus>
  <theme>
    <name>Adwaita</name>
    <titleLayout>NLIMC</titleLayout>
    <font place="ActiveWindow"><name>DejaVu Sans</name><size>9</size><weight>Bold</weight></font>
    <font place="InactiveWindow"><name>DejaVu Sans</name><size>9</size><weight>Normal</weight></font>
  </theme>
  <desktops>
    <number>4</number>
    <names>
      <name>1:Main</name><name>2:Web</name><name>3:Tools</name><name>4:Misc</name>
    </names>
    <firstdesk>1</firstdesk>
    <popupTime>875</popupTime>
  </desktops>
  <keyboard>
    <keybind key="Super_L-Return"><action name="Execute"><command>alacritty</command></action></keybind>
    <keybind key="Super_L-d"><action name="Execute"><command>rofi -show drun</command></action></keybind>
    <keybind key="Super_L-e"><action name="Execute"><command>pcmanfm</command></action></keybind>
    <keybind key="Super_L-t"><action name="Execute"><command>alacritty -e tor-toggle toggle</command></action></keybind>
    <keybind key="Super_L-1"><action name="GoToDesktop"><to>1</to></action></keybind>
    <keybind key="Super_L-2"><action name="GoToDesktop"><to>2</to></action></keybind>
    <keybind key="Super_L-3"><action name="GoToDesktop"><to>3</to></action></keybind>
    <keybind key="Super_L-4"><action name="GoToDesktop"><to>4</to></action></keybind>
    <keybind key="A-F4"><action name="Close"/></keybind>
    <keybind key="A-Tab"><action name="NextWindow"/></keybind>
    <keybind key="A-S-Tab"><action name="PreviousWindow"/></keybind>
  </keyboard>
  <mouse>
    <context name="Desktop">
      <mousebind button="Right" action="Press">
        <action name="ShowMenu"><menu>root-menu</menu></action>
      </mousebind>
      <mousebind button="Middle" action="Press">
        <action name="ShowMenu"><menu>client-list-combined-menu</menu></action>
      </mousebind>
    </context>
    <context name="Frame">
      <mousebind button="A-Left" action="Press">
        <action name="Focus"/><action name="Raise"/>
      </mousebind>
      <mousebind button="A-Left" action="Drag">
        <action name="Move"/>
      </mousebind>
      <mousebind button="A-Right" action="Press">
        <action name="Focus"/><action name="Raise"/>
      </mousebind>
      <mousebind button="A-Right" action="Drag">
        <action name="Resize"/>
      </mousebind>
    </context>
    <context name="Titlebar">
      <mousebind button="Left" action="Drag">
        <action name="Move"/>
      </mousebind>
      <mousebind button="Left" action="DoubleClick">
        <action name="ToggleMaximize"/>
      </mousebind>
    </context>
  </mouse>
  <menu>
    <file>/home/user/.config/openbox/menu.xml</file>
    <hideDelay>200</hideDelay>
    <middle>no</middle>
    <submenuShowDelay>100</submenuShowDelay>
    <submenuHideDelay>400</submenuHideDelay>
    <showIcons>yes</showIcons>
  </menu>
</openbox_config>
RCXML

# Menu XML dengan semua aplikasi
cat > "$USER_HOME/.config/openbox/menu.xml" << 'MENUXML'
<?xml version="1.0" encoding="utf-8"?>
<openbox_menu xmlns="http://openbox.org/3.4/menu">
  <menu id="root-menu" label="Incognito OS">
    <item label="Terminal"><action name="Execute"><command>alacritty</command></action></item>
    <item label="File Manager"><action name="Execute"><command>pcmanfm</command></action></item>
    <item label="App Launcher"><action name="Execute"><command>rofi -show drun</command></action></item>
    <item label="Run Command"><action name="Execute"><command>rofi -show run</command></action></item>
    <separator/>
    <menu id="tor-menu" label="Tor">
      <item label="Toggle Tor"><action name="Execute"><command>alacritty -e bash -c "sudo tor-toggle toggle; read -p 'Press Enter'"</command></action></item>
      <item label="Tor Status"><action name="Execute"><command>alacritty -e bash -c "systemctl status tor; read -p 'Press Enter'"</command></action></item>
      <item label="Tor Logs"><action name="Execute"><command>alacritty -e bash -c "sudo journalctl -u tor -f"</command></action></item>
    </menu>
    <menu id="tools-menu" label="Security Tools">
      <item label="Nmap"><action name="Execute"><command>alacritty -e nmap</command></action></item>
      <item label="Wireshark"><action name="Execute"><command>wireshark</command></action></item>
      <item label="TCPDump"><action name="Execute"><command>alacritty -e sudo tcpdump -i any</command></action></item>
      <item label="Dsniff"><action name="Execute"><command>alacritty -e bash -c "arpspoof -h"</command></action></item>
    </menu>
    <menu id="system-menu" label="System">
      <item label="Settings"><action name="Execute"><command>alacritty -e bash -c "echo 'System settings'; read"</command></action></item>
      <item label="Keyboard Layout"><action name="Execute"><command>alacritty -e setxkbmap -layout</command></action></item>
      <item label="Firewall Status"><action name="Execute"><command>alacritty -e bash -c "sudo iptables -L -n | less"</command></action></item>
    </menu>
    <separator/>
    <item label="Lock Screen"><action name="Execute"><command>i3lock -c 0d1117 -n</command></action></item>
    <item label="Reconfigure"><action name="Reconfigure"/></item>
    <item label="Exit"><action name="Exit"/></item>
  </menu>
</openbox_menu>
MENUXML

# Openbox autostart
cat > "$USER_HOME/.config/openbox/autostart" << 'AUTOSTART'
#!/bin/bash
# VirtualBox guest services
VBoxClient --clipboard 2>/dev/null &
VBoxClient --display 2>/dev/null &
VBoxClient --seamless 2>/dev/null &

# Wallpaper & display
xsetroot -solid "#0d1117"
feh --bg-scale /usr/share/backgrounds/incognito/default.png 2>/dev/null || true

# Network
nm-applet 2>/dev/null &

# Compositor
picom -b 2>/dev/null &

# Taskbar
sleep 1
tint2 2>/dev/null &
AUTOSTART

# Tint2 config
cat > "$USER_HOME/.config/tint2/tint2rc" << 'TINT2RC'
panel_monitor = all
panel_position = bottom center horizontal
panel_size = 100% 32
panel_margin = 0 0
panel_padding = 2 0 2
panel_dock = 0
panel_layer = normal
wm_menu = 1
panel_background_id = 1
taskbar_mode = multi_desktop
taskbar_padding = 0 3 4
task_text = 1
task_icon = 1
task_maximum_size = 200 35
task_padding = 6 3
task_active_background_id = 2
task_background_id = 3
time1_format = %H:%M:%S
time1_font = DejaVu Sans 10
clock_padding = 4 0
clock_background_id = 0
systray_padding = 0 4 4
systray_background_id = 0
systray_sort = ascending

rounded = 0
border_width = 0
background_color = #0d1117 100
border_color = #30363d 100

rounded = 3
border_width = 1
background_color = #21262d 100
border_color = #58a6ff 100

rounded = 3
border_width = 1
background_color = #161b22 100
border_color = #30363d 50
TINT2RC

# Picom config
cat > "$USER_HOME/.config/picom/picom.conf" << 'PICOMRC'
backend = "xrender";
vsync = true;
shadow = false;
fading = true;
fade-delta = 4;
fade-in-step = 0.04;
fade-out-step = 0.04;
inactive-opacity = 0.95;
active-opacity = 1.0;
PICOMRC

# Rofi config
mkdir -p "$USER_HOME/.config/rofi"
cat > "$USER_HOME/.config/rofi/config.rasi" << 'ROFIRC'
configuration {
    modi: "drun,run";
    show-icons: true;
    font: "DejaVu Sans 11";
    display-drun: "Apps";
    display-run: "Run";
    display-ssh: "SSH";
}
* {
    bg: #0d1117;
    fg: #c9d1d9;
    accent: #58a6ff;
    background-color: @bg;
    text-color: @fg;
}
window { width: 50%; border: 2px; border-color: @accent; }
listview { columns: 2; }
element selected { background-color: #21262d; text-color: @accent; }
ROFIRC

# .xinitrc
cat > "$USER_HOME/.xinitrc" << 'XINITRC'
#!/bin/bash
exec > /tmp/xinitrc.log 2>&1
echo "=== xinitrc start $(date) ==="
xsetroot -solid "#0d1117"
xrandr --auto 2>/dev/null || true
exec openbox-session
XINITRC
chmod +x "$USER_HOME/.xinitrc"

# .bash_profile - TTY welcome & startx prompt
cat > "$USER_HOME/.bash_profile" << 'PROFRC'
export PATH="$PATH:/usr/local/bin"
[[ -f ~/.bashrc ]] && source ~/.bashrc
if [ -z "$DISPLAY" ] && [ "$(tty)" = "/dev/tty1" ]; then
    clear
    cat << 'WELCOME'

  ██╗███╗   ██╗ ██████╗ ██████╗  ██████╗ ███╗  ██╗██╗████████╗ ██████╗ 
  ██║████╗  ██║██╔════╝██╔═══██╗██╔════╝ ████╗ ██║██║╚══██╔══╝██╔═══██╗
  ██║██╔██╗ ██║██║     ██║   ██║██║  ███╗██╔██╗██║██║   ██║   ██║   ██║
  ██║██║╚██╗██║██║     ██║   ██║██║   ██║██║╚████║██║   ██║   ██║   ██║
  ██║██║ ╚████║╚██████╗╚██████╔╝╚██████╔╝██║ ╚███║██║   ██║   ╚██████╔╝
  ╚═╝╚═╝  ╚═══╝ ╚═════╝ ╚═════╝  ╚═════╝ ╚═╝  ╚══╝╚═╝   ╚═╝    ╚═════╝ 
WELCOME
    echo ""
    echo "  Privacy-focused Linux | Based on Debian 12 (Bookworm)"
    echo "  Kernel: $(uname -r) | Tor: $(systemctl is-active tor 2>/dev/null || echo 'OFF')"
    echo ""
    echo "  Keyboard: $(setxkbmap -query 2>/dev/null | grep layout | awk '{print $2}' || echo 'us')"
    echo ""
    echo "  🚀 Available commands:"
    echo "     startx                   - Start desktop"
    echo "     sudo tor-toggle on/off   - Enable/disable Tor routing"
    echo "     tor-toggle status        - Check Tor status"
    echo "     sudo setxkbmap de        - Change keyboard layout"
    echo "     neofetch                 - System info"
    echo ""
fi
PROFRC

# .bashrc dengan aliases
cat > "$USER_HOME/.bashrc" << 'BASHRC'
export HISTSIZE=5000
export HISTFILESIZE=10000
PS1='\[\033[01;32m\][\u@incognito]\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
alias ls='ls --color=auto -h'
alias ll='ls -lah'
alias grep='grep --color=auto'
alias diff='diff --color=auto'
alias ip='ip -c'
alias tor-status='systemctl status tor'
alias myip='curl -s ifconfig.me'
alias torip='torify curl -s ifconfig.me'
alias desk-wallpaper='feh --bg-scale'
alias desk-theme='rofi-theme-selector'
BASHRC

# Desktop shortcuts / .desktop files
cat > "$USER_HOME/Desktop/Terminal.desktop" << 'DESKTOP'
[Desktop Entry]
Version=1.0
Type=Application
Name=Terminal
Comment=Alacritty Terminal
Exec=alacritty
Icon=utilities-terminal
Terminal=false
Categories=Utility;TerminalEmulator;
DESKTOP

cat > "$USER_HOME/Desktop/FileManager.desktop" << 'DESKTOP'
[Desktop Entry]
Version=1.0
Type=Application
Name=File Manager
Comment=PCManFM
Exec=pcmanfm
Icon=system-file-manager
Terminal=false
Categories=System;FileManager;
DESKTOP

cat > "$USER_HOME/Desktop/Tor-Toggle.desktop" << 'DESKTOP'
[Desktop Entry]
Version=1.0
Type=Application
Name=Toggle Tor
Comment=Enable/Disable Tor Routing
Exec=alacritty -e bash -c "sudo tor-toggle toggle; read -p 'Press Enter'"
Icon=network-vpn
Terminal=false
Categories=Utility;Network;
DESKTOP

# Permissions
chown -R user:user "$USER_HOME"
chmod +x "$USER_HOME/.xinitrc"
chmod +x "$USER_HOME/Desktop/"*.desktop

echo "Desktop config done"
DESKHOOKUNDEF
    chmod +x "$BUILD_DIR/config/hooks/normal/0040-desktop-config.hook.chroot"

    log_ok "Hooks siap"
}

# ================================================================
build() {
    log_info "Build ISO..."
    cd "$BUILD_DIR"
    lb build 2>&1
    log_ok "Build selesai"
}

collect_iso() {
    local built_iso
    built_iso="$(find "$BUILD_DIR" -maxdepth 1 -name "*.iso" | head -1)"
    [ -f "$built_iso" ] || die "ISO tidak ditemukan"
    cp "$built_iso" "$ISO_OUT"
    log_ok "ISO: $ISO_OUT ($(du -sh "$ISO_OUT" | cut -f1))"
}

# ================================================================
main() {
    require_root
    check_deps
    setup_lb
    setup_packages
    setup_hooks
    build
    collect_iso

    log_ok "=============================="
    log_ok "BUILD SUKSES: $ISO_OUT"
    log_ok ""
    log_ok "LOGIN: user / live"
    log_ok "STARTX: ketik 'startx'"
    log_ok "TOR TOGGLE: sudo tor-toggle on/off"
    log_ok "DESKTOP: Super key + Right click"
    log_ok "=============================="
}

main "$@"
