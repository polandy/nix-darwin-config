#!/bin/bash
source "$CONFIG_DIR/colors.sh"

# Normalize to 0-100% across all cores so thresholds are meaningful
CORES=$(sysctl -n hw.logicalcpu)
CPU=$(ps -A -o %cpu | awk -v cores="$CORES" '{s+=$1} END {printf "%.0f", s/cores}')

if [ "$CPU" -gt 90 ]; then   COLOR=$RED
elif [ "$CPU" -gt 70 ]; then COLOR=$YELLOW
else                         COLOR=$WHITE
fi

sketchybar --set $NAME label="${CPU}%" label.color=$COLOR
