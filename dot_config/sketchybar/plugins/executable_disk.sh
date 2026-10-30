#!/bin/zsh

source "$HOME/.config/sketchybar/colors.sh"

if [ "$SENDER" = "mouse.exited" ]; then
  sketchybar --set "$NAME" popup.drawing=off
  exit 0
fi

DISK_LINE=$(df -H /System/Volumes/Data 2>/dev/null | awk 'NR==2')
[ -z "$DISK_LINE" ] && DISK_LINE=$(df -H / 2>/dev/null | awk 'NR==2')

DISK_USED=$(echo "$DISK_LINE" | awk '{print $5}')
DISK_DETAIL=$(echo "$DISK_LINE" | awk '{printf "/: %s used of %s (%s free)", $3, $2, $4}')

sketchybar --set "$NAME" label="$DISK_USED" \
  --set "${NAME}.tooltip" label="$DISK_DETAIL"

if [ "$SENDER" = "mouse.entered" ]; then
  sketchybar --set "$NAME" popup.drawing=on
fi
