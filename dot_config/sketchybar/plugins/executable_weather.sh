#!/bin/zsh

source "$HOME/.config/sketchybar/colors.sh"

if [ "$SENDER" = "mouse.exited" ]; then
  sketchybar --set "$NAME" popup.drawing=off
  exit 0
fi

if [ "$SENDER" = "mouse.entered" ]; then
  sketchybar --set "$NAME" popup.drawing=on
  exit 0
fi

CITY=$(curl -4 -sS --max-time 5 "http://ip-api.com/json" 2>/dev/null | /opt/homebrew/bin/jq -r '.city // empty' 2>/dev/null)
if [ -n "$CITY" ]; then
  CITY_ESCAPED="${CITY// /+}"
  SHORT_WEATHER=$(curl -4 -sS --max-time 10 "https://wttr.in/${CITY_ESCAPED}?format=%c%t" 2>/dev/null | sed 's/  */ /g')
  FULL_WEATHER=$(curl -4 -sS --max-time 10 "https://wttr.in/${CITY_ESCAPED}?format=%l:+%c%t+(%f)++%h++%w+uv:%u" 2>/dev/null)
else
  SHORT_WEATHER=$(curl -4 -sS --max-time 10 "https://wttr.in/?format=%c%t" 2>/dev/null | sed 's/  */ /g')
  FULL_WEATHER=$(curl -4 -sS --max-time 10 "https://wttr.in/?format=%l:+%c%t+(%f)++%h++%w+uv:%u" 2>/dev/null)
fi

if [ -n "$SHORT_WEATHER" ] && [[ "$SHORT_WEATHER" != *"Unknown"* ]]; then
  sketchybar --set "$NAME" drawing=on label="$SHORT_WEATHER" \
    --set "${NAME}.tooltip" label="${FULL_WEATHER:-$SHORT_WEATHER}"
else
  sketchybar --set "$NAME" drawing=off
fi
