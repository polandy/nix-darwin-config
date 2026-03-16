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
  9[0-9]|100) ICON=􀛨
  ;;
  8[0-9]) ICON=􀺸
  ;;
  7[0-9]) ICON=􀺸
  ;;
  6[0-9]) ICON=􀺶
  ;;
  5[0-9]) ICON=􀺶
  ;;
  4[0-9]) ICON=􀺶
  ;;
  3[0-9]) ICON=􀺴
  ;;
  2[0-9]) ICON=􀛩; COLOR=$RED
  ;;
  1[0-9]) ICON=􀛩; COLOR=$RED
  ;;
  *) ICON=􀛪; COLOR=$RED
esac

if [[ $CHARGING != "" ]]; then
  ICON=􀢋
fi

sketchybar --set $NAME icon="$ICON" icon.color=$COLOR label="${PERCENTAGE}%"
