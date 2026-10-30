#!/bin/zsh

source "$HOME/.config/sketchybar/colors.sh"

if [ "$SENDER" = "mouse.exited" ]; then
  sketchybar --set "$NAME" popup.drawing=off
  exit 0
fi

BATT_INFO=$(pmset -g batt 2>/dev/null)
PERCENTAGE=$(echo "$BATT_INFO" | grep -Eo "\d+%" | cut -d% -f1)

if [ -z "$PERCENTAGE" ]; then
  sketchybar --set "$NAME" drawing=off
  exit 0
fi

CHARGING=$(echo "$BATT_INFO" | grep 'AC Power')

if [ -n "$CHARGING" ]; then
  if [ "$PERCENTAGE" -ge 98 ]; then
    ICON="󰚥"
  else
    ICON="󰂄"
  fi
  COLOR="$BATTERY_CHARGING_COLOR"
else
  case "$PERCENTAGE" in
    9[0-9]|100) ICON="󰁹" ;;
    8[0-9])     ICON="󰂂" ;;
    7[0-9])     ICON="󰂁" ;;
    6[0-9])     ICON="󰂀" ;;
    5[0-9])     ICON="󰁿" ;;
    4[0-9])     ICON="󰁾" ;;
    3[0-9])     ICON="󰁽" ;;
    2[0-9])     ICON="󰁼" ;;
    1[0-9])     ICON="󰁻" ;;
    [5-9])      ICON="󰁺" ;;
    *)          ICON="󰂎" ;;
  esac

  if [ "$PERCENTAGE" -le 15 ]; then
    COLOR="$BATTERY_CRITICAL_COLOR"
  elif [ "$PERCENTAGE" -le 30 ]; then
    COLOR="$BATTERY_WARNING_COLOR"
  else
    COLOR="$BATTERY_COLOR"
  fi
fi

sketchybar --set "$NAME" \
  drawing=on \
  icon="$ICON" \
  icon.color="$COLOR" \
  label="${PERCENTAGE}%"

if [ "$SENDER" = "mouse.entered" ]; then
  STATUS_DETAIL=$(echo "$BATT_INFO" | awk -F'; ' 'NR==2 {print $2 " (" $3 ")"}')
  sketchybar --set "${NAME}.tooltip" label="${STATUS_DETAIL:-Battery: ${PERCENTAGE}%}" \
    --set "$NAME" popup.drawing=on
fi
