#!/usr/bin/env bash

# AeroSpace PATH
USER_NAME=$(id -un)
export PATH="/run/current-system/sw/bin:/etc/profiles/per-user/$USER_NAME/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"

# Sourcing colors and icons
source "$CONFIG_DIR/colors.sh"
source "$CONFIG_DIR/icons.sh"
source "$CONFIG_DIR/plugins/icon_map.sh"

# Determine IDs
CURRENT_SID=$(echo "$1" | tr -d '[:space:]')
FOCUSED_WS=$(echo "$FOCUSED_WORKSPACE" | tr -d '[:space:]')
if [ -z "$FOCUSED_WS" ]; then
    FOCUSED_WS=$(aerospace list-workspaces --focused | tr -d '[:space:]')
fi

# Query apps
APPS=$(aerospace list-windows --workspace "$CURRENT_SID" --format "%{app-name}")
ICON_STR=""
if [ -n "$APPS" ]; then
  while read -r app; do
    __icon_map "$app"
    ICON_STR+="$icon_result "
  done <<< "$(echo "$APPS" | sort -u)"
fi

WHITE_CLEAN=${WHITE#0x??}

if [ "$CURRENT_SID" = "$FOCUSED_WS" ]; then
    # Focused: Pure white pill, black text for maximum contrast
    sketchybar --set "$NAME" background.drawing=on \
                            background.color=0xffffffff \
                            background.border_width=0 \
                            background.padding_left=4 \
                            background.padding_right=4 \
                            label.color="$BLACK" \
                            icon.color="$BLACK" \
                            label="$ICON_STR"
else
    # Unfocused
    if [ -n "$ICON_STR" ]; then
        # Grouped: Very subtle background, no border, tighter padding
        sketchybar --set "$NAME" background.drawing=on \
                                background.color="0x20$WHITE_CLEAN" \
                                background.border_width=0 \
                                background.padding_left=2 \
                                background.padding_right=2 \
                                label.color="$GREY" \
                                icon.color="$GREY" \
                                label="$ICON_STR"
    else
        # Empty: Transparent
        sketchybar --set "$NAME" background.drawing=off \
                                background.padding_left=2 \
                                background.padding_right=2 \
                                label.color="$GREY" \
                                icon.color="$GREY" \
                                label=""
    fi
fi
