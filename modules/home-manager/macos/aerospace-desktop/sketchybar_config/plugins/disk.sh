sketchybar -m --set $NAME label=$(df -lh / | awk 'NR==2 {print $5}')
