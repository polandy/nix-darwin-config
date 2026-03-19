source "$CONFIG_DIR/icons.sh"

sketchybar -m --add item ram right \
              --set ram icon=$RAM \
                        label.font="Hack Nerd Font:Bold:13.0" \
                        label.width=40 \
                        label.align=center \
                        update_freq=1 \
                        script="$CONFIG_DIR/plugins/ram.sh"
