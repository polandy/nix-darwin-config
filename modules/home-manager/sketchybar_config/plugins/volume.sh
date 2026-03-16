#!/bin/bash

source "$CONFIG_DIR/icons.sh"

update_display() {
  local VOLUME=$1
  local ICON
  case $VOLUME in
    [6-9][0-9]|100) ICON=$VOLUME_100 ;;
    [3-5][0-9])     ICON=$VOLUME_66  ;;
    [1-2][0-9])     ICON=$VOLUME_33  ;;
    [1-9])          ICON=$VOLUME_10  ;;
    0)              ICON=$VOLUME_0   ;;
    *)              ICON=$VOLUME_100 ;;
  esac
  sketchybar --set volume icon="$ICON" label="$VOLUME%"
}

if [ "$SENDER" = "mouse.scrolled" ]; then
  CURRENT=$(osascript -e "output volume of (get volume settings)")
  # SCROLL_DELTA is negative when scrolling up (increase) on macOS
  if [ "$SCROLL_DELTA" -lt 0 ]; then
    NEW=$(( CURRENT + 5 ))
  else
    NEW=$(( CURRENT - 5 ))
  fi
  [ $NEW -gt 100 ] && NEW=100
  [ $NEW -lt 0 ]   && NEW=0
  osascript -e "set volume output volume $NEW"
elif [ "$SENDER" = "volume_change" ]; then
  update_display "$INFO"
fi
