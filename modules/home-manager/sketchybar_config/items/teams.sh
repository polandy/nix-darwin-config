source "$CONFIG_DIR/icons.sh"

sketchybar --add item teams right \
           --set teams icon=$APP_TEAMS \
                     icon.font="sketchybar-app-font:Regular:16.0" \
                     label.drawing=off \
                     drawing=off \
                     update_freq=15 \
                     script="$PLUGIN_DIR/teams.sh"
