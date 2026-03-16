#!/bin/bash

# Matches Felix's calendar style: e.g., "Mon 16. Mar 14:00"
sketchybar --set $NAME label="$(date '+%a %d. %b %H:%M')"
