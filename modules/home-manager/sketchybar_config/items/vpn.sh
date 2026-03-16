source "$CONFIG_DIR/icons.sh"

sketchybar --add item vpn right \
           --set vpn icon=$LOCK \
                     label.drawing=off \
                     drawing=off \
                     update_freq=10 \
                     script="$PLUGIN_DIR/vpn.sh"
