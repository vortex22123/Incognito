#!/bin/bash
# Incognito OS - Tor Toggle Script
# Fix: idempotent (flush before set), kill-switch tidak bocor,
#      baseline firewall restore saat Tor OFF.

set -euo pipefail

if [ "$(id -u)" -ne 0 ]; then
    echo "Script ini harus dijalankan sebagai root (sudo)."
    exit 1
fi

STATE_FILE="/run/incognito-tor-state"
TRANS_PORT=9040
DNS_PORT=5353

resolve_tor_uid() {
    # JANGAN fallback ke UID 0 (root) - akan bikin kill-switch bocor diam-diam
    if id -u debian-tor >/dev/null 2>&1; then
        id -u debian-tor
    elif id -u tor >/dev/null 2>&1; then
        id -u tor
    else
        echo "ERROR: user 'debian-tor'/'tor' tidak ditemukan." >&2
        echo "Pastikan paket Tor sudah terinstall sebelum menjalankan toggle." >&2
        exit 1
    fi
}

flush_all() {
    iptables -F
    iptables -X
    iptables -t nat -F
    iptables -t nat -X
    iptables -t mangle -F
    iptables -t mangle -X
    iptables -P INPUT ACCEPT
    iptables -P OUTPUT ACCEPT
    iptables -P FORWARD ACCEPT
}

restore_baseline() {
    # Kembalikan ke baseline firewall (deny-by-default input, allow output)
    flush_all
    iptables -P INPUT DROP
    iptables -P FORWARD DROP
    iptables -P OUTPUT ACCEPT
    iptables -A INPUT -i lo -j ACCEPT
    iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
}

tor_on() {
    local tor_uid
    tor_uid="$(resolve_tor_uid)"

    echo "🟢 Starting Tor..."
    systemctl start tor

    # Wait for Tor to be ready
    local tries=0
    while ! systemctl is-active --quiet tor && [ $tries -lt 10 ]; do
        sleep 1; tries=$((tries+1))
    done
    systemctl is-active --quiet tor || { echo "ERROR: Tor gagal start"; exit 1; }

    # Flush dulu supaya idempotent - aman dipanggil ulang tanpa numpuk rule
    flush_all
    iptables -P INPUT DROP
    iptables -P FORWARD DROP
    iptables -P OUTPUT DROP

    # Allow loopback
    iptables -A INPUT  -i lo -j ACCEPT
    iptables -A OUTPUT -o lo -j ACCEPT

    # Allow established
    iptables -A INPUT  -m state --state ESTABLISHED,RELATED -j ACCEPT
    iptables -A OUTPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

    # Allow Tor process itself (output)
    iptables -A OUTPUT -m owner --uid-owner "$tor_uid" -j ACCEPT

    # Redirect DNS through Tor
    iptables -t nat -A OUTPUT -p udp --dport 53 -j REDIRECT --to-ports "$DNS_PORT"
    iptables -t nat -A OUTPUT -p tcp --dport 53 -j REDIRECT --to-ports "$DNS_PORT"

    # Redirect ALL TCP through transparent proxy
    iptables -t nat -A OUTPUT -p tcp --syn \
        -m owner ! --uid-owner "$tor_uid" -j REDIRECT --to-ports "$TRANS_PORT"

    echo "on" > "$STATE_FILE"
    echo "🟢 TOR ON"
}

tor_off() {
    echo "🔴 Stopping Tor..."
    systemctl stop tor
    restore_baseline
    echo "off" > "$STATE_FILE"
    echo "🔴 TOR OFF"
}

# Signal Polybar module untuk refresh (module type=custom/script pakai signal)
notify_polybar() {
    pkill -RTMIN+8 polybar 2>/dev/null || true
}

case "${1:-toggle}" in
    on)     tor_on ;;
    off)    tor_off ;;
    status)
        if [ -f "$STATE_FILE" ] && [ "$(cat "$STATE_FILE")" = "on" ]; then
            echo "🟢 TOR ON"
        else
            echo "🔴 TOR OFF"
        fi
        ;;
    toggle)
        if systemctl is-active --quiet tor; then
            tor_off
        else
            tor_on
        fi
        ;;
    *)
        echo "Usage: $0 {on|off|status|toggle}"; exit 1 ;;
esac

notify_polybar
