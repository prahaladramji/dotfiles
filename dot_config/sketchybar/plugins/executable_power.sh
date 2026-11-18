#!/bin/zsh

source "$HOME/.config/sketchybar/colors.sh"

ACTION="$1"

if [ -z "$ACTION" ] && [ "$SENDER" = "mouse.exited" ]; then
  sketchybar --set power popup.drawing=off
  exit 0
fi

case "$ACTION" in
  toggle)
    hover_cancel power
    sketchybar --set power popup.drawing=toggle
    ;;
  lock)
    sketchybar --set power popup.drawing=off
    pmset displaysleepnow
    ;;
  sleep)
    sketchybar --set power popup.drawing=off
    pmset sleepnow
    ;;
  reboot)
    sketchybar --set power popup.drawing=off
    osascript -e 'tell app "loginwindow" to «event aevtrrst»'
    ;;
  shutdown)
    sketchybar --set power popup.drawing=off
    osascript -e 'tell app "loginwindow" to «event aevtrsdn»'
    ;;
esac
