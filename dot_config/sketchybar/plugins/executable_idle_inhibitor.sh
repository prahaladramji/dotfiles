#!/bin/zsh

source "$HOME/.config/sketchybar/colors.sh"

ITEM="${NAME:-idle_inhibitor}"

# Handle direct CLI / click_script actions FIRST (before SENDER checks, since
# SketchyBar passes the item's last SENDER into click_script's environment).
if [ "$1" = "toggle" ]; then
  hover_cancel "$ITEM"
  if pgrep -x "caffeinate" >/dev/null 2>&1; then
    pkill -x "caffeinate"
  else
    nohup caffeinate -di >/dev/null 2>&1 &
  fi
elif [ -z "$1" ]; then
  if [ "$SENDER" = "mouse.exited" ]; then
    hover_exit "$ITEM"
    exit 0
  elif [ "$SENDER" = "mouse.entered" ]; then
    hover_enter "$ITEM"
    exit 0
  fi
fi

if pgrep -x "caffeinate" >/dev/null 2>&1; then
  sketchybar --set "$ITEM" \
    icon="󰈈" \
    icon.color="$IDLE_ACTIVE_COLOR" \
    --set "${ITEM}.tooltip" label="Idle inhibitor: Activated (caffeinate)"
else
  sketchybar --set "$ITEM" \
    icon="󰈉" \
    icon.color="$IDLE_COLOR" \
    --set "${ITEM}.tooltip" label="Idle inhibitor: Deactivated"
fi
