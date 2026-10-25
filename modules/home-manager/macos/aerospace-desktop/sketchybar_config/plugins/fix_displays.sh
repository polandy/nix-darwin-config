#!/bin/bash

# Manual rescue hotkey (alt-shift-d): re-apply the positional
# workspace-to-monitor force assignment (reload-config re-runs it) and re-map
# the sketchybar workspace items onto the correct displays.
# Note: aerospace refuses move-workspace-to-monitor calls that contradict the
# force assignment, so "swapping" is done by re-enforcing the assignment, not
# by moving workspaces around it.
USER_NAME=$(id -un)
export PATH="/run/current-system/sw/bin:/etc/profiles/per-user/$USER_NAME/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"

aerospace reload-config
exec "$HOME/.config/sketchybar/plugins/workspace_display.sh"
