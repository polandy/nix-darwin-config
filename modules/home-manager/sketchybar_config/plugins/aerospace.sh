#!/usr/bin/env bash

# Sourcing colors to use them in the script
source "$CONFIG_DIR/colors.sh"

if [ "$1" = "$FOCUSED_WORKSPACE" ]; then
    sketchybar --set $NAME background.drawing=on \
                         background.color=$WHITE \
                         label.color=$BLACK \
                         icon.color=$BLACK
else
    sketchybar --set $NAME background.drawing=off \
                         label.color=$GREY \
                         icon.color=$GREY
fi
