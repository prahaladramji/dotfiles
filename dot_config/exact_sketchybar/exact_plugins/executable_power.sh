#!/bin/zsh

source "$HOME/.config/sketchybar/colors.sh"

ACTION="$1"
POWER_OPEN_FILE="$HOVER_DIR/_power_open"

if [ -z "$ACTION" ] && { [ "$SENDER" = "mouse.exited.global" ] || [ "$SENDER" = "mouse.exited" ]; }; then
  if [ -f "$POWER_OPEN_FILE" ]; then
    rm -f "$POWER_OPEN_FILE"
    sketchybar --set power popup.drawing=off
  fi
  exit 0
fi

case "$ACTION" in
  toggle)
    mkdir -p "$HOVER_DIR"
    prev_open=$(<"$HOVER_DIR/_open") 2>/dev/null || prev_open=""
    hover_cancel power
    if [ -f "$POWER_OPEN_FILE" ]; then
      rm -f "$POWER_OPEN_FILE"
      sketchybar --set power popup.drawing=off
    else
      : > "$POWER_OPEN_FILE"
      if [[ -n "$prev_open" && "$prev_open" != "power" ]]; then
        sketchybar --set "$prev_open" popup.drawing=off --set power popup.drawing=on
      else
        sketchybar --set power popup.drawing=on
      fi
    fi
    ;;
  lock)
    rm -f "$POWER_OPEN_FILE"
    sketchybar --set power popup.drawing=off
    pmset displaysleepnow
    ;;
  sleep)
    rm -f "$POWER_OPEN_FILE"
    sketchybar --set power popup.drawing=off
    pmset sleepnow
    ;;
  reboot)
    rm -f "$POWER_OPEN_FILE"
    sketchybar --set power popup.drawing=off
    osascript -e 'tell app "loginwindow" to «event aevtrrst»'
    ;;
  shutdown)
    rm -f "$POWER_OPEN_FILE"
    sketchybar --set power popup.drawing=off
    osascript -e 'tell app "loginwindow" to «event aevtrsdn»'
    ;;
esac
