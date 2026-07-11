#!/bin/bash
source "$CONFIG_DIR/colors.sh"

# scutil catches macOS built-in VPNs; utun IPv4 check catches GlobalProtect and WireGuard
SCUTIL_VPN=$(/usr/sbin/scutil --nc list 2>/dev/null | grep -c "Connected")
# A utun with IPv4 + UP flag = active VPN tunnel (disconnected tunnels lose the UP flag).
# Reset iface on every interface header (/^[a-z]/), not just utun ones — otherwise a
# physical interface's inet line (e.g. en0, which ifconfig lists AFTER utun0) gets
# wrongly attributed to the preceding utun and triggers a false positive.
UTUN_VPN=$(/sbin/ifconfig 2>/dev/null | awk '/^[a-z]/{iface=$1; flags=$2} /inet [0-9]/ && iface ~ /^utun/ && flags ~ /UP/{found++} END{print found+0}')
# Tailscale: use CLI since its utun interface may persist when stopped
TAILSCALE_VPN=0
if command -v tailscale &>/dev/null; then
  tailscale status &>/dev/null && TAILSCALE_VPN=1
fi

if [ "$SCUTIL_VPN" -gt 0 ] || [ "$UTUN_VPN" -gt 0 ] || [ "$TAILSCALE_VPN" -gt 0 ]; then
  sketchybar --set vpn drawing=on icon.color=$GREEN
else
  sketchybar --set vpn drawing=off
fi
