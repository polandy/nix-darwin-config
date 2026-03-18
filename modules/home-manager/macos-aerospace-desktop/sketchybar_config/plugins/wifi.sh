#!/usr/bin/env bash

WIFI_IF=$(networksetup -listallhardwareports | awk '/Wi-Fi|AirPort/{found=1} found && /Device:/{print $2; exit}')

if ipconfig getifaddr "$WIFI_IF" &>/dev/null; then
  ICON=󰤨
else
  ICON=󰤮
fi

sketchybar --set "$NAME" icon="$ICON"
