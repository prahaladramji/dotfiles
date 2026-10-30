#!/bin/zsh

source "$HOME/.config/sketchybar/colors.sh"

if [ "$SENDER" = "mouse.exited" ]; then
  sketchybar --set "$NAME" popup.drawing=off
  exit 0
fi

if [ "$1" = "toggle" ]; then
  if pgrep -x "caffeinate" >/dev/null 2>&1; then
    pkill -x "caffeinate"
  else
    caffeinate -di >/dev/null 2>&1 &
  fi
fi

if pgrep -x "caffeinate" >/dev/null 2>&1; then
  sketchybar --set "$NAME" \
    icon="󰈈" \
    icon.color="$IDLE_ACTIVE_COLOR" \
    --set "${NAME}.tooltip" label="Idle inhibitor: Activated (caffeinate)"
else
  sketchybar --set "$NAME" \
    icon="󰈉" \
    icon.color="$IDLE_COLOR" \
    --set "${NAME}.tooltip" label="Idle inhibitor: Deactivated"
fi

if [ "$SENDER" = "mouse.entered" ]; then
  sketchybar --set "$NAME" popup.drawing=on
fi
