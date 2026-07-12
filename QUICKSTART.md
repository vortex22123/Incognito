# Incognito OS - Quick Start Guide

> **"Fast. Private. Invisible."**

Welcome to Incognito OS! This guide will help you get started with your new privacy-focused, lightweight Linux distribution.

## 🚀 Getting Started

### First Boot

1. **Boot from ISO or installed system**
2. **Log in with the following credentials:**
   - Username: `incognito`
   - Password: `incognito`
   - Root password: `incognito` (change this immediately!)

3. **Start the desktop environment:**
   ```bash
   startx
   ```

### Basic Navigation

| Action | Shortcut |
|--------|----------|
| Open application menu | Right-click on desktop |
| Switch between windows | Alt+Tab |
| Close window | Alt+F4 |
| Open terminal | Alt+t |
| Open application launcher | Alt+r |
| Toggle Tor | Alt+q |
| Take screenshot | Print |
| Lock screen | Alt+l |
| Switch desktop | Ctrl+Alt+Arrow Keys |

## 🎯 Key Features

### Tor Integration

Incognito OS comes with Tor pre-installed and ready to use:

- **Toggle Tor**: Click the Tor status in the top panel (🟢 ON / 🔴 OFF)
- **Command line**: `toggle-tor`
- **Status check**: `systemctl status tor`
- **All web traffic** is automatically routed through Tor when enabled

### Security Tools

Access the security tools menu:
```bash
security-tools
```

Or use tools directly:
```bash
nmap -sn 192.168.1.0/24    # Network scan
hydra -l user -P /usr/share/wordlists/rockyou.txt ssh://target  # Brute force
sqlmap -u "http://example.com/page.php?id=1" --batch  # SQL injection
wireshark                     # Network analysis (GUI)
tcpdump -i eth0              # Network capture (CLI)
```

### System Information

Check system status:
```bash
htop                         # System monitor
free -h                      # Memory usage
df -h                        # Disk usage
ip a                         # Network interfaces
uname -a                     # System information
```

## 📁 Directory Structure

```
/
├── etc/                      # System configuration
│   ├── xdg/                 # Desktop configuration
│   │   ├── openbox/        # Openbox WM configs
│   │   ├── polybar/        # Polybar configs
│   │   ├── rofi/           # Rofi configs
│   │   └── picom/          # Picom configs
│   ├── tor/                # Tor configuration
│   └── systemd/            # Systemd services
├── usr/
│   ├── share/
│   │   ├── backgrounds/    # Wallpapers
│   │   ├── icons/          # Icon sets
│   │   ├── doc/            # Documentation
│   │   └── incognito/      # Incognito-specific files
│   │       └── scripts/    # Utility scripts
│   └── local/
│       └── incognito/      # Incognito scripts
│           └── scripts/    # System scripts
├── home/
│   └── incognito/          # User home directory
│       ├── .config/        # User configurations
│       └── .local/         # User data
└── boot/
    └── grub/               # GRUB configuration
        └── themes/          # GRUB themes
            └── incognito/   # Incognito GRUB theme
```

## 🔧 Configuration Files

### Desktop Environment

| File | Purpose |
|------|---------|
| `/etc/xdg/openbox/rc.xml` | Openbox main configuration |
| `/etc/xdg/openbox/menu.xml` | Application menu |
| `/etc/xdg/openbox/autostart` | Startup applications |
| `/etc/xdg/polybar/config.ini` | Polybar configuration |
| `/etc/xdg/rofi/config.rasi` | Rofi configuration |
| `/etc/xdg/picom/picom.conf` | Picom compositor configuration |

### System Configuration

| File | Purpose |
|------|---------|
| `/etc/os-release` | System identification |
| `/etc/default/grub` | GRUB configuration |
| `/etc/tor/torrc` | Tor configuration |
| `/etc/systemd/system/tor.service` | Tor service |

### User Configuration

| File | Purpose |
|------|---------|
| `~/.config/openbox/rc.xml` | User Openbox configuration |
| `~/.config/polybar/config.ini` | User Polybar configuration |
| `~/.bashrc` | User shell configuration |

## 🛡️ Security Tools

### Network Scanning
- **nmap**: Network mapper and port scanner
- **masscan**: Fast TCP port scanner
- **nikto**: Web server scanner
- **netdiscover**: ARP reconnaissance

### Password Attacks
- **hydra**: Online password cracker
- **john**: Offline password cracker
- **hashcat**: Advanced password recovery
- **crunch**: Wordlist generator

### Wireless Attacks
- **aircrack-ng**: Wireless security auditing
- **reaver**: WPS attack tool
- **bully**: WPS brute force

### Web Application
- **sqlmap**: SQL injection tool
- **burpsuite**: Web vulnerability scanner
- **dirb**: Web content scanner
- **gobuster**: Directory brute forcer

### Exploitation
- **metasploit-framework**: Exploitation framework
- **social-engineer-toolkit**: Social engineering toolkit

### Forensics
- **wireshark**: Network protocol analyzer
- **tcpdump**: Network traffic analyzer

## 🎨 Customization

### Change Wallpaper

1. **Temporary change:**
   ```bash
   feh --bg-scale /path/to/wallpaper.png
   ```

2. **Permanent change:**
   - Edit `/etc/xdg/openbox/autostart`
   - Change the `feh` command to point to your wallpaper
   - Or create `~/.config/openbox/autostart` with your wallpaper command

### Change Theme

1. **Openbox theme:**
   - Edit `/etc/xdg/openbox/rc.xml`
   - Change the `<name>` in the `<theme>` section

2. **Polybar theme:**
   - Edit `/etc/xdg/polybar/config.ini`
   - Change colors in the `[colors]` section

3. **Rofi theme:**
   - Edit `/etc/xdg/rofi/config.rasi`
   - Change colors and layout

### Add Applications

1. **Install the application:**
   ```bash
   sudo apt install application-name
   ```

2. **Add to menu:**
   - Edit `/etc/xdg/openbox/menu.xml`
   - Add a new `<item>` entry

3. **Add to Polybar:**
   - Edit `/etc/xdg/polybar/config.ini`
   - Add a new module

4. **Add keyboard shortcut:**
   - Edit `/etc/xdg/openbox/rc.xml`
   - Add a new `<keybind>` entry

## ⚙️ System Management

### Update System

```bash
sudo apt update && sudo apt upgrade -y
```

### Clean System

```bash
sudo apt clean && sudo apt autoclean
```

### System Hardening

```bash
sudo system-hardening
```

### Change Passwords

```bash
# Change user password
passwd

# Change root password
sudo passwd root
```

### Manage Services

```bash
# Start/Stop/Restart Tor
sudo systemctl start tor
sudo systemctl stop tor
sudo systemctl restart tor

# Enable/Disable Tor at boot
sudo systemctl enable tor
sudo systemctl disable tor

# Check service status
systemctl status tor
```

## 🌐 Network Configuration

### Check Network Status

```bash
ip a                    # Show network interfaces
ip route               # Show routing table
ping google.com        # Test connectivity
```

### Configure Network

1. **DHCP (automatic):**
   ```bash
   sudo dhclient eth0
   ```

2. **Static IP:**
   ```bash
   sudo ip addr add 192.168.1.100/24 dev eth0
   sudo ip route add default via 192.168.1.1
   sudo ip route add 192.168.1.0/24 dev eth0
   ```

3. **DNS Configuration:**
   ```bash
   echo "nameserver 8.8.8.8" | sudo tee /etc/resolv.conf
   ```

## 🔒 Privacy Features

### Tor Configuration

- **SOCKS Proxy**: 127.0.0.1:9050
- **Control Port**: 127.0.0.1:9051
- **Transparent Proxy**: 127.0.0.1:9040
- **DNS Proxy**: 127.0.0.1:5353

### Tor Usage

1. **Enable Tor:**
   ```bash
   toggle-tor
   ```

2. **Check Tor status:**
   ```bash
   systemctl status tor
   ```

3. **Test Tor connectivity:**
   ```bash
   curl --socks5 127.0.0.1:9050 https://check.torproject.org
   ```

4. **Configure applications to use Tor:**
   - Set proxy to 127.0.0.1:9050 (SOCKS5)
   - Or use `proxychains` for command-line tools

### iptables Rules

When Tor is enabled, the following rules are applied:
- All HTTP (port 80) traffic is redirected to Tor (port 9040)
- All HTTPS (port 443) traffic is redirected to Tor (port 9040)
- All DNS (port 53) traffic is redirected to Tor (port 5353)
- Loopback traffic is allowed
- Established connections are allowed

## 🎮 Performance Tips

### Reduce Memory Usage

1. **Disable Picom (compositor):**
   - Remove from `/etc/xdg/openbox/autostart`

2. **Reduce Polybar modules:**
   - Edit `/etc/xdg/polybar/config.ini`
   - Remove unnecessary modules

3. **Use lighter applications:**
   - Use `st` instead of Alacritty
   - Use `ranger` instead of PCManFM

### Improve Performance

1. **Enable Picom (if you have GPU):**
   - Uncomment Picom in `/etc/xdg/openbox/autostart`

2. **Use faster terminal:**
   - Install `st` (simple terminal)

3. **Optimize Openbox:**
   - Reduce animations in `/etc/xdg/openbox/rc.xml`

## 🐛 Troubleshooting

### Common Issues

| Issue | Solution |
|-------|----------|
| Desktop doesn't start | Run `startx` from console |
| No network | Check `ip a` and `ping google.com` |
| Tor doesn't work | Check `systemctl status tor` |
| No sound | Check `alsamixer` and unmute channels |
| Applications missing | Install with `sudo apt install appname` |
| Polybar not showing | Check `polybar incognito-bar 2>&1` |
| Openbox not starting | Check `openbox --replace 2>&1` |

### Debugging Commands

```bash
# Check running processes
ps aux

# Check Xorg logs
cat /var/log/Xorg.0.log

# Check Openbox logs
openbox --replace 2>&1

# Check Polybar logs
polybar incognito-bar 2>&1

# Check display
xrandr

# Check window manager
wmctrl -m

# Check environment
printenv

# Check system logs
journalctl -xe
```

## 📚 Documentation

- **Full Documentation**: `/usr/share/doc/incognito/`
- **Desktop Configuration**: `/usr/share/doc/incognito/desktop.md`
- **Security Tools**: `/usr/share/doc/incognito/security.md`
- **LFS Build Notes**: `/usr/share/doc/incognito/lfs/`
- **BLFS Build Notes**: `/usr/share/doc/incognito/blfs/`

## 🤝 Support

For support and updates, visit:
- **GitHub Repository**: https://github.com/vortex22123/Incognito
- **Issues**: https://github.com/vortex22123/Incognito/issues

## 📄 License

Incognito OS is licensed under the MIT License. See the LICENSE file for details.

---

**Incognito OS** - Small, fast, and untraceable.

*Built with ❤️ using Linux From Scratch and Kali Linux tools.*
