sketchybar -m --set $NAME label=$(ps -A -o %cpu | awk '{s+=$1} END {printf "%.0f%%\n", s}')
