#!/bin/zsh

source "$HOME/.config/sketchybar/colors.sh"

if [ "$SENDER" = "mouse.exited" ]; then
  sketchybar --set "$NAME" popup.drawing=off
  exit 0
fi

if [ "$1" = "toggle" ]; then
  osascript -e 'set volume output muted not (output muted of (get volume settings))'
fi

if [ "$SENDER" = "mouse.scrolled" ]; then
  DELTA="${SCROLL_DELTA:-0}"
  if [ "$DELTA" -gt 0 ]; then
    osascript -e 'set volume output volume ((output volume of (get volume settings)) + 2)'
  elif [ "$DELTA" -lt 0 ]; then
    osascript -e 'set volume output volume ((output volume of (get volume settings)) - 2)'
  fi
fi

VOL_SETTINGS=$(osascript -e 'get volume settings' 2>/dev/null)
VOLUME=$(echo "$VOL_SETTINGS" | sed -n 's/.*output volume:\([0-9]*\).*/\1/p')
MUTED=$(echo "$VOL_SETTINGS" | sed -n 's/.*output muted:\(true\|false\).*/\1/p')

if [ "$MUTED" = "true" ] || [ "${VOLUME:-0}" -eq 0 ]; then
  sketchybar --set "$NAME" \
    icon="󰝟" \
    icon.color="$VOLUME_MUTED_COLOR" \
    icon.padding_right=7 \
    label.drawing=off
else
  if [ "$VOLUME" -lt 34 ]; then
    ICON="󰕿"
  elif [ "$VOLUME" -lt 67 ]; then
    ICON="󰖀"
  else
    ICON="󰕾"
  fi
  sketchybar --set "$NAME" \
    icon="$ICON" \
    icon.color="$VOLUME_COLOR" \
    icon.padding_right=4 \
    label="${VOLUME}%" \
    label.drawing=on
fi

if [ "$SENDER" = "mouse.entered" ]; then
  OUT_DEV=$(system_profiler SPAudioDataType 2>/dev/null | awk '/^[ ]{8}[^ ].*:$/ {dev=$0; sub(/^[ ]+/, "", dev); sub(/:$/, "", dev)} /Default Output Device: Yes/ {print dev; exit}')
  sketchybar --set "${NAME}.tooltip" label="${OUT_DEV:-Default Output}" \
    --set "$NAME" popup.drawing=on
fi
