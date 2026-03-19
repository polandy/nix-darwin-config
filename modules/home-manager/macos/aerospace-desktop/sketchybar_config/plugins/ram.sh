#!/bin/bash
source "$CONFIG_DIR/colors.sh"

RAM=$(memory_pressure | grep "System-wide memory free percentage:" | awk '{ printf("%.0f", 100-$5) }')

if [ "$RAM" -gt 90 ]; then   COLOR=$RED
elif [ "$RAM" -gt 70 ]; then COLOR=$YELLOW
else                         COLOR=$WHITE
fi

sketchybar --set $NAME label="${RAM}%" label.color=$COLOR
