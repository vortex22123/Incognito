#!/bin/bash
# incognito-welcome.sh - Display welcome message on login
# Installed to /etc/profile.d/ by build script

echo ""
echo "  ██╗██████╗ ███████╗██████╗ ██╗   ██╗██╗███████╗"
echo "  ██║██╔══██╗██╔════╝██╔══██╗██║   ██║██║██╔════╝"
echo "  ██║██████╔╝█████╗  ██████╔╝██║   ██║██║███████╗"
echo "  ██║██╔══██╗██╔══╝  ██╔══██╗╚██╗ ██╔╝██║╚════██║"
echo "  ██║██║  ██║███████╗██║  ██║ ╚████╔╝ ██║███████║"
echo "  ╚═╝╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝  ╚═══╝  ╚═╝╚══════╝"
echo ""
echo "  Incognito OS - Fast. Private. Invisible."
echo ""
echo "  System Information:"
echo "    - Hostname: $(hostname)"
echo "    - Date: $(date)"
echo "    - Uptime: $(uptime -p)"
echo "    - Memory: $(free -h | awk '/Mem/{print $3 "/" $2}') used"
echo ""
echo "  Quick Commands:"
echo "    - toggle-tor      Toggle Tor ON/OFF"
echo "    - startx          Start desktop (if not auto-started)"
echo "    - tor-status      Check Tor connection status"
echo "    - nmap -sn 192.168.1.0/24  Network scan"
echo "    - htop            System monitor"
echo ""
echo "  Tor Status:"
if systemctl is-active --quiet tor 2>/dev/null; then
    echo "    ✓ Tor service is RUNNING"
    echo "    ✓ All traffic is routed through Tor"
else
    echo "    ✗ Tor service is STOPPED"
    echo "    ✗ Normal network access"
fi
echo ""
echo "  Type 'toggle-tor' to enable/disable Tor routing"
echo ""
