#!/usr/bin/env bash

# Wait for AeroSpace to finish reassigning workspaces, then update each
# workspace item's display property without a full bar reload.
USER_NAME=$(id -un)
export PATH="/run/current-system/sw/bin:/etc/profiles/per-user/$USER_NAME/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"

sleep 2

_num_monitors=$(aerospace list-monitors --format "%{monitor-id}" 2>/dev/null | wc -l | tr -d ' ')
# LEN T25d-10 (DisplayLink) setup: AeroSpace and sketchybar number monitors the same way,
# so use direct mapping. For MacBook setups, invert (sketchybar primary != AeroSpace built-in).
_len_count=$(aerospace list-monitors --format "%{monitor-name}" 2>/dev/null | grep -c "LEN T25d-10" || true)
for _monitor in $(aerospace list-monitors --format "%{monitor-id}" 2>/dev/null); do
    if (( _len_count >= 2 )); then
        _display=$_monitor
    else
        _display=$(( _num_monitors + 1 - _monitor ))
    fi
    for _ws in $(aerospace list-workspaces --monitor "$_monitor" 2>/dev/null); do
        sketchybar --set "space.$_ws" display="$_display"
    done
done
