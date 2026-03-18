source "$CONFIG_DIR/icons.sh"

sketchybar -m --add item disk right \
              --set disk icon=$DISK \
                         label.font="Hack Nerd Font:Bold:13.0" \
                         label.width=40 \
                         label.align=center \
                         update_freq=30 \
                         script="$CONFIG_DIR/plugins/disk.sh"
