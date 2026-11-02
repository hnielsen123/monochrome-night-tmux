#!/usr/bin/env pwsh
# Network/IP widget for psmux (replaces src/netspeed.sh + lib/netspeed.sh).
# Runs on psmux's status-interval hook and publishes its output to
# @monochrome-night-tmux_network, which status-right references.

$ErrorActionPreference = 'SilentlyContinue'
. (Join-Path $PSScriptRoot 'common.ps1')

$o     = Get-MntOptions
$t     = Get-MntPalette $o
$RESET = Get-MntReset $t
$fg    = $t.foreground

function Publish([string]$Text) { Invoke-Mux set -g '@monochrome-night-tmux_network' $Text }

$showSpeed = $o['show_netspeed'] -eq '1'
$showIp    = $o['show_ip'] -eq '1'
if (-not ($showSpeed -or $showIp)) { Publish ''; exit }

$mode = if ($o['network_iface_mode']) { $o['network_iface_mode'] } else { 'default' }
# Windows has no tun0; "tun" modes match VPN adapters by name/description instead.
$vpnPattern = if ($o['vpn_iface_match']) { $o['vpn_iface_match'] } else { 'TAP-Windows|Wintun|WireGuard|OpenVPN|PANGP|AnyConnect|Fortinet|VPN' }

$up = @(Get-NetAdapter | Where-Object Status -eq 'Up')

function Test-Vpn($a) { ($a.Name -match $vpnPattern) -or ($a.InterfaceDescription -match $vpnPattern) }
function Get-VpnAdapter { $up | Where-Object { Test-Vpn $_ } | Select-Object -First 1 }
function Get-DefaultAdapter {
    $route = Get-NetRoute -DestinationPrefix '0.0.0.0/0' |
        Sort-Object { $_.RouteMetric + $_.InterfaceMetric } | Select-Object -First 1
    if ($route) { $up | Where-Object ifIndex -eq $route.ifIndex | Select-Object -First 1 }
}

$adapter = switch ($mode) {
    'specified'      { Get-NetAdapter -Name $o['network_iface'] }
    'tun_only'       { Get-VpnAdapter }
    'tun_or_default' { $v = Get-VpnAdapter; if ($v) { $v } else { Get-DefaultAdapter } }
    default          { Get-DefaultAdapter }
}
if (-not $adapter) { Publish ''; exit }

$type = if (Test-Vpn $adapter) { 'vpn' }
        elseif ($adapter.PhysicalMediaType -match '802\.11') { 'wifi' }
        else { 'wired' }

$ip = Get-NetIPAddress -InterfaceIndex $adapter.ifIndex -AddressFamily IPv4 |
    Where-Object { $_.IPAddress -notlike '169.254.*' } |
    Select-Object -First 1 -ExpandProperty IPAddress
$isUp = $ip -and $adapter.Status -eq 'Up'

function Format-Rate([double]$BytesPerSec) {
    if ($BytesPerSec -lt 1MB) { '{0:F1}KB/s' -f ($BytesPerSec / 1KB) } else { '{0:F1}MB/s' -f ($BytesPerSec / 1MB) }
}

$out = "$RESET$(Glyph 0x2591) "

if ($showSpeed) {
    # The bash version sleeps between two samples; here we diff against the
    # previous poll instead, so the hook returns immediately.
    $stats = Get-NetAdapterStatistics -Name $adapter.Name
    if ($stats) {
        $stateFile = Join-Path $env:TEMP 'monochrome-night-tmux-netspeed.json'
        $now = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()
        $rx = 0.0; $tx = 0.0
        $prev = if (Test-Path $stateFile) { Get-Content $stateFile -Raw | ConvertFrom-Json }
        if ($prev -and $prev.iface -eq $adapter.Name) {
            $elapsed = ($now - $prev.ts) / 1000.0
            if ($elapsed -gt 0 -and $elapsed -lt 120) {
                $rx = [math]::Max(0, ($stats.ReceivedBytes - $prev.rx) / $elapsed)
                $tx = [math]::Max(0, ($stats.SentBytes - $prev.tx) / $elapsed)
            }
        }
        @{ iface = $adapter.Name; ts = $now; rx = [double]$stats.ReceivedBytes; tx = [double]$stats.SentBytes } |
            ConvertTo-Json -Compress | Set-Content $stateFile
        $out += "#[fg=$($t.bgreen)]$(Glyph 0xF06F4) #[fg=$fg]$(Format-Rate $rx) #[fg=$($t.bblue)]$(Glyph 0xF06F6) #[fg=$fg]$(Format-Rate $tx) "
    }
}

$icons = @{ wifi = @(0xF05A9, 0xF05AA); wired = @(0xF0318, 0xF0319); vpn = @(0xF0582, 0xF0582) }
$iconCp    = $icons[$type][$(if ($isUp) { 0 } else { 1 })]
$iconColor = if ($isUp) { $fg } else { $t.red }
$out += "#[fg=$iconColor]$(Glyph $iconCp) #[dim]$($adapter.Name) "
if ($showIp -and $ip) { $out += "#[fg=$fg]$(Glyph 0xF0A5F) #[dim]$ip " }

Publish $out
