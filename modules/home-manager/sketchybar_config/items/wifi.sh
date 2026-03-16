#!/usr/bin/env bash

sketchybar --add item wifi right \
           --set wifi script="$PLUGIN_DIR/wifi.sh" \
                         icon=󰤨 \
                         label.drawing=off \
                         click_script="open 'x-apple.systempreferences:com.apple.wifi-settings-extension'" \
                         update_freq=60 \
           --subscribe wifi system_woke
