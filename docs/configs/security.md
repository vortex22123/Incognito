# Security Tools Configuration

This document describes the security tools configuration for Incognito OS.

## Overview

Incognito OS includes a comprehensive set of security tools from Kali Linux, organized for easy access and use. The tools are pre-configured and ready to use for penetration testing, security auditing, and privacy protection.

## Security Tools Categories

### Network Scanning

| Tool | Description | Command |
|------|-------------|---------|
| nmap | Network mapper, port scanner | `nmap [options] target` |
| masscan | Fast TCP port scanner | `masscan [options] target` |
| nikto | Web server scanner | `nikto [options] target` |
| netdiscover | Active/passive ARP reconnaissance | `netdiscover [options]` |

### Password Attacks

| Tool | Description | Command |
|------|-------------|---------|
| hydra | Online password cracker | `hydra [options] service://target` |
| john | Offline password cracker | `john [options] file` |
| hashcat | Advanced password recovery | `hashcat [options] hashfile wordlist` |
| crunch | Wordlist generator | `crunch [options]` |
| cewl | Custom word list generator | `cewl [options] url` |

### Wireless Attacks

| Tool | Description | Command |
|------|-------------|---------|
| aircrack-ng | Wireless security auditing | `aircrack-ng [options] file` |
| airmon-ng | Monitor mode enable/disable | `airmon-ng [start/stop] interface` |
| airodump-ng | Packet capture | `airodump-ng [options] interface` |
| aireplay-ng | Packet injection | `aireplay-ng [options] interface` |
| reaver | WPS attack tool | `reaver [options] interface` |
| bully | WPS brute force | `bully [options] interface` |

### Web Application Testing

| Tool | Description | Command |
|------|-------------|---------|
| sqlmap | SQL injection tool | `sqlmap [options] -u url` |
| burpsuite | Web vulnerability scanner | `burpsuite` |
| dirb | Web content scanner | `dirb [options] url` |
| gobuster | Directory brute forcer | `gobuster [options] url` |
| wpscan | WordPress vulnerability scanner | `wpscan [options] url` |
| nikto | Web server scanner | `nikto [options] url` |

### Exploitation

| Tool | Description | Command |
|------|-------------|---------|
| metasploit-framework | Exploitation framework | `msfconsole` |
| social-engineer-toolkit | Social engineering toolkit | `setoolkit` |
| beef-xss | Browser Exploitation Framework | `beef-xss` |
| armitage | Graphical cyber attack management | `armitage` |

### Forensics & Analysis

| Tool | Description | Command |
|------|-------------|---------|
| wireshark | Network protocol analyzer | `wireshark` |
| tcpdump | Network traffic analyzer | `tcpdump [options]` |
| tshark | CLI network protocol analyzer | `tshark [options]` |
| foremost | Forensic file carver | `foremost [options] file` |
| binwalk | Firmware analysis tool | `binwalk [options] file` |

### Post-Exploitation

| Tool | Description | Command |
|------|-------------|---------|
| mimikatz | Windows credentials extraction | `mimikatz` |
| linpeas | Linux privilege escalation | `linpeas.sh` |
| linenum | Linux enumeration | `linenum.sh` |
| powersploit | PowerShell exploitation | `powersploit` |
| empire | Post-exploitation framework | `empire` |

### OSINT & Reconnaissance

| Tool | Description | Command |
|------|-------------|---------|
| maltego | Open source intelligence | `maltego` |
| theharvester | Email and subdomain discovery | `theharvester [options]` |
| recon-ng | Web reconnaissance framework | `recon-ng` |
| spiderfoot | Open source intelligence automation | `spiderfoot` |
| amass | In-depth DNS enumeration | `amass [options]` |
| sublist3r | Subdomain enumeration | `sublist3r [options]` |

## Tor Configuration

### Tor Service

Incognito OS includes a pre-configured Tor daemon with the following features:

- **SOCKS Proxy**: Port 9050
- **Control Port**: Port 9051
- **Transparent Proxy**: Port 9040
- **DNS Proxy**: Port 5353

#### Tor Configuration File

Location: `/etc/tor/torrc`

Key settings:
```
SocksPort 9050
SocksListenAddress 127.0.0.1
TransPort 9040
TransListenAddress 127.0.0.1
DNSPort 5353
DNSListenAddress 127.0.0.1
RunAsDaemon 1
User tor
Group tor
DataDirectory /var/lib/tor
```

#### Tor Service File

Location: `/etc/systemd/system/tor.service`

```ini
[Unit]
Description=Tor Anonymity Daemon
After=network.target
Wants=network.target

[Service]
Type=simple
User=tor
Group=tor
ExecStart=/usr/bin/tor -f /etc/tor/torrc
ExecReload=/bin/kill -HUP $MAINPID
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
```

### Tor Toggle Script

Location: `/usr/local/incognito/scripts/toggle-tor.sh`

This script:
1. Checks if Tor is running
2. Starts/stops the Tor service
3. Configures iptables to route traffic through Tor
4. Updates the Polybar indicator

#### Usage

```bash
# Toggle Tor ON/OFF
toggle-tor

# Check Tor status
tor-status

# Start Tor manually
systemctl start tor

# Stop Tor manually
systemctl stop tor

# Check Tor status
systemctl status tor
```

### iptables Rules for Tor

When Tor is enabled, the following iptables rules are applied:

```bash
# Allow loopback traffic
iptables -A INPUT -i lo -j ACCEPT
iptables -A OUTPUT -o lo -j ACCEPT

# Allow established connections
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A OUTPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

# Allow Tor traffic
iptables -A INPUT -p tcp --dport 9050 -j ACCEPT
iptables -A INPUT -p tcp --dport 9051 -j ACCEPT
iptables -A OUTPUT -p tcp --dport 9050 -j ACCEPT
iptables -A OUTPUT -p tcp --dport 9051 -j ACCEPT

# Redirect HTTP/HTTPS through Tor
iptables -t nat -A OUTPUT -p tcp --dport 80 -j REDIRECT --to-port 9040
iptables -t nat -A OUTPUT -p tcp --dport 443 -j REDIRECT --to-port 9040

# Redirect DNS through Tor
iptables -t nat -A OUTPUT -p udp --dport 53 -j REDIRECT --to-port 5353
iptables -t nat -A OUTPUT -p tcp --dport 53 -j REDIRECT --to-port 5353
```

## Security Tools Configuration

### Nmap

#### Configuration

Nmap is pre-installed and ready to use. For advanced usage, create custom scripts in `/usr/share/nmap/scripts/`.

#### Common Commands

```bash
# Quick scan
nmap -T4 -F target

# Full scan
nmap -T4 -p- target

# Service version scan
nmap -T4 -sV target

# OS detection
nmap -T4 -O target

# Aggressive scan
nmap -T4 -A target

# UDP scan
nmap -T4 -sU target

# Script scan
nmap -T4 --script vuln target
```

#### Custom Scripts

Location: `/usr/share/incognito/security/nmap-scan.sh`

This script provides a menu-driven interface for common Nmap scans.

### Metasploit Framework

#### Configuration

Metasploit Framework is pre-installed with database support.

#### Setup

```bash
# Initialize database
msfdb init

# Start PostgreSQL
systemctl start postgresql

# Start Metasploit
msfconsole
```

#### Setup Script

Location: `/usr/local/incognito/scripts/metasploit-setup.sh`

This script automates the Metasploit setup process.

### Wireshark

#### Configuration

Wireshark is pre-installed with Qt interface.

#### Usage

```bash
# Start Wireshark GUI
wireshark

# Start TShark (CLI)
tshark [options]

# Capture on specific interface
tshark -i eth0

# Capture and save to file
tshark -i eth0 -w capture.pcap

# Read from file
tshark -r capture.pcap
```

### John the Ripper

#### Configuration

John the Ripper is pre-installed with community patches.

#### Usage

```bash
# Show formats
john --list=formats

# Crack password file
john password.txt

# Crack with wordlist
john --wordlist=/usr/share/wordlists/rockyou.txt password.txt

# Show cracked passwords
john --show password.txt
```

### Hashcat

#### Configuration

Hashcat is pre-installed with GPU support (if available).

#### Usage

```bash
# Show help
hashcat -h

# Crack MD5 hashes
hashcat -m 0 -a 0 hashes.txt wordlist.txt

# Crack SHA1 hashes
hashcat -m 100 -a 0 hashes.txt wordlist.txt

# Crack with rules
hashcat -m 0 -a 0 hashes.txt wordlist.txt -r rules/best64.rule

# Benchmark
hashcat -b
```

### SQLmap

#### Configuration

SQLmap is pre-installed and ready to use.

#### Usage

```bash
# Basic scan
sqlmap -u "http://example.com/page.php?id=1" --batch

# Get database names
sqlmap -u "http://example.com/page.php?id=1" --dbs --batch

# Get tables from database
sqlmap -u "http://example.com/page.php?id=1" -D database --tables --batch

# Dump table contents
sqlmap -u "http://example.com/page.php?id=1" -D database -T table --dump --batch

# Use Tor
sqlmap -u "http://example.com/page.php?id=1" --tor --batch
```

## Security Tools Menu

Location: `/usr/local/incognito/scripts/security-tools`

This script provides a menu-driven interface for accessing all security tools.

### Usage

```bash
# Open security tools menu
security-tools
```

### Menu Options

1. **Network Scanning**
   - Nmap
   - Masscan
   - Nikto

2. **Password Attacks**
   - Hydra
   - John the Ripper
   - Hashcat

3. **Wireless Attacks**
   - Aircrack-ng
   - Reaver
   - Bully

4. **Web Application**
   - SQLmap
   - Burp Suite
   - Dirb
   - Gobuster

5. **Exploitation**
   - Metasploit Framework
   - Social Engineer Toolkit

6. **Forensics**
   - Wireshark
   - Tcpdump

## System Hardening

### Hardening Script

Location: `/usr/local/incognito/scripts/hardening.sh`

This script automates system hardening with the following features:

1. **System Update**
   - Update all packages
   - Install security updates

2. **SSH Security**
   - Disable root login
   - Disable password authentication
   - Limit authentication attempts

3. **Firewall Configuration**
   - Set default DROP policy
   - Allow only essential traffic
   - Configure Tor routing

4. **Shared Memory Protection**
   - Mount /run/shm with noexec,nosuid,nodev

5. **IPv6 Configuration**
   - Disable IPv6 (optional)

6. **ASLR Configuration**
   - Enable Address Space Layout Randomization

7. **/tmp Protection**
   - Mount /tmp with noexec,nosuid,nodev

8. **Restrictive Umask**
   - Set umask to 027

9. **Core Dump Prevention**
   - Disable core dumps

10. **Auditd Configuration**
    - Enable audit daemon (if installed)

### Usage

```bash
# Run hardening script
sudo system-hardening
```

## Wordlists

Incognito OS includes several wordlists for password cracking:

- `/usr/share/wordlists/rockyou.txt` - Popular password list
- `/usr/share/wordlists/dirb/common.txt` - Common directories
- `/usr/share/wordlists/dirbuster/directory-list-2.3-medium.txt` - Directory brute force list
- `/usr/share/wordlists/seclists/` - Various security lists

## Custom Scripts

### Nmap Scan Script

Location: `/usr/share/incognito/security/nmap-scan.sh`

Provides a menu for common Nmap scans.

### Metasploit Setup Script

Location: `/usr/share/incognito/security/metasploit-setup.sh`

Automates Metasploit database setup.

### Tools Menu Script

Location: `/usr/share/incognito/security/tools-menu.sh`

Provides a menu for all security tools.

## Usage Tips

### General Tips

1. **Always Get Permission**
   - Only test systems you own or have permission to test
   - Unauthorized testing is illegal

2. **Use Tor for Anonymity**
   - Enable Tor before conducting security tests
   - Use `toggle-tor` to enable/disable

3. **Document Your Work**
   - Keep notes of commands and results
   - Save screenshots and logs

4. **Stay Updated**
   - Regularly update security tools
   - Check for new vulnerabilities

### Network Scanning Tips

1. **Start with Reconnaissance**
   - Use `nmap -sn` for host discovery
   - Use `netdiscover` for ARP scanning

2. **Scan for Open Ports**
   - Use `nmap -p-` for full port scan
   - Use `masscan` for fast scanning

3. **Identify Services**
   - Use `nmap -sV` for service version detection
   - Use `nikto` for web server scanning

4. **Save Results**
   - Use `-oN` for normal output
   - Use `-oX` for XML output
   - Use `-oG` for grepable output

### Password Attack Tips

1. **Use Wordlists**
   - Start with common wordlists
   - Use custom wordlists for specific targets

2. **Combine Techniques**
   - Use `hydra` for online attacks
   - Use `john` or `hashcat` for offline attacks

3. **Optimize Performance**
   - Use GPU acceleration with `hashcat`
   - Use rules with `john`

4. **Be Patient**
   - Password cracking can take time
   - Use distributed cracking for large jobs

### Web Application Tips

1. **Start with Reconnaissance**
   - Use `gobuster` for directory brute forcing
   - Use `dirb` for web content scanning

2. **Test for Vulnerabilities**
   - Use `sqlmap` for SQL injection
   - Use `nikto` for web server vulnerabilities

3. **Use Burp Suite**
   - Configure browser to use Burp proxy
   - Intercept and modify requests

4. **Automate Testing**
   - Use scripts for repetitive tasks
   - Save configurations for reuse

### Wireless Attack Tips

1. **Monitor Mode**
   - Use `airmon-ng start wlan0` to enable monitor mode
   - Use `airodump-ng` to capture packets

2. **Target Selection**
   - Identify target networks with `airodump-ng`
   - Focus on specific targets

3. **Capture Handshake**
   - Use `airodump-ng` to capture WPA handshake
   - Save capture to file

4. **Crack Password**
   - Use `aircrack-ng` with wordlist
   - Use `hashcat` for faster cracking

### Forensics Tips

1. **Capture Traffic**
   - Use `tcpdump` for command-line capture
   - Use `wireshark` for GUI analysis

2. **Analyze Files**
   - Use `foremost` for file carving
   - Use `binwalk` for firmware analysis

3. **Save Evidence**
   - Save capture files
   - Document findings

## Troubleshooting

### Common Issues

1. **Tool Not Found**
   - Verify the tool is installed: `which toolname`
   - Check if the tool is in PATH
   - Reinstall the tool if necessary

2. **Permission Denied**
   - Run with sudo: `sudo toolname`
   - Check file permissions
   - Check user group membership

3. **Missing Dependencies**
   - Check tool documentation for dependencies
   - Install missing libraries
   - Verify Python/Perl modules

4. **Network Issues**
   - Check network connection: `ping google.com`
   - Check Tor status: `systemctl status tor`
   - Check iptables rules: `iptables -L -n -v`

5. **GUI Tools Don't Start**
   - Check if Xorg is running
   - Check display variable: `echo $DISPLAY`
   - Try running from terminal to see errors

### Debugging Commands

```bash
# Check service status
systemctl status tor
systemctl status postgresql

# Check network
ip a
ip route
ping google.com

# Check Tor
curl --socks5 127.0.0.1:9050 https://check.torproject.org

# Check iptables
iptables -L -n -v
iptables -t nat -L -n -v

# Check processes
ps aux | grep toolname

# Check logs
journalctl -u tor
journalctl -u postgresql
```

## Performance Optimization

### Memory Usage

1. **Limit Tool Memory**
   - Use `ulimit` to limit memory usage
   - Configure tool-specific limits

2. **Use Lightweight Tools**
   - Use CLI tools instead of GUI tools
   - Use `tcpdump` instead of `wireshark`

3. **Close Unused Tools**
   - Exit tools when not in use
   - Free up memory

### CPU Usage

1. **Limit CPU Usage**
   - Use `nice` to lower priority
   - Use `cpulimit` to limit CPU usage

2. **Use Efficient Tools**
   - Use `masscan` instead of `nmap` for fast scanning
   - Use `hashcat` with GPU for faster cracking

3. **Parallel Processing**
   - Use multiple cores with `hashcat`
   - Use distributed cracking

### Storage Usage

1. **Clean Up Files**
   - Remove temporary files
   - Clean up capture files

2. **Use Compression**
   - Compress large files
   - Use efficient storage formats

3. **Limit Logs**
   - Configure log rotation
   - Limit log file sizes

## References

- [Kali Linux Tools](https://www.kali.org/tools/)
- [Nmap Documentation](https://nmap.org/book/)
- [Metasploit Documentation](https://docs.metasploit.com/)
- [Wireshark Documentation](https://www.wireshark.org/docs/)
- [John the Ripper Documentation](https://www.openwall.com/john/)
- [Hashcat Documentation](https://hashcat.net/wiki/)
- [Tor Documentation](https://www.torproject.org/docs/)

## Legal Notice

**Important**: The security tools included in Incognito OS are for educational and authorized testing purposes only. Unauthorized use of these tools against systems you do not own or have permission to test is illegal and unethical.

Always:
1. Get written permission before testing
2. Follow responsible disclosure practices
3. Comply with all applicable laws and regulations
4. Use these tools ethically and responsibly

The developers of Incognito OS are not responsible for any misuse of these tools.
