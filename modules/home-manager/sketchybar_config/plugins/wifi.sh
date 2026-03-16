#!/usr/bin/env bash

SSID=$(ipconfig getsummary en0 | grep ' SSID : ' | awk -F': ' '{print $2}')

IS_CONNECTED=false
if [ -n "$SSID" ] && [ "$SSID" != "<redacted>" ] && [ "$SSID" != "You are not associated with an AirPort network." ]; then
  IS_CONNECTED=true
elif scutil --nwi | grep -A 3 "en0" | grep -q "Reachable"; then
  IS_CONNECTED=true
fi

if [ "$IS_CONNECTED" = true ]; then
  ICON=󰤨
else
  ICON=󰤮
fi

sketchybar --set "$NAME" icon="$ICON"
