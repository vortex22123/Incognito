# Desktop Setup

Ringkasan cara pakai & kustomisasi desktop environment Incognito OS.

## Komponen

- **Window Manager**: Openbox — config di `configs/openbox/rc.xml` (keybinding, tema, workspace)
- **Panel**: Polybar — config di `configs/polybar/config.ini`
- **Launcher**: Rofi — config di `configs/rofi/config.rasi`, dipanggil via `Super+Enter`
- **Compositor**: Picom (opsional) — `configs/picom/picom.conf`

## Keybinding Default

| Shortcut | Aksi |
|---|---|
| `Super+Enter` | Buka Rofi (drun) |
| `Super+D` | Buka Rofi (run) |
| `Super+T` | Buka terminal |
| `Super+E` | Toggle Tor ON/OFF |
| `Super+Q` / `Alt+F4` | Close window |
| `Super+1..4` | Pindah workspace |

## Mengganti Wallpaper

```bash
feh --bg-scale /path/ke/wallpaper.png
nitrogen --save --set-scaled /path/ke/wallpaper.png   # supaya persist antar reboot
```

Wallpaper default ada di `assets/wallpapers/`.

## Menambah Module Polybar

Edit `configs/polybar/config.ini`, tambahkan section `[module/nama-baru]`, lalu daftarkan di `modules-left/center/right` pada `[bar/main]`. Script pendukung module custom ditaruh di `configs/polybar/scripts/`.

## Restart Desktop Tanpa Logout

```bash
openbox --reconfigure
polybar-msg cmd restart
```
