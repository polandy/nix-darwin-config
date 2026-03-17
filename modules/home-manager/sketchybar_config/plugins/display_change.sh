#!/usr/bin/env bash

# Wait for AeroSpace to finish reassigning workspaces, then update each
# workspace item's display property without a full bar reload.
USER_NAME=$(id -un)
export PATH="/run/current-system/sw/bin:/etc/profiles/per-user/$USER_NAME/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"

sleep 2

_num_monitors=$(aerospace list-monitors --format "%{monitor-id}" 2>/dev/null | wc -l | tr -d ' ')
for _monitor in $(aerospace list-monitors --format "%{monitor-id}" 2>/dev/null); do
    _display=$(( _num_monitors + 1 - _monitor ))
    for _ws in $(aerospace list-workspaces --monitor "$_monitor" 2>/dev/null); do
        sketchybar --set "space.$_ws" display="$_display"
    done
done
