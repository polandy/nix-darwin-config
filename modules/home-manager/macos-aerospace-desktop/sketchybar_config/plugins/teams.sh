#!/bin/bash
source "$CONFIG_DIR/colors.sh"

# Hide if Teams is not running
if ! pgrep -q "Teams"; then
  sketchybar --set teams drawing=off
  exit 0
fi

# Read the Dock badge for Teams (unread count)
BADGE=$(osascript -e '
  tell application "System Events"
    tell process "Dock"
      try
        repeat with dockItem in UI elements of list 1
          if name of dockItem contains "Microsoft Teams" then
            return value of attribute "AXStatusLabel" of dockItem
          end if
        end repeat
      end try
    end tell
  end tell
' 2>/dev/null)

[ "$BADGE" = "missing value" ] && BADGE=""

if [ -n "$BADGE" ]; then
  sketchybar --set teams drawing=on \
                       icon.color=$RED \
                       label.drawing=on \
                       label="$BADGE"
else
  sketchybar --set teams drawing=off \
                       label.drawing=off
fi
