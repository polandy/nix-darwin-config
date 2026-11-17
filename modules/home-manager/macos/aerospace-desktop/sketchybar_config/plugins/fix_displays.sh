#!/bin/bash

# aerospace refuses move-workspace-to-monitor calls that contradict the force assignment,
# so re-enforce it via reload-config instead of moving workspaces.
USER_NAME=$(id -un)
export PATH="/run/current-system/sw/bin:/etc/profiles/per-user/$USER_NAME/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"

aerospace reload-config
exec "$HOME/.config/sketchybar/plugins/workspace_display.sh"
