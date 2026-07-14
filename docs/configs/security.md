# Security Tools

Daftar tool security/pentest yang terpasang lewat `scripts/build/phase4-security-tools.sh`, diambil dari repo Kali rolling.

| Tool | Kategori | Kegunaan singkat |
|---|---|---|
| nmap | Recon | Network/port scanning |
| hydra | Brute-force | Login cracking (multi-protocol) |
| metasploit-framework | Exploitation | Framework exploit & payload |
| sqlmap | Web | Automasi SQL injection testing |
| burpsuite | Web | Proxy/intercept untuk web app testing |
| wireshark | Recon | Packet capture & analysis |
| aircrack-ng | Wireless | Suite audit keamanan WiFi (WEP/WPA) |
| john | Cracking | Password cracker (John the Ripper) |
| hashcat | Cracking | Password cracker berbasis GPU |
| netcat-traditional | Network | Utility TCP/UDP serba guna |
| tcpdump | Recon | Packet capture CLI |
| nikto | Web | Web server vulnerability scanner |
| dirb / gobuster | Web | Directory/file brute-forcing |

## Catatan Etika & Legalitas

Semua tool di atas adalah dual-use — dipakai profesional pentest/red team dengan izin eksplisit dari pemilik sistem, sekaligus bisa disalahgunakan. Incognito OS menyediakan tool-nya (sama seperti Kali Linux), tapi tanggung jawab pemakaian ada di user. Gunakan hanya pada sistem milik sendiri atau dengan otorisasi tertulis (pentest engagement, CTF, lab pribadi).

## Menambah Tool Baru

1. Tambahkan nama paket ke array `SECURITY_PACKAGES` di `scripts/build/phase4-security-tools.sh`
2. Kalau tool tidak tersedia di repo Kali/Debian, buat sub-script build-from-source di `scripts/tools/security-packages/<nama-tool>.sh`
3. Jalankan ulang phase4, cek `packages/security-tools.lock` untuk konfirmasi versi terpasang

## Update Daftar Terpasang

```bash
sudo scripts/build/phase4-security-tools.sh
cat packages/security-tools.lock
```
