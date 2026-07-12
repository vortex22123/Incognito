# Incognito OS

> **"Fast. Private. Invisible."**

Incognito is a lightweight, privacy-focused Linux distribution built from scratch using Linux From Scratch (LFS) methodology. Designed to run on minimal hardware (4GB RAM) with Tor integration and Kali Linux security tools.

## 🎯 Key Features

- **Ultra-lightweight**: Idle RAM < 300MB, runs smoothly on 4GB RAM systems
- **Privacy-first**: Tor pre-installed with one-click ON/OFF toggle
- **Minimalist**: Only essential components, no bloatware
- **Security-focused**: Kali Linux tools for penetration testing and auditing
- **Aesthetic**: Dark, minimal, professional appearance

## 📋 System Requirements

| Component | Minimum | Recommended |
|-----------|---------|-------------|
| CPU | 1 GHz | 2+ GHz |
| RAM | 2 GB | 4 GB |
| Storage | 10 GB | 20 GB |
| Architecture | x86_64 | x86_64 |

## 🏗️ Build Process

### Phase 1: Base System (LFS)
```bash
# Follow LFS book chapters 1-10
cd scripts/build
./phase1-lfs-base.sh
```

### Phase 2: Networking & Systemd (BLFS)
```bash
./phase2-blfs-networking.sh
```

### Phase 3: Desktop Environment
```bash
./phase3-desktop-openbox.sh
```

### Phase 4: Security Tools
```bash
./phase4-security-tools.sh
```

### Phase 5: Finalization
```bash
./phase5-finalize-iso.sh
```

## 📁 Directory Structure

```
Incognito/
├── docs/                    # Documentation
│   ├── lfs/               # LFS build notes
│   ├── blfs/              # BLFS configurations
│   └── configs/           # System configurations
├── scripts/                # Build and configuration scripts
│   ├── build/             # Phase build scripts
│   ├── config/            # Configuration scripts
│   └── tools/             # Utility scripts
├── configs/                # Configuration files
│   ├── openbox/           # Openbox WM configs
│   ├── polybar/           # Polybar configs
│   ├── rofi/              # Rofi configs
│   ├── picom/             # Picom compositor configs
│   ├── tor/               # Tor configurations
│   ├── grub/              # GRUB configurations
│   └── systemd/           # Systemd service files
├── assets/                 # Visual assets
│   ├── wallpapers/        # Background images
│   ├── icons/             # Icon sets
│   └── grub-theme/        # GRUB theme files
├── packages/               # Package lists and sources
└── iso/                   # ISO build output
```

## 🚀 Quick Start

### 1. Clone the repository
```bash
git clone https://github.com/vortex22123/Incognito.git
cd Incognito
```

### 2. Review and customize configurations
Edit files in `configs/` directory to match your preferences.

### 3. Start the build process
```bash
chmod +x scripts/build/*.sh
./scripts/build/phase1-lfs-base.sh
```

## 🔧 Configuration

### Tor Toggle
The system includes a Tor toggle script that:
- Starts/stops the Tor service
- Configures iptables to route traffic through Tor
- Updates Polybar indicator (🟢 ON / 🔴 OFF)

### Desktop Environment
- **Window Manager**: Openbox (ultra-lightweight)
- **Panel**: Polybar (customizable taskbar)
- **App Launcher**: Rofi
- **Compositor**: Picom (optional transparency)

### Visual Identity
- **Colors**: Dark theme with green/cyan accents
- **Wallpaper**: Minimal dark design with Tor-inspired elements
- **Icons**: Papirus dark or Kali-icons
- **Fonts**: Inter/Noto Sans for system, JetBrains Mono for terminal

## 🛡️ Security Tools

Pre-installed Kali Linux tools:
- nmap, hydra, metasploit-framework
- sqlmap, burpsuite, wireshark
- aircrack-ng, john, hashcat
- netcat, tcpdump, nikto, dirb, gobuster

## 📊 Performance Targets

| Metric | Target |
|--------|--------|
| RAM Idle | < 300 MB |
| CPU Idle | < 5% |
| RAM with Tor ON | < 500 MB |
| ISO Size | < 2 GB |
| Boot Time | < 15 seconds |

## 📚 Documentation

- [LFS Build Guide](docs/lfs/README.md)
- [BLFS Configuration](docs/blfs/README.md)
- [Desktop Setup](docs/configs/desktop.md)
- [Security Tools](docs/configs/security.md)

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

**Incognito OS** - Small, fast, and untraceable.
