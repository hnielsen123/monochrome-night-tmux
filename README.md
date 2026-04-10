# Monochrome Night Tmux

A personal tmux theme, forked from [jarnoamaral/tokyo-night-tmux](https://github.com/janoamaral/tokyo-night-tmux)


## Requirements

This theme has the following hard requirements:

- Any patched [Nerd Fonts] (v3 or higher)
- Bash 4.2 or newer

The following are recommended for full support of all widgets and features:

- [Noto Sans] Symbols 2 (for segmented digit numbers)
- [bc] (for netspeed and git widgets)
- [jq], [gh], [glab] (for git widgets)
- [playerctl] (Linux) or [nowplaying-cli] (macOS) for music statusbar

### macOS

macOS still ships with bash 3.2 so you must provide a newer version.
You can easily install all dependencies via [Homebrew]:

```bash
brew install --cask font-monaspace-nerd-font font-noto-sans-symbols-2
brew install bash bc coreutils gawk gh glab gsed jq nowplaying-cli
```

### Linux

#### Alpine Linux

```bash
apk add bash bc coreutils gawk git jq playerctl sed
```

#### Arch Linux

```bash
pacman -Sy bash bc coreutils git jq playerctl
```

#### Ubuntu

```bash
apt-get install bash bc coreutils gawk git jq playerctl
```

Check documentation for installing on other operating systems.

## Installation using TPM

In your `tmux.conf`:

```bash
set -g @plugin "janoamaral/tokyo-night-tmux"
```

## Configuration

### Themes

Use following option to change theme preference:

```bash
set -g @monochrome-night-tmux_theme storm    # storm | day | night | defaults to 'monochrome'
set -g @monochrome-night-tmux_transparent 1  # 1 or 0
```

### Number styles

Run these commands in your terminal:

```bash
tmux set @monochrome-night-tmux_window_id_style digital
tmux set @monochrome-night-tmux_pane_id_style hsquare
tmux set @monochrome-night-tmux_zoom_id_style dsquare
```

Alternatively, add these lines to your  `.tmux.conf`:

```bash
set -g @monochrome-night-tmux_window_id_style digital
set -g @monochrome-night-tmux_pane_id_style hsquare
set -g @monochrome-night-tmux_zoom_id_style dsquare
```

### Window styles

```bash
# Icon styles
set -g @monochrome-night-tmux_terminal_icon 
set -g @monochrome-night-tmux_active_terminal_icon 

# No extra spaces between icons
set -g @monochrome-night-tmux_window_tidy_icons 0
```

### Widgets

For widgets add following lines in you `.tmux.conf`

#### Date and Time widget

This widget is enabled by default. To disable it:

```bash
set -g @monochrome-night-tmux_show_datetime 0
set -g @monochrome-night-tmux_date_format MYD
set -g @monochrome-night-tmux_time_format 12H
```

##### Available Options

- `YMD`: (Year Month Day), 2024-01-31
- `MDY`: (Month Day Year), 01-31-2024
- `DMY`: (Day Month Year), 31-01-2024

- `24H`: 18:30
- `12H`: 6:30 PM

#### Now Playing widget

```bash
set -g @monochrome-night-tmux_show_music 1
```

#### Netspeed widget
![Snap netspeed](snaps/netspeed.png)

```bash
set -g @monochrome-night-tmux_show_netspeed 1
set -g @monochrome-night-tmux_netspeed_iface "wlan0" # Detected via default route
set -g @monochrome-night-tmux_netspeed_showip 1      # Display IPv4 address (default 0)
set -g @monochrome-night-tmux_netspeed_refresh 1     # Update interval in seconds (default 1)
```

#### Path Widget

```bash
set -g @monochrome-night-tmux_show_path 1
set -g @monochrome-night-tmux_path_format relative # 'relative' or 'full'
```

#### Battery Widget

```bash
set -g @monochrome-night-tmux_show_battery_widget 1
set -g @monochrome-night-tmux_battery_name "BAT1"  # some linux distro have 'BAT0'
set -g @monochrome-night-tmux_battery_low_threshold 21 # default
```

Set variable value `0` to disable the widget. Remember to restart `tmux` after
changing values.

#### Hostname Widget

```bash
set -g @monochrome-night-tmux_show_hostname 1
```

## Styles

- `hide`: hide number
- `none`: no style, default font
- `digital`: 7 segment number (🯰...🯹) (needs [Unicode support](https://github.com/janoamaral/tokyo-night-tmux/issues/36#issuecomment-1907072080))
- `roman`: roman numbers (󱂈...󱂐) (needs nerdfont)
- `fsquare`: filled square (󰎡...󰎼) (needs nerdfont)
- `hsquare`: hollow square (󰎣...󰎾) (needs nerdfont)
- `dsquare`: hollow double square (󰎡...󰎼) (needs nerdfont)
- `super`: superscript symbol (⁰...⁹)
- `sub`: subscript symbols (₀...₉)

