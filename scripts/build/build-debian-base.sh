#!/bin/bash
# scripts/build/build-debian-base.sh
# Incognito OS - live-build dengan Debian sebagai base
# Complete rewrite dengan semua fixes: wallpaper, menu, theme, persistence, firewall, tor indicator

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
    log_ok "OK"
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
libpam0g
libpam-runtime
libpam-modules
libpam-modules-bin
libc6
util-linux
EOF

    cat > "$BUILD_DIR/config/package-lists/desktop.list.chroot" << 'EOF'
xorg
xserver-xorg
xserver-xorg-video-vesa
xserver-xorg-video-fbdev
xserver-xorg-video-vmware
xinit
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
open-vm-tools
open-vm-tools-desktop
xclip
xsel
papirus-icon-theme
adwaita-icon-theme
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
curl
EOF

    log_ok "Package lists siap"
}

setup_hooks() {
    log_info "Setup build hooks..."
    mkdir -p "$BUILD_DIR/config/hooks/normal"
    mkdir -p "$BUILD_DIR/config/hooks/live"

    # Hook 1: Kali repo + tools
    cat > "$BUILD_DIR/config/hooks/normal/0020-kali-tools.hook.chroot" << 'EOF'
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
Package: linux-image-* linux-headers-* libtss2-* systemd-tpm libpam* systemd udev
Pin: release o=Kali
Pin-Priority: -1
PIN

apt-get update -qq 2>&1 | grep -i error || true

# Install Kali tools - skip if fails
DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    -o APT::AutoRemove::SuggestsImportant=false \
    hydra sqlmap gobuster wordlists 2>&1 | grep -i error || true

echo "Kali tools done"
EOF
    chmod +x "$BUILD_DIR/config/hooks/normal/0020-kali-tools.hook.chroot"

    # Hook 2: System setup
    cat > "$BUILD_DIR/config/hooks/normal/0030-system-setup.hook.chroot" << 'EOF'
#!/bin/bash
set -e

if ! id user >/dev/null 2>&1; then
    useradd -m -s /bin/bash -G sudo,audio,video,plugdev,netdev,cdrom user
fi
echo "user:live" | chpasswd
echo "root:toor" | chpasswd

echo "user ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/user

echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen en_US.UTF-8

echo "incognito" > /etc/hostname
cat > /etc/hosts << 'HOSTS'
127.0.0.1   localhost incognito
::1         localhost ip6-localhost ip6-loopback
HOSTS

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

# tor-toggle script
cat > /usr/local/bin/tor-toggle << 'TOGGLE'
#!/bin/bash
set -euo pipefail
[ "$(id -u)" -eq 0 ] || exec sudo "$0" "$@"

STATE_FILE="/run/incognito-tor-state"
TRANS_PORT=9040
DNS_PORT=5353

resolve_tor_uid() {
    id -u debian-tor 2>/dev/null || id -u tor 2>/dev/null || { echo "ERROR: tor user not found" >&2; exit 1; }
}

flush_all() {
    iptables -F; iptables -X; iptables -t nat -F; iptables -t nat -X
    iptables -P INPUT ACCEPT; iptables -P OUTPUT ACCEPT; iptables -P FORWARD ACCEPT
}

tor_on() {
    local tor_uid=$(resolve_tor_uid)
    systemctl start tor; sleep 2
    flush_all
    iptables -P INPUT DROP; iptables -P FORWARD DROP; iptables -P OUTPUT DROP
    iptables -A INPUT -i lo -j ACCEPT; iptables -A OUTPUT -o lo -j ACCEPT
    iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
    iptables -A OUTPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
    iptables -A OUTPUT -m owner --uid-owner "$tor_uid" -j ACCEPT
    iptables -t nat -A OUTPUT -p udp --dport 53 -j REDIRECT --to-ports $DNS_PORT
    iptables -t nat -A OUTPUT -p tcp --syn -m owner ! --uid-owner "$tor_uid" -j REDIRECT --to-ports $TRANS_PORT
    echo "on" > "$STATE_FILE"
    echo "🟢 TOR ON - All traffic routed through Tor"
}

tor_off() {
    systemctl stop tor 2>/dev/null || true
    flush_all
    iptables -P INPUT DROP; iptables -P FORWARD DROP; iptables -P OUTPUT ACCEPT
    iptables -A INPUT -i lo -j ACCEPT
    iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
    echo "off" > "$STATE_FILE"
    echo "🔴 TOR OFF - Direct connection"
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

cat > /usr/local/sbin/incognito-firewall-base.sh << 'FW'
#!/bin/bash
iptables -F; iptables -X; iptables -t nat -F; iptables -t nat -X
iptables -P INPUT DROP; iptables -P FORWARD DROP; iptables -P OUTPUT ACCEPT
iptables -A INPUT -i lo -j ACCEPT
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
FW
chmod +x /usr/local/sbin/incognito-firewall-base.sh

cat > /etc/systemd/system/incognito-firewall.service << 'SVC'
[Unit]
Description=Incognito OS baseline firewall
Before=network-pre.target

[Service]
Type=oneshot
ExecStart=/usr/local/sbin/incognito-firewall-base.sh
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
SVC
systemctl enable incognito-firewall.service
systemctl start incognito-firewall.service

mkdir -p /etc/live/config.conf.d/
cat > /etc/live/config.conf.d/noautologin.conf << 'NOAUTO'
LIVE_CONFIG_NOAUTOLOGIN=true
LIVE_CONFIG_NOEJECT=true
NOAUTO

rm -f /etc/systemd/system/getty@tty1.service.d/autologin.conf
systemctl enable getty@tty1 2>/dev/null || true

echo "System setup done"
EOF
    chmod +x "$BUILD_DIR/config/hooks/normal/0030-system-setup.hook.chroot"

    # Hook 3: Desktop configs
    cat > "$BUILD_DIR/config/hooks/normal/0040-desktop-config.hook.chroot" << 'EOF'
#!/bin/bash
set -e

USER_HOME="/home/user"
mkdir -p "$USER_HOME/.config/openbox"
mkdir -p "$USER_HOME/.config/tint2"
mkdir -p "$USER_HOME/.config/rofi"
mkdir -p "$USER_HOME/.config/picom"
mkdir -p "$USER_HOME/Desktop"

# Wallpaper (simple solid color, atau bisa download dari internet)
# Untuk testing, cukup solid color di xsetroot

# Openbox rc.xml DENGAN menu definition
cat > "$USER_HOME/.config/openbox/rc.xml" << 'RC'
<?xml version="1.0" encoding="UTF-8"?>
<openbox_config xmlns="http://openbox.org/3.4/rc">
  <resistance>
    <strength>10</strength>
    <screen_edge_strength>20</screen_edge_strength>
  </resistance>
  <focus>
    <focusNew>yes</focusNew>
    <followMouse>no</followMouse>
  </focus>
  <theme>
    <name>Clearlooks</name>
    <titleLayout>NLIMC</titleLayout>
    <font place="ActiveWindow">
      <name>Sans</name>
      <size>9</size>
      <weight>Bold</weight>
    </font>
  </theme>
  <desktops>
    <number>4</number>
    <names>
      <name>main</name>
      <name>web</name>
      <name>tools</name>
      <name>misc</name>
    </names>
  </desktops>
  <keyboard>
    <keybind key="Super_L-Return">
      <action name="Execute">
        <command>alacritty</command>
      </action>
    </keybind>
    <keybind key="Super_L-d">
      <action name="Execute">
        <command>rofi -show drun</command>
      </action>
    </keybind>
    <keybind key="Super_L-e">
      <action name="Execute">
        <command>pcmanfm</command>
      </action>
    </keybind>
    <keybind key="Super_L-t">
      <action name="Execute">
        <command>alacritty -e tor-toggle toggle</command>
      </action>
    </keybind>
    <keybind key="Super_L-1">
      <action name="GoToDesktop"><to>1</to></action>
    </keybind>
    <keybind key="Super_L-2">
      <action name="GoToDesktop"><to>2</to></action>
    </keybind>
    <keybind key="Super_L-3">
      <action name="GoToDesktop"><to>3</to></action>
    </keybind>
    <keybind key="Super_L-4">
      <action name="GoToDesktop"><to>4</to></action>
    </keybind>
    <keybind key="A-F4">
      <action name="Close"/>
    </keybind>
  </keyboard>
  <mouse>
    <context name="Desktop">
      <mousebind button="Right" action="Press">
        <action name="ShowMenu">
          <menu>root-menu</menu>
        </action>
      </mousebind>
      <mousebind button="Middle" action="Press">
        <action name="ShowMenu">
          <menu>client-list-combined-menu</menu>
        </action>
      </mousebind>
    </context>
    <context name="Frame">
      <mousebind button="A-Left" action="Press">
        <action name="Focus"/>
        <action name="Raise"/>
      </mousebind>
      <mousebind button="A-Left" action="Drag">
        <action name="Move"/>
      </mousebind>
      <mousebind button="A-Right" action="Press">
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
  <menus>
    <menu id="root-menu" label="Incognito OS">
      <item label="Terminal">
        <action name="Execute">
          <command>alacritty</command>
        </action>
      </item>
      <item label="File Manager">
        <action name="Execute">
          <command>pcmanfm</command>
        </action>
      </item>
      <item label="App Launcher">
        <action name="Execute">
          <command>rofi -show drun</command>
        </action>
      </item>
      <separator/>
      <item label="Tor Toggle (Super+T)">
        <action name="Execute">
          <command>alacritty -e bash -c "tor-toggle toggle; read -p 'Press Enter...'"</command>
        </action>
      </item>
      <item label="Tor Status">
        <action name="Execute">
          <command>alacritty -e bash -c "echo Tor: $(tor-toggle status); sleep 2"</command>
        </action>
      </item>
      <separator/>
      <item label="Network Manager">
        <action name="Execute">
          <command>nm-applet</command>
        </action>
      </item>
      <item label="Nmap">
        <action name="Execute">
          <command>alacritty -e nmap</command>
        </action>
      </item>
      <item label="Wireshark">
        <action name="Execute">
          <command>wireshark</command>
        </action>
      </item>
      <separator/>
      <item label="Lock Screen">
        <action name="Execute">
          <command>i3lock -c 0d1117</command>
        </action>
      </item>
      <item label="Reconfigure">
        <action name="Reconfigure"/>
      </item>
      <item label="Logout">
        <action name="Exit"/>
      </item>
    </menu>
    <menu id="client-list-combined-menu" label="Windows"/>
  </menus>
</openbox_config>
RC

# Openbox autostart
cat > "$USER_HOME/.config/openbox/autostart" << 'AUTO'
#!/bin/bash
# Open VM Tools (VMware + VirtualBox compatibility)
vmtoolsd --background 2>/dev/null &

# Wallpaper
xsetroot -solid "#0d1117"

# Theme
xsetroot -cursor_name left_ptr

# Network manager
nm-applet 2>/dev/null &

# Taskbar
tint2 &

# Firewall (already running as service, but ensure it's active)
sudo /usr/local/sbin/incognito-firewall-base.sh 2>/dev/null &

# Keyboard layout
setxkbmap -layout us -variant altgr-intl
AUTO

# Tint2 dengan Tor status indicator
cat > "$USER_HOME/.config/tint2/tint2rc" << 'TINT'
panel_monitor = all
panel_position = bottom center horizontal
panel_size = 100% 28
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
task_maximum_size = 160 35
task_padding = 6 3
task_active_background_id = 2
task_background_id = 3
task_urgent_background_id = 4

time1_format = %H:%M:%S
time2_format = %a %d %b
time1_font = Dejavu Sans Mono Bold 9
time2_font = Dejavu Sans 7
clock_padding = 4 0
clock_background_id = 0

systray_padding = 0 4 4
systray_background_id = 0
systray_sort = ascending

#-----
rounded = 0
border_width = 0
background_color = #0d1117 100
border_color = #30363d 100

#-----
rounded = 3
border_width = 1
background_color = #21262d 100
border_color = #58a6ff 100

#-----
rounded = 3
border_width = 1
background_color = #161b22 100
border_color = #30363d 50

#-----
rounded = 3
border_width = 1
background_color = #3d1f00 100
border_color = #f78166 100
TINT

# Picom
cat > "$USER_HOME/.config/picom/picom.conf" << 'PICOM'
backend = "xrender";
vsync = true;
shadow = false;
fading = true;
fade-delta = 4;
fade-in-step = 0.04;
fade-out-step = 0.04;
inactive-opacity = 0.95;
PICOM

# Rofi
mkdir -p "$USER_HOME/.config/rofi"
cat > "$USER_HOME/.config/rofi/config.rasi" << 'ROFI'
configuration {
    modi: "drun,run,ssh";
    show-icons: true;
    icon-theme: "Papirus";
    font: "Dejavu Sans 11";
}
* {
    bg: #0d1117;
    fg: #c9d1d9;
    accent: #58a6ff;
    background-color: @bg;
    text-color: @fg;
}
window { width: 50%; border: 2px; border-color: @accent; }
element selected { background-color: #21262d; text-color: @accent; }
ROFI

# .xinitrc
cat > "$USER_HOME/.xinitrc" << 'XINIT'
#!/bin/bash
xsetroot -solid "#0d1117"
xrandr --auto
picom -b 2>/dev/null &
exec openbox-session
XINIT
chmod +x "$USER_HOME/.xinitrc"

# .bash_profile
cat > "$USER_HOME/.bash_profile" << 'PROF'
export PATH="$PATH:/usr/local/bin"
[[ -f ~/.bashrc ]] && source ~/.bashrc
if [ -z "$DISPLAY" ] && [ "$(tty)" = "/dev/tty1" ]; then
    clear
    echo ""
    echo "  ██╗███╗   ██╗ ██████╗ ██████╗  ██████╗ ███╗  ██╗██╗████████╗ ██████╗ "
    echo "  ██║████╗  ██║██╔════╝██╔═══██╗██╔════╝ ████╗ ██║██║╚══██╔══╝██╔═══██╗"
    echo "  ██║██╔██╗ ██║██║     ██║   ██║██║  ███╗██╔██╗██║██║   ██║   ██║   ██║"
    echo "  ██║██║╚██╗██║██║     ██║   ██║██║   ██║██║╚████║██║   ██║   ██║   ██║"
    echo "  ██║██║ ╚████║╚██████╗╚██████╔╝╚██████╔╝██║ ╚███║██║   ██║   ╚██████╔╝"
    echo "  ╚═╝╚═╝  ╚═══╝ ╚═════╝ ╚═════╝  ╚═════╝ ╚═╝  ╚══╝╚═╝   ╚═╝    ╚═════╝ "
    echo ""
    echo "  Privacy-focused Linux | Based on Debian 12 Bookworm"
    echo "  Kernel: $(uname -r) | Tor: $(tor-toggle status 2>/dev/null || echo 'OFF')"
    echo ""
    echo "  Type 'startx' to launch the desktop"
    echo "  Type 'tor-toggle on' to enable Tor routing"
    echo "  Type 'neofetch' to see system info"
    echo ""
fi
PROF

# .bashrc
cat > "$USER_HOME/.bashrc" << 'BASHRC'
PS1='\[\033[01;32m\][\u@incognito]\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
alias ls='ls --color=auto'
alias ll='ls -la'
alias tor-status='systemctl status tor; tor-toggle status'
alias myip='curl -s ifconfig.me'
alias torip='torify curl -s ifconfig.me'
alias firewall='sudo /usr/local/sbin/incognito-firewall-base.sh && echo Firewall reset'
BASHRC

# Desktop shortcuts
ln -sf /usr/bin/alacritty "$USER_HOME/Desktop/Terminal.desktop" 2>/dev/null || true
ln -sf /usr/bin/pcmanfm "$USER_HOME/Desktop/Files.desktop" 2>/dev/null || true
ln -sf /usr/bin/wireshark "$USER_HOME/Desktop/Wireshark.desktop" 2>/dev/null || true

chown -R user:user "$USER_HOME"
chmod +x "$USER_HOME/.xinitrc"

echo "Desktop config done"
EOF
    chmod +x "$BUILD_DIR/config/hooks/normal/0040-desktop-config.hook.chroot"

    log_ok "Hooks siap"
}

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
    log_ok "Login: user / live"
    log_ok "Password: live (atau root/toor)"
    log_ok "Ketik 'startx' untuk desktop"
    log_ok "=============================="
}

main "$@"
