source "$CONFIG_DIR/icons.sh"

sketchybar -m --add item cpu right \
              --set cpu icon=$CPU \
                        label.font="Hack Nerd Font:Bold:13.0" \
                        label.width=40 \
                        label.align=center \
                        update_freq=1 \
                        script="$CONFIG_DIR/plugins/cpu.sh"
