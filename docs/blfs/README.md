# BLFS Build Documentation

This directory contains documentation for Beyond Linux From Scratch (BLFS) configurations for Incognito OS.

## Overview

After completing the base LFS system, we use BLFS to add additional functionality:
- Networking support
- Systemd init system
- Desktop environment
- Security tools
- System utilities

## Phase 2: Networking & Systemd

### Networking Stack

1. **iproute2**
   - Modern networking tools (ip, ss, etc.)
   - Replaces ifconfig, route, etc.

2. **iptables**
   - Firewall and NAT configuration
   - Essential for Tor routing

3. **dhcpcd**
   - DHCP client for automatic network configuration
   - Lightweight alternative to NetworkManager

4. **wget & curl**
   - Command-line download tools
   - Essential for package management

### Systemd Integration

1. **systemd Installation**
   - Build and install systemd
   - Configure as init system

2. **Service Configuration**
   - Tor service
   - Network services
   - System services

3. **Boot Process**
   - Configure systemd boot
   - Set up default targets

## Phase 3: Desktop Environment

### Xorg Display Server

1. **Xorg Server**
   - X11 display server
   - Input device support
   - Video driver support

2. **Xorg Utilities**
   - xrandr (display configuration)
   - xsetroot (root window properties)
   - xset (user preferences)

3. **Xorg Libraries**
   - libX11, libXext, libXrender
   - libXinerama, libXrandr, libXcursor
   - libXfixes, libXcomposite, libXdamage

### Openbox Window Manager

1. **Openbox Installation**
   - Lightweight window manager
   - Minimal dependencies

2. **Openbox Configuration**
   - rc.xml (main configuration)
   - menu.xml (application menu)
   - autostart (startup applications)

3. **Openbox Themes**
   - Incognito-Dark theme
   - Custom color scheme

### Polybar Panel

1. **Polybar Installation**
   - Modern taskbar/panel
   - Highly configurable

2. **Polybar Configuration**
   - config.ini (main configuration)
   - Modules: menu, terminal, file, firefox, chromium
   - Modules: ram, cpu, tor, clock, power

3. **Polybar Themes**
   - Incognito color scheme
   - Custom icons

### Rofi Application Launcher

1. **Rofi Installation**
   - Fast application launcher
   - Window switcher

2. **Rofi Configuration**
   - config.rasi (theme and settings)
   - Custom color scheme

### Picom Compositor (Optional)

1. **Picom Installation**
   - Compositing manager
   - Transparency and shadows

2. **Picom Configuration**
   - picom.conf (effects and settings)
   - Blur effects
   - Shadow effects

## Phase 4: Security Tools

### Kali Linux Repository

1. **Repository Setup**
   - Add Kali repository
   - Import GPG key
   - Configure APT

2. **Package Management**
   - Install security tools
   - Update system

### Security Tools

1. **Network Scanning**
   - nmap
   - masscan
   - nikto

2. **Password Attacks**
   - hydra
   - john
   - hashcat

3. **Wireless Attacks**
   - aircrack-ng
   - reaver
   - bully

4. **Web Application**
   - sqlmap
   - burpsuite
   - dirb
   - gobuster

5. **Exploitation**
   - metasploit-framework
   - social-engineer-toolkit

6. **Forensics**
   - wireshark
   - tcpdump

## Phase 5: Finalization

### GRUB Configuration

1. **GRUB Theme**
   - Incognito theme
   - Custom background
   - Custom icons

2. **GRUB Menu**
   - Default entry
   - Tor enabled/disabled entries
   - Recovery mode

### System Configuration

1. **fstab**
   - Filesystem mount points
   - Swap configuration

2. **Network Configuration**
   - NetworkManager or dhcpcd
   - DNS configuration

3. **Locale Configuration**
   - Language settings
   - Timezone settings

### ISO Creation

1. **Live Boot Configuration**
   - initramfs
   - syslinux

2. **ISO Generation**
   - xorriso
   - Hybrid ISO

## Customizations for Incognito OS

### Privacy Enhancements

1. **Tor Integration**
   - Pre-configured Tor daemon
   - iptables rules for Tor routing
   - Tor toggle script

2. **Security Hardening**
   - System hardening script
   - Secure defaults
   - Minimal attack surface

### Performance Optimizations

1. **Memory Usage**
   - Lightweight components
   - Minimal services
   - zram for compressed swap

2. **CPU Usage**
   - Optimized kernel
   - Efficient services
   - Minimal background processes

3. **Storage Usage**
   - Minimal package set
   - No unnecessary files
   - Compressed filesystems

### Aesthetic Customizations

1. **Color Scheme**
   - Primary: #0a0a0a (black)
   - Secondary: #1a1a1a (dark gray)
   - Accent: #00ff88 (green)
   - Accent2: #00ccff (cyan)
   - Text: #ffffff (white)
   - Danger: #ff4444 (red)
   - Warning: #ffaa00 (yellow)

2. **Fonts**
   - System: DejaVu Sans
   - Monospace: DejaVu Sans Mono
   - Terminal: JetBrains Mono

3. **Icons**
   - Papirus-Dark
   - Font Awesome

## Troubleshooting

### Common Issues

1. **Missing Dependencies**
   - Check BLFS book for dependencies
   - Verify all required libraries

2. **Build Failures**
   - Check logs for specific errors
   - Verify package versions
   - Check environment variables

3. **Configuration Issues**
   - Verify configuration files
   - Check file permissions
   - Test configurations

### Debugging Tips

1. **Check Service Status**
   ```bash
   systemctl status tor
   systemctl status NetworkManager
   ```

2. **Test Networking**
   ```bash
   ping google.com
   ip a
   ip route
   ```

3. **Test Desktop**
   ```bash
   startx
   openbox --replace &
   polybar incognito-bar &
   ```

## References

- [BLFS Book](https://www.linuxfromscratch.org/blfs/view/stable/)
- [Kali Linux Documentation](https://www.kali.org/docs/)
- [Arch Wiki](https://wiki.archlinux.org/)

## Next Steps

After completing all phases, you have a fully functional Incognito OS system:
- Boot from ISO or installed system
- Log in with username: incognito, password: incognito
- Start desktop: startx
- Toggle Tor: toggle-tor
- Access security tools: security-tools
