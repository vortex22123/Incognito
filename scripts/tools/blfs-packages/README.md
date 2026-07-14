# scripts/tools/blfs-packages/

Sub-script build-from-source untuk paket BLFS (dipanggil dari phase2 & phase3).

Yang perlu ditambahkan seiring build:
- `systemd.sh`
- `tor.sh`
- `xorg.sh`
- `openbox.sh`
- `polybar.sh`
- `rofi.sh`
- `picom.sh`

Tiap script idealnya: download (kalau belum ada di `$LFS/sources`) -> extract
-> configure -> build -> install -> cleanup build dir. Versi paket ada di
`packages/blfs-packages.txt`.
