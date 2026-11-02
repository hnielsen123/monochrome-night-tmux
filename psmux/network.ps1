# Shared helpers for the psmux (Windows) port of monochrome-night-tmux.
# Dot-sourced by ../monochrome-night-tmux.ps1 and ./network.ps1.
# Kept pure ASCII on purpose: every glyph is built from its codepoint, so file
# encoding (BOM / no BOM, PS 5.1 vs 7) can never mangle the icons.

function Get-PsmuxBin {
    foreach ($n in @('psmux', 'pmux', 'tmux')) {
        $b = Get-Command $n -ErrorAction SilentlyContinue
        if ($b) { return $b.Source }
    }
    return 'psmux'
}

$PSMUX = Get-PsmuxBin

function Invoke-Mux { & $PSMUX @args 2>&1 | Out-Null }

function Glyph([int]$Codepoint) { [char]::ConvertFromUtf32($Codepoint) }

# One show-options call, parsed into a hashtable of this theme's options
# (keys without the '@monochrome-night-tmux_' prefix).
function Get-MntOptions {
    $opts = @{}
    foreach ($line in (& $PSMUX show-options -g 2>&1)) {
        if ("$line" -match '^\s*@monochrome-night-tmux_(\S+)\s+[''"]?(.*?)[''"]?\s*$') {
            $opts[$Matches[1]] = $Matches[2]
        }
    }
    return $opts
}

function Get-MntPalette([hashtable]$Opts) {
    $palettes = @{
        monochrome = @{ background = '#1c1c1c'; foreground = '#f2f2f2'; black = '#4e4e4e'; blue = '#87afff'; white = '#afd7ff'; yellow = '#d7af5f'; red = '#ff8787'; bblack = '#303030'; bblue = '#87afff'; bgreen = '#5fafaf' }
        storm      = @{ background = '#24283b'; foreground = '#a9b1d6'; black = '#414868'; blue = '#7aa2f7'; white = '#a9b1d6'; yellow = '#e0af68'; red = '#f7768e'; bblack = '#414868'; bblue = '#7aa2f7'; bgreen = '#41a6b5' }
        day        = @{ background = '#d5d6db'; foreground = '#343b58'; black = '#0f0f14'; blue = '#34548a'; white = '#343b58'; yellow = '#8f5e15'; red = '#8c4351'; bblack = '#9699a3'; bblue = '#34548a'; bgreen = '#33635c' }
        night      = @{ background = '#1A1B26'; foreground = '#a9b1d6'; black = '#414868'; blue = '#7aa2f7'; white = '#c0caf5'; yellow = '#e0af68'; red = '#f7768e'; bblack = '#2A2F41'; bblue = '#7aa2f7'; bgreen = '#41a6b5' }
    }
    $name = if ($Opts['theme'] -and $palettes.ContainsKey($Opts['theme'])) { $Opts['theme'] } else { 'monochrome' }
    $p = $palettes[$name].Clone()
    if ($Opts['transparent'] -eq '1') { $p.background = 'default' }
    return $p
}

function Get-MntReset([hashtable]$T) {
    "#[fg=$($T.foreground),bg=$($T.background),nobold,noitalics,nounderscore,nodim]"
}
