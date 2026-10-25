#!/bin/bash

# Sync each sketchybar workspace item onto the physical display its AeroSpace
# workspace lives on. AeroSpace monitor ids are the left-to-right sequence;
# sketchybar display numbers are NSScreen arrangement ids (main display first),
# so the two are joined by left-to-right rank using the display frames.
# Idempotent; called from sketchybarrc at startup and from display_change.sh.
USER_NAME=$(id -un)
export PATH="/run/current-system/sw/bin:/etc/profiles/per-user/$USER_NAME/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"

# macOS fires several display_change events during a DisplayLink re-dock; run
# one instance and let it re-run if more events arrived while it was working.
LOCKDIR="${TMPDIR:-/tmp}/sketchybar_workspace_display.lock"
RERUN_FLAG="$LOCKDIR/rerun"
if ! mkdir "$LOCKDIR" 2>/dev/null; then
    # Steal the lock if a killed run left it behind (EXIT trap never fired).
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
    # Arrangement ids ordered left to right by frame origin.
    arr_ids=$(sketchybar --query displays | /usr/bin/jq -r 'sort_by(.frame.x, .frame.y) | .[]."arrangement-id"')
    for m in $(aerospace list-monitors --format '%{monitor-id}' 2>/dev/null); do
        d=$(printf '%s\n' "$arr_ids" | sed -n "${m}p")
        [ -n "$d" ] || d=1
        for ws in $(aerospace list-workspaces --monitor "$m" 2>/dev/null); do
            # Workspaces without a bar item (e.g. 12) are ignored.
            sketchybar --set "space.$ws" display="$d" 2>/dev/null
        done
    done
    [ -e "$RERUN_FLAG" ] && continue
    break
done
