#!/bin/bash
# tor-toggle.sh
# Toggle Tor ON/OFF + update indikator Polybar, sesuai deskripsi README:
#  "Starts/stops the Tor service, Configures iptables to route traffic through Tor,
#   Updates Polybar indicator (green ON / red OFF)"
#
# Install: taruh di /usr/local/bin/tor-toggle, chmod +x, bind ke keybind Openbox/Rofi.

set -euo pipefail

STATE_FILE="/run/incognito-tor-state"
TRANS_PORT=9040
DNS_PORT=5353

need_root() {
    [ "$(id -u)" -eq 0 ] || { echo "Jalankan dengan sudo."; exit 1; }
}

resolve_tor_uid() {
    # PENTING: jangan pernah fallback ke UID 0. Kalau ini fallback ke root,
    # rule "-m owner --uid-owner 0 -j ACCEPT" akan meloloskan SEMUA proses
    # yang jalan sebagai root tanpa lewat Tor - kill switch jadi bocor diam-diam.
    if id -u debian-tor >/dev/null 2>&1; then
        id -u debian-tor
    elif id -u tor >/dev/null 2>&1; then
        id -u tor
    else
        echo "ERROR: user 'debian-tor'/'tor' tidak ditemukan. Pastikan paket Tor" >&2
        echo "sudah terinstall (lihat scripts/build/phase2-blfs-networking.sh) sebelum" >&2
        echo "menjalankan tor-toggle. Membatalkan supaya tidak membuat kill switch palsu." >&2
        exit 1
    fi
}

tor_on() {
    local tor_uid
    tor_uid="$(resolve_tor_uid)"

    systemctl start tor

    # Flush dulu supaya idempotent - aman dipanggil ulang tanpa numpuk rule
    iptables -t nat -F OUTPUT
    iptables -F OUTPUT

    iptables -t nat -A OUTPUT -m owner --uid-owner "$tor_uid" -j RETURN
    iptables -t nat -A OUTPUT -p udp --dport 53 -j REDIRECT --to-ports "$DNS_PORT"
    iptables -t nat -A OUTPUT -p tcp --syn -j REDIRECT --to-ports "$TRANS_PORT"

    iptables -A OUTPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
    iptables -A OUTPUT -o lo -j ACCEPT
    iptables -A OUTPUT -m owner --uid-owner "$tor_uid" -j ACCEPT
    iptables -A OUTPUT -j REJECT

    echo "on" > "$STATE_FILE"
    echo "Tor: ON"
}

tor_off() {
    systemctl stop tor

    iptables -t nat -F OUTPUT
    iptables -F OUTPUT
    iptables -P OUTPUT ACCEPT

    echo "off" > "$STATE_FILE"
    echo "Tor: OFF"
}

status() {
    if [ -f "$STATE_FILE" ] && [ "$(cat "$STATE_FILE")" = "on" ]; then
        echo "🟢 TOR ON"
    else
        echo "🔴 TOR OFF"
    fi
}

main() {
    need_root
    case "${1:-toggle}" in
        on)     tor_on ;;
        off)    tor_off ;;
        status) status ;;
        toggle)
            if [ -f "$STATE_FILE" ] && [ "$(cat "$STATE_FILE")" = "on" ]; then
                tor_off
            else
                tor_on
            fi
            ;;
        *) echo "Usage: $0 {on|off|status|toggle}"; exit 1 ;;
    esac

    # Signal Polybar module untuk refresh (module type=custom/script pakai signal)
    pkill -RTMIN+8 polybar 2>/dev/null || true
}

main "$@"
