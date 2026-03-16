#!/bin/sh

# Some events send additional information specific to the event in the $INFO
# variable. E.g. the front_app_switched event sends the name of the newly
# focused application in the $INFO variable:
# https://felixkratz.github.io/SketchyBar/config/events#events-and-scripting

if [ "$SENDER" = "front_app_switched" ]; then
  sketchybar --set "$NAME" label="$INFO"
else
  sketchybar --set "$NAME" label="$(osascript -e 'tell application "System Events" to get name of first application process whose frontmost is true')"
fi

# Refresh workspace pills so new/closed windows are reflected immediately
FOCUSED_WS=$(aerospace list-workspaces --focused 2>/dev/null)
sketchybar --trigger aerospace_workspace_change FOCUSED_WORKSPACE="$FOCUSED_WS"
