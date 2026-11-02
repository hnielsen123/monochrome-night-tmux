# Monochrome Night Tmux

A personal tmux theme, forked from [janoamaral/tokyo-night-tmux](https://github.com/janoamaral/tokyo-night-tmux). Also runs on Windows under psmux (see [psmux (Windows)](#psmux-windows)).

## Requirements

Hard requirements:

- A patched [Nerd Font][Nerd Fonts] (v3 or higher)
- Bash 4.2 or newer

Optional, per widget:

- [Noto Sans Symbols 2][Noto Sans] for the `digital` number style
- [bc] for the netspeed and git widgets
- [gh] or [glab], plus [jq], for the web git widget
- [playerctl] (Linux) or [nowplaying-cli] (macOS) for the music widget

### macOS

macOS still ships with bash 3.2, so install a newer one. Everything is available via [Homebrew]:

```bash
brew install --cask font-monaspace-nerd-font font-noto-sans-symbols-2
brew install bash bc coreutils gawk gh glab gsed jq nowplaying-cli
```

### Linux

```bash
apk add bash bc coreutils gawk git jq playerctl sed   # Alpine
pacman -Sy bash bc coreutils git jq playerctl         # Arch
apt-get install bash bc coreutils gawk git jq playerctl  # Ubuntu
```

## Installation (TPM)

```bash
set -g @plugin "hnielsen123/monochrome-night-tmux"
```

## Configuration

Options are read when the theme loads, so restart tmux (or re-source the config) after changing them.

The left side of the status bar is fixed: a prefix indicator and the hostname.

### Theme

```bash
set -g @monochrome-night-tmux_theme storm    # storm | day | night (default: monochrome)
set -g @monochrome-night-tmux_transparent 1  # 1 = use the terminal background (default: 0)
```

### Window numbers

```bash
set -g @monochrome-night-tmux_window_id_style digital   # default: fsquare
```

Styles:

- `hide`: hide the number
- `none`: plain digits
- `digital`: 7-segment digits (🯰...🯹) (needs Noto Sans Symbols 2 or another font with [Symbols for Legacy Computing](https://github.com/janoamaral/tokyo-night-tmux/issues/36#issuecomment-1907072080))
- `roman`: roman numerals (󱂈...󱂐), single-digit windows only (needs a Nerd Font)
- `fsquare`: filled squares (󰎡...󰎼) (needs a Nerd Font)
- `hsquare`: hollow squares (󰎣...󰎾) (needs a Nerd Font)
- `dsquare`: hollow double squares (󰎢...󰎽) (needs a Nerd Font)
- `super`: superscript (⁰...⁹)
- `sub`: subscript (₀...₉)

### Window icons

```bash
set -g @monochrome-night-tmux_terminal_icon          # inactive windows (default shown)
set -g @monochrome-night-tmux_active_terminal_icon   # active window (default shown)
set -g @monochrome-night-tmux_window_tidy_icons 0     # 0 = add a space after the icon (default: no space)
```

Windows running `ssh` get an ssh icon instead.

### Widgets

The right side of the status bar is built from these, in this order: battery, path, music, network, git, web git, date/time.

#### Date and time (on by default)

```bash
set -g @monochrome-night-tmux_show_datetime 0   # disable
set -g @monochrome-night-tmux_date_format YMD   # YMD | MDY | DMY | hide (default: MDY)
set -g @monochrome-night-tmux_time_format 24H   # 12H | 24H | hide (default: 12H)
```

- `YMD`: 2024-01-31
- `MDY`: 01-31-2024
- `DMY`: 31-01-2024
- `24H`: 18:30
- `12H`: 06:30 PM

#### Git (on by default)

Branch, sync state and diff stats for the current pane's repo.

```bash
set -g @monochrome-night-tmux_show_git 0   # disable
```

#### Web git (on by default)

Open PR, review, issue and bug counts from GitHub (via `gh`) or GitLab (via `glab`) for the current pane's repo. Makes API calls on every status refresh.

```bash
set -g @monochrome-night-tmux_show_wbg 0   # disable
```

#### Network (netspeed / IP)

```bash
set -g @monochrome-night-tmux_show_netspeed 1              # show interface speed (default: 0)
set -g @monochrome-night-tmux_show_ip 1                    # show IPv4 address (default: 0)
set -g @monochrome-night-tmux_network_iface_mode default   # default | specified | tun_or_default | tun_only
set -g @monochrome-night-tmux_network_iface eth0           # only used if mode = specified
set -g @monochrome-night-tmux_netspeed_refresh 1           # sampling window in seconds (default: 1)
```

Modes:

- `default`: the interface with the default route
- `specified`: the interface set in `@monochrome-night-tmux_network_iface`
- `tun_or_default`: `tun0` (VPN) if it's up, otherwise the default route interface
- `tun_only`: `tun0` if it's up, otherwise the widget is hidden

#### Path

```bash
set -g @monochrome-night-tmux_show_path 1
set -g @monochrome-night-tmux_path_format relative   # relative | full (default: relative)
```

#### Battery

```bash
set -g @monochrome-night-tmux_show_battery_widget 1
set -g @monochrome-night-tmux_battery_name "BAT1"           # default: BAT1 (Linux), InternalBattery-0 (macOS)
set -g @monochrome-night-tmux_battery_low_threshold 21      # default: 21
```

#### Music

```bash
set -g @monochrome-night-tmux_show_music 1
```

## psmux (Windows)

There's also a PowerShell port for [psmux](https://github.com/psmux/psmux). ppm loads `monochrome-night-tmux.ps1`, and tpm keeps using `monochrome-night.tmux`. The port's helpers live in `psmux/`, and the bash files are untouched.

ppm only runs `<plugin-dir-name>.ps1` (or `plugin.conf`, `plugin.ps1`, `init.ps1`), so the entry point has to stay named `monochrome-night-tmux.ps1`. If it's named anything else, ppm skips it silently.

Requirements: a Nerd Font and PowerShell 7 (`pwsh`). No bash needed.

```bash
set -g @plugin 'hnielsen123/monochrome-night-tmux'
# ...options...
run '~/.psmux/plugins/ppm/ppm.ps1'
```

### Supported

Same option names as tmux:

- `_theme`, `_transparent`
- `_window_id_style`, `_terminal_icon`, `_active_terminal_icon`, `_window_tidy_icons`
- `_show_datetime`, `_date_format`, `_time_format`
- `_show_netspeed`, `_show_ip`, `_network_iface_mode`, `_network_iface`

### Differences

- Window numbers 10 and up show as plain numbers rather than per-digit glyphs.
- `tun_only` / `tun_or_default`: Windows has no `tun0`. These modes match a VPN adapter by name or description against a regex. Override the regex if your VPN isn't detected. Check with `Get-NetAdapter | ft Name, InterfaceDescription, Status`.
  ```bash
  set -g @monochrome-night-tmux_vpn_iface_match 'PANGP|Wintun'   # psmux only
  ```
  The default regex is `TAP-Windows|Wintun|WireGuard|OpenVPN|PANGP|AnyConnect|Fortinet|VPN`.
- `_network_iface` takes the Windows adapter name, e.g. `Wi-Fi` or `Ethernet 3`. The widget also shows the adapter name instead of `tun0`.
- `_netspeed_refresh` is ignored. The network widget updates on psmux's `status-interval` hook, and netspeed is the delta since the previous poll.

### Not ported

- Widgets: git, web git, music, path, battery. Git and web git are on by default under tmux, so they're the visible difference.

[Nerd Fonts]: https://www.nerdfonts.com/
[Noto Sans]: https://fonts.google.com/noto/specimen/Noto+Sans+Symbols+2
[bc]: https://www.gnu.org/software/bc/
[jq]: https://jqlang.github.io/jq/
[gh]: https://cli.github.com/
[glab]: https://gitlab.com/gitlab-org/cli
[playerctl]: https://github.com/altdesktop/playerctl
[nowplaying-cli]: https://github.com/kirtan-shah/nowplaying-cli
[Homebrew]: https://brew.sh/
