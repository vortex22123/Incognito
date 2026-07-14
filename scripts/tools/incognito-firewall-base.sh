#!/bin/bash
# incognito-firewall-base.sh
# Baseline firewall: deny-by-default INPUT/FORWARD, allow established/loopback.
# Dipanggil oleh configs/systemd/incognito-firewall.service saat boot.
# Dipasang ke /usr/local/sbin/ oleh scripts/build/phase2-blfs-networking.sh.

set -euo pipefail

iptables -F
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT ACCEPT
iptables -A INPUT -i lo -j ACCEPT
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
