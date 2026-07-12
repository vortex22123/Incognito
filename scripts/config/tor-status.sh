#!/bin/bash
# Tor status script for Polybar

if systemctl is-active --quiet tor; then
    echo "🟢 TOR ON"
else
    echo "🔴 TOR OFF"
fi
