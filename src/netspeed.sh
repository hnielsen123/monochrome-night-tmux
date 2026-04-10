#!/usr/bin/env bash
#<------------------------------Network widget for TMUX------------------------------------>
# originally by @tribhuwan-kumar, modified for monochrome-night-tmux by hnielsen123
#<------------------------------------------------------------------------------------------>

# Check if enabled - either netspeed or IP (or both)
SHOW_NETSPEED=$(tmux show-option -gv @monochrome-night-tmux_show_netspeed 2>/dev/null)
SHOW_IP=$(tmux show-option -gv @monochrome-night-tmux_show_ip 2>/dev/null)
[[ ${SHOW_NETSPEED} -ne 1 ]] && [[ ${SHOW_IP} -ne 1 ]] && exit 0

# Imports
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/.."
source "$ROOT_DIR/src/themes.sh"
source "$ROOT_DIR/lib/netspeed.sh"

# Config
IFACE_MODE=$(tmux show-option -gv @monochrome-night-tmux_network_iface_mode 2>/dev/null)
IFACE_MODE=${IFACE_MODE:-default}
SPECIFIED_IFACE=$(tmux show-option -gv @monochrome-night-tmux_network_iface 2>/dev/null)
TIME_DIFF=$(tmux show-option -gv @monochrome-night-tmux_netspeed_refresh 2>/dev/null)
TIME_DIFF=${TIME_DIFF:-1}

# Icons
declare -A NET_ICONS
NET_ICONS[wifi_up]="#[fg=${THEME[foreground]}]\U000f05a9"   # nf-md-wifi
NET_ICONS[wifi_down]="#[fg=${THEME[red]}]\U000f05aa"        # nf-md-wifi_off
NET_ICONS[wired_up]="#[fg=${THEME[foreground]}]\U000f0318"  # nf-md-lan_connect
NET_ICONS[wired_down]="#[fg=${THEME[red]}]\U000f0319"       # nf-md-lan_disconnect
NET_ICONS[vpn_up]="#[fg=${THEME[foreground]}]\U000f0582"    # nf-md-vpn (verify codepoint)
NET_ICONS[vpn_down]="#[fg=${THEME[red]}]\U000f0582"
NET_ICONS[traffic_tx]="#[fg=${THEME[bblue]}]\U000f06f6"     # nf-md-upload_network
NET_ICONS[traffic_rx]="#[fg=${THEME[bgreen]}]\U000f06f4"    # nf-md-download_network
NET_ICONS[ip]="#[fg=${THEME[foreground]}]\U000f0a5f"        # nf-md-ip

# Helper: is tun0 present and up?
tun_is_up() {
  [[ -d /sys/class/net/tun0 ]] || return 1
  local state
  state=$(cat /sys/class/net/tun0/operstate 2>/dev/null)
  [[ $state != "down" ]]
}

# Pick interface based on mode
case "$IFACE_MODE" in
  default)
    INTERFACE=$(find_interface)
    ;;
  specified)
    INTERFACE="$SPECIFIED_IFACE"
    ;;
  tun_or_default)
    if tun_is_up; then
      INTERFACE="tun0"
    else
      INTERFACE=$(find_interface)
    fi
    ;;
  tun_only)
    if tun_is_up; then
      INTERFACE="tun0"
    else
      exit 0
    fi
    ;;
  *)
    INTERFACE=$(find_interface)
    ;;
esac

[[ -z $INTERFACE ]] && exit 0

# Measure netspeed only if we're going to show it
if [[ ${SHOW_NETSPEED} -eq 1 ]]; then
  read -r RX1 TX1 < <(get_bytes "$INTERFACE")
  sleep "$TIME_DIFF"
  read -r RX2 TX2 < <(get_bytes "$INTERFACE")

  RX_DIFF=$((RX2 - RX1))
  TX_DIFF=$((TX2 - TX1))

  RX_SPEED="#[fg=${THEME[foreground]}]$(readable_format "$RX_DIFF" "$TIME_DIFF")"
  TX_SPEED="#[fg=${THEME[foreground]}]$(readable_format "$TX_DIFF" "$TIME_DIFF")"
fi

# Interface type for icon selection
if [[ $INTERFACE == tun* ]]; then
  IFACE_TYPE="vpn"
elif [[ ${INTERFACE} == "en0" ]] || [[ -d /sys/class/net/${INTERFACE}/wireless ]]; then
  IFACE_TYPE="wifi"
else
  IFACE_TYPE="wired"
fi

# Detect IPv4 and up/down status (needed for both IP display and icon state)
if IPV4_ADDR=$(interface_ipv4 "$INTERFACE"); then
  IFACE_STATUS="up"
else
  IFACE_STATUS="down"
fi

NETWORK_ICON=${NET_ICONS[${IFACE_TYPE}_${IFACE_STATUS}]}

# Assemble output
OUTPUT="${RESET}░ "
if [[ ${SHOW_NETSPEED} -eq 1 ]]; then
  OUTPUT+="${NET_ICONS[traffic_rx]} $RX_SPEED ${NET_ICONS[traffic_tx]} $TX_SPEED "
fi
OUTPUT+="$NETWORK_ICON #[dim]$INTERFACE "
if [[ ${SHOW_IP} -eq 1 ]] && [[ -n $IPV4_ADDR ]]; then
  OUTPUT+="${NET_ICONS[ip]} #[dim]$IPV4_ADDR "
fi

echo -e "$OUTPUT"
