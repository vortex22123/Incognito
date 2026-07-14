#!/bin/bash
# Dipanggil oleh module tor-status di config.ini
/usr/local/bin/tor-toggle status 2>/dev/null || echo "🔴 TOR OFF"
