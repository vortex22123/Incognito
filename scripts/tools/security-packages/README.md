# scripts/tools/security-packages/

Opsional: sub-script build-from-source untuk security tool yang TIDAK tersedia
lewat repo Kali/Debian (dipakai sebagai fallback oleh
`scripts/build/phase4-security-tools.sh` kalau `apt-get install` gagal untuk
suatu paket).

Kosong untuk saat ini karena semua tool di README (nmap, hydra,
metasploit-framework, sqlmap, burpsuite, wireshark, aircrack-ng, john, hashcat,
netcat, tcpdump, nikto, dirb, gobuster) tersedia di repo Kali rolling.
