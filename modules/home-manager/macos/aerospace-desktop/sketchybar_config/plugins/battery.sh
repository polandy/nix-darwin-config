#!/bin/bash

source "$CONFIG_DIR/icons.sh"
source "$CONFIG_DIR/colors.sh"

PERCENTAGE=$(pmset -g batt | grep -Eo "\d+%" | cut -d% -f1)
CHARGING=$(pmset -g batt | grep 'AC Power')

if [ "$PERCENTAGE" = "" ]; then
  exit 0
fi

COLOR=$WHITE
case ${PERCENTAGE} in
  9[0-9]|100) ICON=$BATTERY_100
  ;;
  8[0-9]) ICON=$BATTERY_75
  ;;
  7[0-9]) ICON=$BATTERY_75
  ;;
  6[0-9]) ICON=$BATTERY_50
  ;;
  5[0-9]) ICON=$BATTERY_50
  ;;
  4[0-9]) ICON=$BATTERY_50
  ;;
  3[0-9]) ICON=$BATTERY_25; COLOR=$YELLOW
  ;;
  2[0-9]) ICON=$BATTERY_25; COLOR=$RED
  ;;
  1[0-9]) ICON=$BATTERY_0; COLOR=$RED
  ;;
  *) ICON=$BATTERY_0; COLOR=$RED
esac

if [[ $CHARGING != "" ]]; then
  ICON=$BATTERY_CHARGING
fi

sketchybar --set $NAME icon="$ICON" icon.color=$COLOR label="${PERCENTAGE}%" label.color=$COLOR
