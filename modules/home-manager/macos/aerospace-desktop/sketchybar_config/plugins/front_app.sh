#!/bin/sh

if [ "$SENDER" = "front_app_switched" ]; then
  sketchybar --set "$NAME" label="$INFO"
else
  sketchybar --set "$NAME" label="$(osascript -e 'tell application "System Events" to get name of first application process whose frontmost is true')"
fi

FOCUSED_WS=$(aerospace list-workspaces --focused 2>/dev/null)
sketchybar --trigger aerospace_workspace_change FOCUSED_WORKSPACE="$FOCUSED_WS"
