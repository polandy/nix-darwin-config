#!/usr/bin/env bash

USER_NAME=$(id -un)
export PATH="/run/current-system/sw/bin:/etc/profiles/per-user/$USER_NAME/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"

source "$CONFIG_DIR/colors.sh"
source "$CONFIG_DIR/icons.sh"
source "$CONFIG_DIR/plugins/icon_map.sh"

CURRENT_SID=$(echo "$1" | tr -d '[:space:]')
FOCUSED_WS=$(echo "$FOCUSED_WORKSPACE" | tr -d '[:space:]')
if [ -z "$FOCUSED_WS" ]; then
    FOCUSED_WS=$(aerospace list-workspaces --focused | tr -d '[:space:]')
fi

APPS=$(aerospace list-windows --workspace "$CURRENT_SID" --format "%{app-name}")
ICON_STR=""
if [ -n "$APPS" ]; then
  while read -r app; do
    __icon_map "$app"
    ICON_STR+="$icon_result "
  done <<< "$(echo "$APPS" | sort -u)"
fi

WHITE_CLEAN=${WHITE#0x??}

DEFAULT_ICON=""
DEFAULT_ICON_FONT="sketchybar-app-font:Regular:14.0"
if [ -z "$ICON_STR" ]; then
    default_app=""
    case "$CURRENT_SID" in
        1)  default_app="Messages" ;;
        2)  default_app="Mail" ;;
        4)  default_app="Firefox" ;;
        5)  DEFAULT_ICON="$APP_FILES"; DEFAULT_ICON_FONT="Hack Nerd Font:Regular:14.0" ;;
        6)  DEFAULT_ICON="$APP_CODE";   DEFAULT_ICON_FONT="Hack Nerd Font:Regular:14.0" ;;
        7)  DEFAULT_ICON="$APP_CAMERA"; DEFAULT_ICON_FONT="Hack Nerd Font:Regular:14.0" ;;
        8)  DEFAULT_ICON="$APP_FANCY";  DEFAULT_ICON_FONT="Hack Nerd Font:Regular:14.0" ;;
        9)  DEFAULT_ICON="$APP_STAR";   DEFAULT_ICON_FONT="Hack Nerd Font:Regular:14.0" ;;
        10) DEFAULT_ICON="$DISK";       DEFAULT_ICON_FONT="SF Pro:Regular:14.0" ;;
        11) default_app="Logseq" ;;
    esac
    if [ -n "$default_app" ]; then
        __icon_map "$default_app"
        DEFAULT_ICON="$icon_result"
    fi
fi

if [ "$CURRENT_SID" = "$FOCUSED_WS" ]; then
    if [ -n "$ICON_STR" ]; then
        sketchybar --set "$NAME" background.drawing=on \
                                background.color=0xffffffff \
                                background.border_width=0 \
                                background.padding_left=4 \
                                background.padding_right=4 \
                                label.font="sketchybar-app-font:Regular:14.0" \
                                label.color="$BLACK" \
                                label.padding_left=3 \
                                label.padding_right=3 \
                                icon.color="$BLACK" \
                                label="$ICON_STR"
    elif [ -n "$DEFAULT_ICON" ]; then
        sketchybar --set "$NAME" background.drawing=on \
                                background.color=0xffffffff \
                                background.border_width=0 \
                                background.padding_left=4 \
                                background.padding_right=4 \
                                label.font="$DEFAULT_ICON_FONT" \
                                label.color=0x50000000 \
                                label.padding_left=3 \
                                label.padding_right=3 \
                                icon.color="$BLACK" \
                                label="$DEFAULT_ICON"
    else
        sketchybar --set "$NAME" background.drawing=on \
                                background.color=0xffffffff \
                                background.border_width=0 \
                                background.padding_left=4 \
                                background.padding_right=4 \
                                label.font="sketchybar-app-font:Regular:14.0" \
                                label.color="$BLACK" \
                                label.padding_left=0 \
                                label.padding_right=0 \
                                icon.color="$BLACK" \
                                label=""
    fi
else
    if [ -n "$ICON_STR" ]; then
        sketchybar --set "$NAME" background.drawing=on \
                                background.color="0x20$WHITE_CLEAN" \
                                background.border_width=0 \
                                background.padding_left=2 \
                                background.padding_right=2 \
                                label.font="sketchybar-app-font:Regular:14.0" \
                                label.color="$GREY" \
                                icon.color="$GREY" \
                                label="$ICON_STR"
    elif [ -n "$DEFAULT_ICON" ]; then
        sketchybar --set "$NAME" background.drawing=off \
                                background.padding_left=2 \
                                background.padding_right=2 \
                                label.font="$DEFAULT_ICON_FONT" \
                                label.color=0x30ffffff \
                                icon.color="$GREY" \
                                label="$DEFAULT_ICON"
    else
        sketchybar --set "$NAME" background.drawing=off \
                                background.padding_left=2 \
                                background.padding_right=2 \
                                label.font="sketchybar-app-font:Regular:14.0" \
                                label.color="$GREY" \
                                icon.color="$GREY" \
                                label=""
    fi
fi
