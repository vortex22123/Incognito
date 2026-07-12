#!/bin/bash
# Incognito OS - Tor Toggle Script
# Toggles Tor service and iptables rules

# Check if running as root
if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root"
    exit 1
fi

if systemctl is-active --quiet tor; then
    # Tor is running, stop it and clear iptables
    echo "🔴 Stopping Tor..."
    systemctl stop tor
    
    # Clear iptables rules
    iptables -F
    iptables -X
    iptables -t nat -F
    iptables -t nat -X
    iptables -t mangle -F
    iptables -t mangle -X
    
    # Remove Tor DNS
    iptables -t nat -D OUTPUT -p udp --dport 53 -j REDIRECT --to-port 5353 2>/dev/null || true
    iptables -t nat -D OUTPUT -p tcp --dport 53 -j REDIRECT --to-port 5353 2>/dev/null || true
    
    echo "🔴 TOR OFF"
else
    # Tor is stopped, start it and configure iptables
    echo "🟢 Starting Tor..."
    systemctl start tor
    
    # Wait for Tor to be ready
    sleep 5
    
    # Configure iptables to route traffic through Tor
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
    
    # Redirect HTTP and HTTPS traffic through Tor
    iptables -t nat -A OUTPUT -p tcp --dport 80 -j REDIRECT --to-port 9040
    iptables -t nat -A OUTPUT -p tcp --dport 443 -j REDIRECT --to-port 9040
    
    # Redirect DNS through Tor
    iptables -t nat -A OUTPUT -p udp --dport 53 -j REDIRECT --to-port 5353
    iptables -t nat -A OUTPUT -p tcp --dport 53 -j REDIRECT --to-port 5353
    
    # Block all other outgoing traffic (optional - strict mode)
    # iptables -A OUTPUT -j REJECT
    
    echo "🟢 TOR ON"
fi
