#!/bin/bash

# AeroSpace monitor ids are left-to-right; sketchybar display numbers are NSScreen
# arrangement ids (main first), so join them by left-to-right rank of the frames.
USER_NAME=$(id -un)
export PATH="/run/current-system/sw/bin:/etc/profiles/per-user/$USER_NAME/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"

# A DisplayLink re-dock fires several display_change events: run one instance, re-run if more arrived.
LOCKDIR="${TMPDIR:-/tmp}/sketchybar_workspace_display.lock"
RERUN_FLAG="$LOCKDIR/rerun"
if ! mkdir "$LOCKDIR" 2>/dev/null; then
    # Steal a stale lock left by a killed run.
    if find "$LOCKDIR" -maxdepth 0 -mmin +2 2>/dev/null | grep -q .; then
        rm -rf "$LOCKDIR"
        mkdir "$LOCKDIR" 2>/dev/null || exit 0
    else
        touch "$RERUN_FLAG" 2>/dev/null
        exit 0
    fi
fi
trap 'rm -rf "$LOCKDIR"' EXIT

while :; do
    rm -f "$RERUN_FLAG"
    arr_ids=$(sketchybar --query displays | /usr/bin/jq -r 'sort_by(.frame.x, .frame.y) | .[]."arrangement-id"')
    for m in $(aerospace list-monitors --format '%{monitor-id}' 2>/dev/null); do
        d=$(printf '%s\n' "$arr_ids" | sed -n "${m}p")
        [ -n "$d" ] || d=1
        for ws in $(aerospace list-workspaces --monitor "$m" 2>/dev/null); do
            # Workspaces without a bar item are ignored.
            sketchybar --set "space.$ws" display="$d" 2>/dev/null
        done
    done
    [ -e "$RERUN_FLAG" ] && continue
    break
done
