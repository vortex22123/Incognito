# Incognito OS - Build Guide

> **"Fast. Private. Invisible."**

This guide explains how to build Incognito OS from source. The build process creates a lightweight, privacy-focused Linux distribution with Tor integration and Kali Linux security tools.

## Build Overview

Incognito OS can be built using two approaches:

1. **Debian-based (Recommended)**: Uses `debootstrap` to create a minimal Debian base, then adds Kali tools. Faster (30-60 minutes).
2. **LFS-based (Pure)**: Follows Linux From Scratch methodology. Takes 8-12 hours, fully from source.

This guide focuses on the **Debian-based approach** as it's more practical and maintainable.

## Prerequisites

### Host System Requirements

| Requirement | Minimum | Recommended |
|-------------|---------|-------------|
| CPU | 2 cores | 4+ cores |
| RAM | 4 GB | 8+ GB |
| Disk Space | 20 GB | 50+ GB |
| OS | Debian/Ubuntu | Debian 12+ |
| Architecture | x86_64 | x86_64 |

### Required Packages

Install build dependencies on your host system:

```bash
sudo apt update
sudo apt install -y \
    debootstrap \
    mksquashfs \
    grub-mkrescue \
    xorriso \
    mtools \
    wget \
    curl \
    gpg \
    git
```

## Quick Build

The fastest way to build Incognito OS:

```bash
# Clone the repository
git clone https://github.com/vortex22123/Incognito.git
cd Incognito

# Make scripts executable
chmod +x build-incognito.sh
chmod +x scripts/build/*.sh
chmod +x scripts/config/*.sh
chmod +x scripts/tools/*.sh

# Run the main build script (as root)
sudo ./build-incognito.sh all
```

This will:
1. Bootstrap a minimal Debian system
2. Install desktop environment (Openbox, Polybar, etc.)
3. Configure Tor and privacy tools
4. Install security tools from Kali
5. Create a bootable ISO image

The ISO will be created at: `incognito-os-YYYYMMDD.iso`

## Step-by-Step Build

### Phase 1: Base System

Creates a minimal Debian base system using `debootstrap`:

```bash
sudo ./scripts/build/build-debian-base.sh
```

This phase:
- Creates a chroot environment at `build-root/`
- Installs minimal Debian packages
- Configures basic system settings
- Sets up APT repositories

**Duration**: 10-15 minutes

### Phase 2: Networking & Tor

Configures networking and Tor integration:

```bash
# This is automatically run by the main build script
# Or run manually after Phase 1:
sudo ./scripts/build/phase2-blfs-networking.sh
```

This phase:
- Installs Tor daemon
- Configures transparent proxy
- Sets up iptables rules
- Creates systemd services

**Duration**: 5-10 minutes

### Phase 3: Desktop Environment

Installs the lightweight desktop environment:

```bash
sudo ./scripts/build/phase3-desktop-openbox.sh
```

This phase:
- Installs Xorg server
- Configures Openbox window manager
- Sets up Polybar panel
- Configures Rofi application launcher
- Installs Picom compositor
- Sets up wallpapers and themes

**Duration**: 15-20 minutes

### Phase 4: Security Tools

Installs penetration testing and security auditing tools:

```bash
sudo ./scripts/build/phase4-security-tools.sh
```

This phase:
- Adds Kali Linux repository
- Installs tools from `packages/kali-tools.list`
- Configures APT pinning (Debian > Kali)
- Handles package conflicts

**Duration**: 30-60 minutes (depends on tool selection)

### Phase 5: Finalize ISO

Creates the bootable ISO image:

```bash
sudo ./scripts/build/phase5-finalize-iso.sh
```

This phase:
- Installs GRUB bootloader
- Configures kernel and initramfs
- Creates squashfs filesystem
- Builds hybrid BIOS/UEFI ISO
- Cleans up build artifacts

**Duration**: 10-15 minutes

## Customization

### Selecting Security Tools

Edit `packages/kali-tools.list` to customize which security tools are installed. Tools are categorized:

- **Network Scanning**: nmap, masscan, nikto, netdiscover
- **Password Attacks**: hydra, john, hashcat, crunch
- **Wireless**: aircrack-ng, reaver, bully
- **Web Application**: sqlmap, burpsuite, dirb, gobuster
- **Exploitation**: metasploit-framework, social-engineer-toolkit
- **Forensics**: foremost, binwalk, exiftool
- **Privacy**: tor, proxychains, privoxy

Comment out tools you don't need to reduce ISO size and RAM usage.

### Desktop Configuration

Desktop configurations are in `configs/`:

- `configs/openbox/` - Openbox window manager settings
- `configs/polybar/` - Polybar panel configuration
- `configs/rofi/` - Rofi application launcher
- `configs/picom/` - Picom compositor settings

Edit these files to customize the look and feel.

### Tor Configuration

Tor settings are in `configs/tor/torrc`:

```ini
SocksPort 9050
ControlPort 9051
TransPort 9040
DNSPort 5353
```

The `toggle-tor` script controls Tor routing:
- `toggle-tor on` - Enable Tor and route all traffic through it
- `toggle-tor off` - Disable Tor and restore normal network
- `toggle-tor status` - Show current Tor status

### System Configuration

- `configs/system/os-release` - System identification
- `configs/systemd/tor.service` - Tor systemd service
- `configs/systemd/incognito-firewall.service` - Firewall service

## Build Options

### Minimal Build (No Security Tools)

To build without security tools (smaller ISO, faster build):

```bash
# Edit packages/kali-tools.list and comment out all tools
# Or create an empty file

# Then run the build
sudo ./build-incognito.sh all
```

### Custom Package Selection

Create a custom package list:

```bash
# Create a new list file
cp packages/kali-tools.list packages/kali-tools-custom.list

# Edit the custom list
nano packages/kali-tools-custom.list

# Update the build script to use your custom list
# In scripts/build/phase4-security-tools.sh, change:
#   local list="$REPO_ROOT/packages/kali-tools.list"
# to:
#   local list="$REPO_ROOT/packages/kali-tools-custom.list"
```

### Build with Specific Debian Version

Edit `scripts/build/build-debian-base.sh`:

```bash
# Change DEBIAN_SUITE
DEBIAN_SUITE="bookworm"  # Debian 12 stable
# DEBIAN_SUITE="trixie"   # Debian 13 testing
# DEBIAN_SUITE="sid"      # Debian unstable
```

## Troubleshooting

### Common Issues

#### Build Fails Due to Missing Dependencies

```bash
# Install the missing package on your host system
sudo apt install <missing-package>
```

#### Disk Space Issues

```bash
# Clean up previous builds
sudo ./build-incognito.sh clean

# Check disk space
df -h
```

#### Network Issues

```bash
# Check your internet connection
ping google.com

# If behind a proxy, configure it
# In the chroot, edit /etc/apt/apt.conf.d/proxy
# echo 'Acquire::http::Proxy "http://proxy:port";' > /etc/apt/apt.conf.d/proxy
```

#### Kali Repository Issues

```bash
# Manually import Kali GPG key
wget -qO- https://archive.kali.org/archive-key.asc | gpg --dearmor -o /usr/share/keyrings/kali-archive-keyring.gpg

# Update APT
apt-get update
```

### Debugging

#### View Build Logs

```bash
# Build logs are saved with timestamps
tail -f build-*.log

# Or check the last build log
ls -lt build-*.log | head -1
tail -n 100 $(ls -t build-*.log | head -1)
```

#### Manual Chroot Access

```bash
# After Phase 1, you can manually enter the chroot
sudo chroot build-root /bin/bash

# Once inside, you can manually run commands
# Exit with: exit
```

#### Check Service Status

```bash
# After build, check services
systemctl status tor
systemctl status incognito-firewall
```

## Testing the ISO

### In QEMU

```bash
# Install QEMU
sudo apt install qemu-system-x86

# Run the ISO
qemu-system-x86_64 \
    -cdrom incognito-os-*.iso \
    -m 4G \
    -enable-kvm \
    -net nic -net user
```

### In VirtualBox

1. Open VirtualBox
2. Create new VM
3. Type: Linux, Version: Debian (64-bit)
4. Memory: 4GB
5. Create virtual disk: 20GB
6. Settings > Storage > Add ISO
7. Start VM

### On Real Hardware

1. Burn ISO to USB:
   ```bash
   sudo dd if=incognito-os-*.iso of=/dev/sdX bs=4M status=progress
   ```
2. Boot from USB
3. Select "Incognito OS" from GRUB menu

## Performance Targets

| Metric | Target | Current |
|--------|--------|---------|
| RAM Idle | < 300 MB | TBD |
| RAM with Tor | < 500 MB | TBD |
| ISO Size | < 2 GB | TBD |
| Boot Time | < 15 sec | TBD |

## Cleanup

To clean up build artifacts:

```bash
# Remove build directory
sudo rm -rf build-root iso-staging

# Remove ISO files
sudo rm -f incognito-os-*.iso

# Remove logs
sudo rm -f build-*.log

# Or use the clean command
sudo ./build-incognito.sh clean
```

## Advanced Topics

### LFS-based Build (Pure from Source)

For a true LFS build (8-12 hours):

1. Follow the LFS book: https://www.linuxfromscratch.org/lfs/view/stable/
2. Use `scripts/build/phase1-lfs-base.sh` as a guide
3. Update `packages/base-packages.txt` with current versions
4. Build each package manually in order

### Adding New Tools

To add a new security tool:

1. Add the package name to `packages/kali-tools.list`
2. If it's not in Kali/Debian repos, create a build script in `scripts/tools/security-packages/`
3. Update the build script to handle the new tool

### Creating Custom ISOs

To create a custom ISO with different configurations:

1. Create a new branch:
   ```bash
   git checkout -b my-custom-build
   ```
2. Modify configurations in `configs/`
3. Update package lists
4. Build the ISO:
   ```bash
   sudo ./build-incognito.sh all
   ```
5. Test the ISO

### Automated Builds

For CI/CD or automated builds:

```bash
#!/bin/bash
# automated-build.sh

cd /path/to/Incognito

# Clean previous build
sudo ./build-incognito.sh clean

# Build new ISO
git pull origin main
sudo ./build-incognito.sh all

# Move ISO to web server
mv incognito-os-*.iso /var/www/html/iso/
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test the build
5. Submit a pull request

## License

This project is licensed under the MIT License. See the LICENSE file for details.

---

**Incognito OS** - Small, fast, and untraceable.

*Built with love using Debian, Kali Linux, and custom configurations.*
