#!/usr/bin/env pwsh
# monochrome-night-tmux: psmux (Windows) entry point.
# tpm (Linux/macOS) loads monochrome-night.tmux; ppm (psmux) loads this file,
# because it looks for <plugin-dir-name>.ps1. The bash side is untouched.

$ErrorActionPreference = 'Continue'
. (Join-Path $PSScriptRoot 'psmux/common.ps1')

$o     = Get-MntOptions
$t     = Get-MntPalette $o
$RESET = Get-MntReset $t
$fg    = $t.foreground

Invoke-Mux set -g status-left-length 80
Invoke-Mux set -g status-right-length 150
Invoke-Mux set -g mode-style "fg=$($t.bgreen),bg=$($t.bblack)"
Invoke-Mux set -g message-style "bg=$($t.blue),fg=$($t.background)"
Invoke-Mux set -g message-command-style "fg=$($t.white),bg=$($t.black)"
Invoke-Mux set -g pane-border-style "fg=$($t.bblack)"
Invoke-Mux set -g pane-active-border-style "fg=$($t.blue)"
Invoke-Mux set -g pane-border-status off
Invoke-Mux set -g status-style "bg=$($t.background)"

# --- Number styles (replaces src/custom-number.sh) ---------------------------
# Built as a nested format conditional so no script runs per window.
$numberStyles = @{
    none    = 0x30..0x39
    digital = 0x1FBF0..0x1FBF9
    fsquare = @(0xF03A1, 0xF03A4, 0xF03A7, 0xF03AA, 0xF03AD, 0xF03B1, 0xF03B3, 0xF03B6, 0xF03B9, 0xF03BC)
    hsquare = @(0xF03A3, 0xF03A6, 0xF03A9, 0xF03AC, 0xF03AE, 0xF03B0, 0xF03B5, 0xF03B8, 0xF03BB, 0xF03BE)
    dsquare = @(0xF03A2, 0xF03A5, 0xF03A8, 0xF03AB, 0xF03B2, 0xF03AF, 0xF03B4, 0xF03B7, 0xF03BA, 0xF03BD)
    roman   = @(0x20, 0xF1088, 0xF1089, 0xF108A, 0xF108B, 0xF108C, 0xF108D, 0xF108E, 0xF108F, 0xF1090)
    super   = @(0x2070, 0xB9, 0xB2, 0xB3, 0x2074, 0x2075, 0x2076, 0x2077, 0x2078, 0x2079)
    sub     = 0x2080..0x2089
}

function New-NumberFormat([string]$Var, [string]$Style) {
    if ($Style -eq 'hide') { return '' }
    $cps = $numberStyles[$Style]
    if (-not $cps) { $cps = $numberStyles['none'] }
    $fmt = "#{$Var} "   # 10+ falls back to the plain number
    for ($i = 9; $i -ge 0; $i--) {
        $fmt = "#{?#{==:#{$Var},$i},$(Glyph ($cps[$i])) ,$fmt}"
    }
    return $fmt
}

$windowIdStyle = if ($o['window_id_style']) { $o['window_id_style'] } else { 'fsquare' }
$winNum = New-NumberFormat 'window_index' $windowIdStyle

# --- Window list -------------------------------------------------------------
$termIcon   = if ($o['terminal_icon'])        { $o['terminal_icon'] }        else { Glyph 0xF489 }
$activeIcon = if ($o['active_terminal_icon']) { $o['active_terminal_icon'] } else { Glyph 0xE795 }
# Matches the bash version's actual behaviour: extra space only when explicitly 0.
$space      = if ($o['window_tidy_icons'] -eq '0') { ' ' } else { '' }
$ssh        = Glyph 0xF08C0

function New-IconFormat([string]$Default) {
    # On Windows the command may report as ssh or ssh.exe.
    "#{?#{==:#{pane_current_command},ssh},$ssh ,#{?#{==:#{pane_current_command},ssh.exe},$ssh ,$Default $space}}"
}

Invoke-Mux set -g window-status-current-format "$RESET#[fg=$fg,bg=$($t.bblack)] $(New-IconFormat $activeIcon)#[fg=$fg,bold,nodim]$winNum#W#[nobold]#{?window_last_flag, , }"
Invoke-Mux set -g window-status-format "$RESET#[fg=$fg] $(New-IconFormat $termIcon)$RESET$winNum#W#[nobold,dim]#[fg=$($t.yellow)]#{?window_last_flag, , }"
Invoke-Mux set -g window-status-separator ''

# --- Left: prefix indicator + hostname ---------------------------------------
$hostName = [System.Net.Dns]::GetHostName()
Invoke-Mux set -g status-left "#[fg=$fg,bg=$($t.black)] #{?client_prefix,$(Glyph 0xF0820) ,#[dim]$(Glyph 0xF0902) }#[nodim]$hostName "

# --- Right: network/IP (polled) + date/time ----------------------------------
$dateTime = ''
if ($o['show_datetime'] -ne '0') {
    $d = switch ($o['date_format']) {
        'YMD'   { ' %Y-%m-%d' }
        'DMY'   { ' %d-%m-%Y' }
        'hide'  { '' }
        default { ' %m-%d-%Y' }
    }
    $tm = switch ($o['time_format']) {
        '24H'   { '%H:%M ' }
        'hide'  { '' }
        default { '%I:%M %p ' }
    }
    $sep = if ($d -and $tm) { "$(Glyph 0x276C) " } else { '' }
    $dateTime = "$RESET#[fg=$fg,bg=$($t.bblack)]$d $sep$tm"
}

Invoke-Mux set -g '@monochrome-night-tmux_network' ''
Invoke-Mux set -g status-right "#{@monochrome-night-tmux_network}$dateTime"

if ($o['show_ip'] -eq '1' -or $o['show_netspeed'] -eq '1') {
    $netScript = (Join-Path $PSScriptRoot 'psmux/network.ps1') -replace '\\', '/'
    $pollCmd   = "pwsh -NoProfile -NonInteractive -File `"$netScript`""
    # Don't stack duplicate hooks every time the config is re-sourced.
    $hooks = (& $PSMUX show-hooks -g 2>&1 | Out-String)
    if ($hooks -notmatch [regex]::Escape($netScript)) {
        Invoke-Mux set-hook -ga client-attached "run-shell '$pollCmd'"
        Invoke-Mux set-hook -ga status-interval "run-shell '$pollCmd'"
    }
    & pwsh -NoProfile -NonInteractive -File $netScript 2>&1 | Out-Null
}

Write-Host "monochrome-night-tmux: loaded ($windowIdStyle)" -ForegroundColor DarkGray
