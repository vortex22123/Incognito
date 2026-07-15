#!/bin/bash
# toggle-tor.sh - Toggle Tor ON/OFF with iptables rules
# Usage: toggle-tor [on|off|status]

set -euo pipefail

TOR_SERVICE="tor.service"
TOR_STATUS_FILE="/tmp/tor_enabled"

log() {
    echo "[TOR] $*"
}

tor_is_running() {
    systemctl is-active --quiet "$TOR_SERVICE" 2>/dev/null || false
}

tor_is_enabled() {
    [ -f "$TOR_STATUS_FILE" ] && [ "$(cat "$TOR_STATUS_FILE" 2>/dev/null)" = "enabled" ]
}

tor_start() {
    log "Starting Tor service..."
    systemctl start "$TOR_SERVICE"
    sleep 2
    if ! tor_is_running; then
        log "Failed to start Tor service"
        return 1
    fi
    log "Tor service started"
    return 0
}

tor_stop() {
    log "Stopping Tor service..."
    systemctl stop "$TOR_SERVICE"
    if tor_is_running; then
        log "Failed to stop Tor service"
        return 1
    fi
    log "Tor service stopped"
    return 0
}

setup_tor_iptables() {
    log "Setting up Tor iptables rules..."
    
    # Flush existing rules
    iptables -F
    iptables -t nat -F
    
    # Default policies
    iptables -P INPUT DROP
    iptables -P FORWARD DROP
    iptables -P OUTPUT ACCEPT
    
    # Allow loopback
    iptables -A INPUT -i lo -j ACCEPT
    iptables -A OUTPUT -o lo -j ACCEPT
    
    # Allow established connections
    iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
    iptables -A OUTPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
    
    # Redirect HTTP/HTTPS/DNS through Tor
    iptables -t nat -A OUTPUT -p tcp --dport 80 -j REDIRECT --to-ports 9040
    iptables -t nat -A OUTPUT -p tcp --dport 443 -j REDIRECT --to-ports 9040
    iptables -t nat -A OUTPUT -p udp --dport 53 -j REDIRECT --to-ports 5353
    iptables -t nat -A OUTPUT -p tcp --dport 53 -j REDIRECT --to-ports 5353
    
    # Allow Tor traffic
    iptables -A OUTPUT -p tcp -m owner --uid-owner debian-tor -j ACCEPT
    iptables -A OUTPUT -p udp -m owner --uid-owner debian-tor -j ACCEPT
    
    # Allow local services (DHCP, etc.)
    iptables -A OUTPUT -p udp --dport 67:68 -j ACCEPT
    
    log "Tor iptables rules applied"
    echo "enabled" > "$TOR_STATUS_FILE"
}

remove_tor_iptables() {
    log "Removing Tor iptables rules..."
    
    # Flush all rules
    iptables -F
    iptables -t nat -F
    
    # Set default policies to ACCEPT (normal operation)
    iptables -P INPUT ACCEPT
    iptables -P FORWARD ACCEPT
    iptables -P OUTPUT ACCEPT
    
    # Allow loopback
    iptables -A INPUT -i lo -j ACCEPT
    iptables -A OUTPUT -o lo -j ACCEPT
    
    # Allow established connections
    iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
    iptables -A OUTPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
    
    log "Tor iptables rules removed"
    echo "disabled" > "$TOR_STATUS_FILE"
}

show_status() {
    if tor_is_enabled && tor_is_running; then
        echo "Tor is ENABLED and RUNNING"
        echo "All traffic is being routed through Tor"
        echo "SOCKS Port: 9050"
        echo "TransPort: 9040"
        echo "DNS Port: 5353"
    elif tor_is_running; then
        echo "Tor service is RUNNING but iptables rules are not active"
    elif tor_is_enabled; then
        echo "Tor iptables rules are active but service is not running"
    else
        echo "Tor is DISABLED"
        echo "Normal network access is available"
    fi
    
    echo ""
    echo "Tor service status:"
    systemctl status "$TOR_SERVICE" 2>/dev/null | head -5 || echo "Tor service not found"
}

case "${1:-status}" in
    on|enable)
        if tor_is_enabled; then
            log "Tor is already enabled"
            exit 0
        fi
        tor_start || exit 1
        setup_tor_iptables
        log "Tor is now ENABLED - all traffic routed through Tor"
        ;;
    off|disable)
        if ! tor_is_enabled; then
            log "Tor is already disabled"
            exit 0
        fi
        remove_tor_iptables
        tor_stop || exit 1
        log "Tor is now DISABLED - normal network access restored"
        ;;
    toggle)
        if tor_is_enabled; then
            remove_tor_iptables
            tor_stop
            log "Tor is now DISABLED"
        else
            tor_start
            setup_tor_iptables
            log "Tor is now ENABLED"
        fi
        ;;
    status)
        show_status
        ;;
    *)
        echo "Usage: $0 [on|off|toggle|status]"
        echo ""
        echo "  on/enable    - Enable Tor and route all traffic through it"
        echo "  off/disable  - Disable Tor and restore normal network"
        echo "  toggle      - Switch between enabled/disabled"
        echo "  status      - Show current Tor status"
        exit 1
        ;;
esac
