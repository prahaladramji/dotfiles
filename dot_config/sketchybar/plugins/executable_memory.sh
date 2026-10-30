#!/bin/zsh

source "$HOME/.config/sketchybar/colors.sh"

if [ "$SENDER" = "mouse.exited" ]; then
  sketchybar --set "$NAME" popup.drawing=off
  exit 0
fi

MEM_USED=$(memory_pressure 2>/dev/null | awk '/System-wide memory free percentage:/ {printf "%.0f", 100 - $5}')

if [ -n "$MEM_USED" ]; then
  sketchybar --set "$NAME" label="${MEM_USED}%"
fi

if [ "$SENDER" = "mouse.entered" ]; then
  TOTAL_BYTES=$(sysctl -n hw.memsize 2>/dev/null || echo 0)
  TOTAL_GB=$((TOTAL_BYTES / 1073741824))
  TOP_MEM=$(ps -Aceo rss,comm -m | awk 'NR==2 {printf "%s (%.0f MB)", $2, $1/1024}')
  sketchybar --set "${NAME}.tooltip" label="RAM: ${MEM_USED}% of ${TOTAL_GB}GB | Top: ${TOP_MEM}" \
    --set "$NAME" popup.drawing=on
fi
