#!/bin/bash
source "$CONFIG_DIR/colors.sh"

SCUTIL_VPN=$(/usr/sbin/scutil --nc list 2>/dev/null | grep -c "Connected")
# iface must reset on every interface header, else en0's inet line (listed after utun0) is misattributed to utun0.
UTUN_VPN=$(/sbin/ifconfig 2>/dev/null | awk '/^[a-z]/{iface=$1; flags=$2} /inet [0-9]/ && iface ~ /^utun/ && flags ~ /UP/{found++} END{print found+0}')
# Tailscale's utun may persist when stopped, so ask the CLI.
TAILSCALE_VPN=0
if command -v tailscale &>/dev/null; then
  tailscale status &>/dev/null && TAILSCALE_VPN=1
fi

if [ "$SCUTIL_VPN" -gt 0 ] || [ "$UTUN_VPN" -gt 0 ] || [ "$TAILSCALE_VPN" -gt 0 ]; then
  sketchybar --set vpn drawing=on icon.color=$GREEN
else
  sketchybar --set vpn drawing=off
fi
