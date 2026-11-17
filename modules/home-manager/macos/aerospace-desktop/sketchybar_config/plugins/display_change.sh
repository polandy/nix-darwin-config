#!/usr/bin/env bash

# Let macOS and AeroSpace settle after a display change.
sleep 2
CONFIG_DIR="${CONFIG_DIR:-$HOME/.config/sketchybar}"
exec "$CONFIG_DIR/plugins/workspace_display.sh"
