#!/usr/bin/env bash

# Wait for macOS and AeroSpace to settle after a display topology change, then
# re-map the workspace items onto the correct displays (shared helper).
sleep 2
CONFIG_DIR="${CONFIG_DIR:-$HOME/.config/sketchybar}"
exec "$CONFIG_DIR/plugins/workspace_display.sh"
