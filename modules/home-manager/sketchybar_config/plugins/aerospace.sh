#!/usr/bin/env bash

# Sourcing colors and icons to use them in the script
source "$CONFIG_DIR/colors.sh"
source "$CONFIG_DIR/icons.sh"
source "$CONFIG_DIR/plugins/icon_map.sh"

# Query the apps open on this specific workspace
APPS=$(aerospace list-windows --workspace "$1" --format "%{app-name}")

ICON_STR=""
if [ -n "$APPS" ]; then
  # Remove duplicates and map to icons
  while read -r app; do
    __icon_map "$app"
    ICON_STR+="$icon_result "
  done <<< "$(echo "$APPS" | sort -u)"
fi

# Ensure there's a space if ICON_STR is empty for visual consistency
if [ -z "$ICON_STR" ]; then
  ICON_STR=" "
fi

# Determine display style based on focus
if [ "$1" = "$FOCUSED_WORKSPACE" ]; then
    sketchybar --set "$NAME" background.drawing=on \
                            background.color="$WHITE" \
                            label.color="$BLACK" \
                            icon.color="$BLACK" \
                            label="$ICON_STR"
else
    sketchybar --set "$NAME" background.drawing=off \
                            label.color="$GREY" \
                            icon.color="$GREY" \
                            label="$ICON_STR"
fi
