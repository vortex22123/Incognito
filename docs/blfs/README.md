# BLFS Configuration Notes

Catatan build fase 2-3 (networking, systemd, desktop) mengikuti [Beyond Linux From Scratch Book](https://www.linuxfromscratch.org/blfs/view/stable/).

## Fase 2 — Networking & Systemd

Dikerjakan oleh `scripts/build/phase2-blfs-networking.sh`:

| Komponen | Sumber config |
|---|---|
| systemd | build from source (BLFS ch. systemd) |
| systemd-networkd | `configs/systemd/20-wired.network` |
| Tor | `configs/tor/torrc` |
| Firewall dasar | `configs/systemd/incognito-firewall.service` |

## Fase 3 — Desktop Environment

Dikerjakan oleh `scripts/build/phase3-desktop-openbox.sh`:

| Komponen | Config repo | Catatan |
|---|---|---|
| Xorg server | - | build minimal, tanpa driver proprietary |
| Openbox | `configs/openbox/rc.xml`, `menu.xml`, `autostart` | window manager utama |
| Polybar | `configs/polybar/config.ini` | panel/taskbar, termasuk indikator Tor |
| Rofi | `configs/rofi/config.rasi` | app launcher (`Super+Enter`) |
| Picom | `configs/picom/picom.conf` | compositor opsional, transparansi ringan |

## Status

- [x] Config file desktop stack (openbox/polybar/rofi/picom)
- [x] Kerangka script build fase 2 & 3
- [ ] Sub-script build-from-source per paket BLFS (taruh di `scripts/tools/blfs-packages/`)
- [ ] Daftar versi paket final (isi `packages/blfs-packages.txt`)

## Referensi

- BLFS Book stable: https://www.linuxfromscratch.org/blfs/view/stable/
