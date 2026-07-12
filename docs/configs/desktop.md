# Desktop Configuration

This document describes the desktop environment configuration for Incognito OS.

## Overview

Incognito OS uses a lightweight, minimal desktop environment based on:
- **Window Manager**: Openbox
- **Panel**: Polybar
- **App Launcher**: Rofi
- **Compositor**: Picom (optional)
- **Terminal**: Alacritty
- **File Manager**: PCManFM

## Desktop Environment Setup

### Xorg Display Server

Xorg is the display server that provides the graphical environment.

#### Configuration Files

- `/etc/X11/xorg.conf.d/10-incognito.conf` - Main Xorg configuration
- `/etc/X11/xinit/xinitrc` - xinit startup script
- `/etc/X11/Xsession` - X session script

#### Starting Xorg

```bash
# Start Xorg with default configuration
startx

# Start Xorg with custom configuration
startx /usr/bin/openbox-session

# Start Xorg with specific window manager
startx /usr/bin/openbox
```

### Openbox Window Manager

Openbox is a lightweight, highly configurable window manager.

#### Configuration Files

- `/etc/xdg/openbox/rc.xml` - Main Openbox configuration
- `/etc/xdg/openbox/menu.xml` - Application menu
- `/etc/xdg/openbox/autostart` - Startup applications
- `/etc/xdg/openbox/environment` - Environment variables

#### User Configuration

User-specific configurations can be placed in:
- `~/.config/openbox/rc.xml`
- `~/.config/openbox/menu.xml`
- `~/.config/openbox/autostart`
- `~/.config/openbox/environment`

#### Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| Alt+Tab | Switch between windows |
| Alt+Shift+Tab | Switch between windows (reverse) |
| Alt+F4 | Close window |
| Alt+Escape | Show root menu |
| Alt+d | Show client menu |
| Alt+r | Show Rofi launcher |
| Alt+t | Open terminal |
| Alt+l | Lock screen |
| Alt+q | Toggle Tor |
| Print | Take screenshot |
| Ctrl+Alt+Left/Right/Up/Down | Switch desktop |

#### Mouse Bindings

| Button | Context | Action |
|--------|---------|--------|
| Left | Desktop | Focus/Raise window |
| Right | Desktop | Show root menu |
| Left | Titlebar | Focus/Raise/Move window |
| Right | Titlebar | Show client menu |
| Left | Frame | Focus/Raise window |
| Left+Drag | Frame | Move window |
| Right+Drag | Frame | Resize window |

### Polybar Taskbar

Polybar is a fast and easy-to-use status bar.

#### Configuration Files

- `/etc/xdg/polybar/config.ini` - Main Polybar configuration
- `/usr/local/incognito/scripts/tor-status.sh` - Tor status script

#### Layout

```
[Menu] [Terminal] [File] [Firefox] [Chromium] │ RAM: X.XG/4G │ CPU: XX% │ 🟢TOR ON │ HH:MM │ ⏻
```

#### Modules

| Position | Module | Function |
|----------|--------|----------|
| Left | Menu | Application launcher (Rofi) |
| Left | Terminal | Pinned app (Alacritty) |
| Left | File | Pinned app (PCManFM) |
| Left | Firefox | Pinned app (Firefox ESR) |
| Left | Chromium | Pinned app (Chromium) |
| Center | RAM | Real-time RAM usage |
| Center | CPU | Real-time CPU usage |
| Center | Tor | Tor status toggle (🟢 ON / 🔴 OFF) |
| Center | Clock | Current time (HH:MM) |
| Right | Power | Shutdown/Restart/Logout/Suspend |

#### Customization

To customize Polybar:
1. Edit `/etc/xdg/polybar/config.ini`
2. Add/remove modules as needed
3. Change colors in the `[colors]` section
4. Adjust fonts in the `[bar/incognito-bar]` section

### Rofi Application Launcher

Rofi is a window switcher, application launcher, and dmenu replacement.

#### Configuration Files

- `/etc/xdg/rofi/config.rasi` - Main Rofi configuration

#### Usage

```bash
# Show drun (desktop entries)
rofi -show drun

# Show window list
rofi -show window

# Show custom menu
rofi -show menu -modi "Incognito:incognito-menu"
```

#### Customization

To customize Rofi:
1. Edit `/etc/xdg/rofi/config.rasi`
2. Change colors in the `configuration` block
3. Adjust window size and layout
4. Modify font settings

### Picom Compositor (Optional)

Picom is a compositor for X11 that provides transparency and shadows.

#### Configuration Files

- `/etc/xdg/picom/picom.conf` - Main Picom configuration

#### Features

- **Transparency**: Adjust window opacity
- **Shadows**: Add shadows to windows
- **Blur**: Blur background windows
- **Animations**: Smooth window animations
- **Fading**: Fade windows in/out

#### Customization

To customize Picom:
1. Edit `/etc/xdg/picom/picom.conf`
2. Adjust opacity settings
3. Modify shadow parameters
4. Enable/disable blur effects
5. Configure animations

### Alacritty Terminal

Alacritty is a fast, cross-platform, OpenGL terminal emulator.

#### Configuration Files

- `/etc/xdg/alacritty/alacritty.yml` - Main Alacritty configuration

#### Features

- GPU-accelerated
- Vi mode support
- Live configuration reload
- True color support
- Ligature support

#### Customization

To customize Alacritty:
1. Edit `/etc/xdg/alacritty/alacritty.yml`
2. Change color scheme
3. Adjust font settings
4. Modify window dimensions
5. Configure key bindings

### PCManFM File Manager

PCManFM is a lightweight GTK-based file manager.

#### Features

- Tabbed browsing
- Thumbnail support
- Desktop management
- Bookmarks
- Volume management

#### Customization

To customize PCManFM:
1. Edit `/etc/xdg/pcmanfm/default/pcmanfm.conf`
2. Change view settings
3. Configure desktop behavior
4. Set default applications

## Theming

### Color Scheme

| Element | Color | Hex |
|---------|-------|-----|
| Primary | Black | #0a0a0a |
| Secondary | Dark Gray | #1a1a1a |
| Accent | Green | #00ff88 |
| Accent2 | Cyan | #00ccff |
| Text | White | #ffffff |
| Danger | Red | #ff4444 |
| Warning | Yellow | #ffaa00 |

### Fonts

| Type | Font | Size |
|------|------|------|
| System | DejaVu Sans | 10 |
| Monospace | DejaVu Sans Mono | 10 |
| Terminal | JetBrains Mono | 10 |
| Bold | DejaVu Sans Bold | 10 |

### Icons

- **Icon Set**: Papirus-Dark
- **Location**: `/usr/share/icons/Papirus-Dark/`
- **Size**: 16x16, 24x24, 32x32, 48x48, 256x256

### Wallpaper

- **Location**: `/usr/share/backgrounds/incognito/`
- **Default**: `default.png`
- **Resolution**: 1920x1080 (scalable)
- **Style**: Dark, minimal, mysterious

## Desktop Environment Setup

### Starting the Desktop

1. **From Console**
   ```bash
   startx
   ```

2. **From Display Manager** (if installed)
   - Select "Incognito OS" from the login menu
   - Log in with username and password

3. **Automatic Start**
   - Configure your display manager to auto-start Openbox
   - Or use `.xinitrc` for auto-start

### Autostart Applications

Applications that start automatically with the desktop:
- **feh**: Wallpaper setter
- **picom**: Compositor (optional)
- **polybar**: Taskbar
- **setxkbmap**: Keyboard layout

### Environment Variables

| Variable | Value | Purpose |
|----------|-------|---------|
| DISPLAY | :0 | X display |
| XDG_CONFIG_DIRS | /etc/xdg | Configuration directories |
| XDG_DATA_DIRS | /usr/share | Data directories |
| XDG_CACHE_HOME | ~/.cache | Cache directory |
| XDG_CONFIG_HOME | ~/.config | Configuration directory |
| XDG_DATA_HOME | ~/.local/share | Data directory |

## Customization Guide

### Adding New Applications

1. **Install the Application**
   ```bash
   apt install application-name
   ```

2. **Add to Menu**
   - Edit `/etc/xdg/openbox/menu.xml`
   - Add a new `<item>` entry
   - Or create a `.desktop` file in `/usr/share/applications/`

3. **Add to Polybar**
   - Edit `/etc/xdg/polybar/config.ini`
   - Add a new module in the `modules-left` or `modules-right` list

4. **Add Keyboard Shortcut**
   - Edit `/etc/xdg/openbox/rc.xml`
   - Add a new `<keybind>` entry

### Changing the Theme

1. **Openbox Theme**
   - Edit `/etc/xdg/openbox/rc.xml`
   - Change the `<name>` in the `<theme>` section
   - Or create a new theme in `~/.themes/`

2. **Polybar Theme**
   - Edit `/etc/xdg/polybar/config.ini`
   - Change colors in the `[colors]` section

3. **Rofi Theme**
   - Edit `/etc/xdg/rofi/config.rasi`
   - Change colors and layout

### Changing Wallpaper

1. **Manual Method**
   ```bash
   feh --bg-scale /path/to/wallpaper.png
   ```

2. **Permanent Method**
   - Edit `/etc/xdg/openbox/autostart`
   - Change the `feh` command to point to your wallpaper

3. **User Method**
   - Edit `~/.config/openbox/autostart`
   - Add your wallpaper command

## Troubleshooting

### Common Issues

1. **Desktop Doesn't Start**
   - Check if Xorg is running: `ps aux | grep X`
   - Check Xorg logs: `cat /var/log/Xorg.0.log`
   - Verify display manager is running

2. **Polybar Doesn't Show**
   - Check if Polybar is running: `ps aux | grep polybar`
   - Check Polybar logs: `polybar incognito-bar 2>&1`
   - Verify configuration file syntax

3. **Openbox Doesn't Start**
   - Check if Openbox is running: `ps aux | grep openbox`
   - Check Openbox logs: `openbox --replace 2>&1`
   - Verify configuration file syntax

4. **No Sound**
   - Check if PulseAudio/ALSA is running
   - Check volume: `alsamixer`
   - Verify sound card: `aplay -l`

5. **No Network**
   - Check network interface: `ip a`
   - Check routing: `ip route`
   - Check DNS: `cat /etc/resolv.conf`

### Debugging Commands

```bash
# Check running processes
ps aux

# Check Xorg logs
cat /var/log/Xorg.0.log

# Check Openbox logs
openbox --replace 2>&1

# Check Polybar logs
polybar incognito-bar 2>&1

# Check display
xrandr

# Check window manager
wmctrl -m

# Check environment
printenv
```

## Performance Tips

### Reducing Memory Usage

1. **Disable Picom** (if not needed)
   - Remove from autostart
   - Or use simpler effects

2. **Reduce Polybar Modules**
   - Remove unnecessary modules
   - Increase update intervals

3. **Use Lighter Applications**
   - Use `st` instead of Alacritty
   - Use `ranger` instead of PCManFM
   - Use `scrot` instead of flameshot

4. **Disable Unnecessary Services**
   ```bash
   systemctl disable bluetooth
   systemctl disable cups
   systemctl disable avahi-daemon
   ```

### Improving Performance

1. **Enable Compositing**
   - Use Picom for better rendering
   - Enable vsync in Picom

2. **Use Faster Terminal**
   - Use `st` (simple terminal)
   - Or `urxvt` (rxvt-unicode)

3. **Optimize Openbox**
   - Reduce animations
   - Disable unnecessary features

4. **Use Lightweight Applications**
   - `feh` instead of `eog`
   - `mpv` instead of `vlc`
   - `nano` instead of `vim`

## References

- [Openbox Documentation](http://openbox.org/wiki/Help:Contents)
- [Polybar Documentation](https://github.com/polybar/polybar/wiki)
- [Rofi Documentation](https://github.com/davatorium/rofi/wiki)
- [Picom Documentation](https://github.com/yshui/picom/wiki)
- [Alacritty Documentation](https://github.com/alacritty/alacritty/wiki)
