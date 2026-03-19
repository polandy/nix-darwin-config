#!/usr/bin/env bash

UPDOWN=$(ifstat -i "en0" -b 0.1 1 | tail -n1)
DOWN=$(echo $UPDOWN | awk '{ print $1 }' | cut -f1 -d ".")
UP=$(echo $UPDOWN | awk '{ print $2 }' | cut -f1 -d ".")

format_speed() {
  local val=$1
  if [ "$val" -gt 999 ]; then
    awk "BEGIN { printf \"%.1fM\", $val / 1000 }"
  else
    echo "${val}K"
  fi
}

DOWN_FMT=$(format_speed $DOWN)
UP_FMT=$(format_speed $UP)

sketchybar --set network label="↓${DOWN_FMT}  ↑${UP_FMT}"
