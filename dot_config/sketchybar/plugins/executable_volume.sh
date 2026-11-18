#!/bin/zsh

source "$HOME/.config/sketchybar/colors.sh"

ITEM="${NAME:-volume}"

update_volume_bar() {
  local vol="$1"
  local muted="$2"
  if [ "$muted" = "true" ] || [ "${vol:-0}" -eq 0 ]; then
    sketchybar --set "$ITEM" \
      icon="󰝟" \
      icon.color="$VOLUME_MUTED_COLOR" \
      icon.padding_right=7 \
      label.drawing=off
  else
    local icon="󰕾"
    if [ "$vol" -lt 34 ]; then
      icon="󰕿"
    elif [ "$vol" -lt 67 ]; then
      icon="󰖀"
    fi
    sketchybar --set "$ITEM" \
      icon="$icon" \
      icon.color="$VOLUME_COLOR" \
      icon.padding_right=4 \
      label="${vol}%" \
      label.drawing=on
  fi
}

if [ "$1" = "toggle" ]; then
  hover_cancel "$ITEM"
  VOL_SETTINGS=$(osascript -e 'set volume output muted not (output muted of (get volume settings))' -e 'get volume settings' 2>/dev/null)
  VOLUME=$(print -r -- "$VOL_SETTINGS" | sed -n 's/.*output volume:\([0-9]*\).*/\1/p')
  MUTED=$(print -r -- "$VOL_SETTINGS" | sed -n 's/.*output muted:\(true\|false\).*/\1/p')
  update_volume_bar "$VOLUME" "$MUTED"
  exit 0
fi

if [ "$SENDER" = "mouse.scrolled" ]; then
  DELTA="${SCROLL_DELTA:-0}"
  if [ "$DELTA" -gt 0 ]; then
    VOL_SETTINGS=$(osascript -e 'set volume output volume ((output volume of (get volume settings)) + 2)' -e 'get volume settings' 2>/dev/null)
  elif [ "$DELTA" -lt 0 ]; then
    VOL_SETTINGS=$(osascript -e 'set volume output volume ((output volume of (get volume settings)) - 2)' -e 'get volume settings' 2>/dev/null)
  else
    exit 0
  fi
  VOLUME=$(print -r -- "$VOL_SETTINGS" | sed -n 's/.*output volume:\([0-9]*\).*/\1/p')
  MUTED=$(print -r -- "$VOL_SETTINGS" | sed -n 's/.*output muted:\(true\|false\).*/\1/p')
  update_volume_bar "$VOLUME" "$MUTED"
  exit 0
fi

if [ "$SENDER" = "mouse.exited" ]; then
  hover_exit "$ITEM"
  exit 0
fi

if [ "$SENDER" = "mouse.entered" ]; then
  hover_enter "$ITEM"
  exit 0
fi

if [ "$SENDER" = "volume_change" ] && [ -n "$INFO" ]; then
  update_volume_bar "$INFO" "false"
else
  VOL_SETTINGS=$(osascript -e 'get volume settings' 2>/dev/null)
  VOLUME=$(print -r -- "$VOL_SETTINGS" | sed -n 's/.*output volume:\([0-9]*\).*/\1/p')
  MUTED=$(print -r -- "$VOL_SETTINGS" | sed -n 's/.*output muted:\(true\|false\).*/\1/p')
  update_volume_bar "$VOLUME" "$MUTED"
fi

OUT_DEV=$(system_profiler SPAudioDataType 2>/dev/null | awk '/^[ ]{8}[^ ].*:$/ {dev=$0; sub(/^[ ]+/, "", dev); sub(/:$/, "", dev)} /Default Output Device: Yes/ {print dev; exit}')
sketchybar --set "${ITEM}.tooltip" label="${OUT_DEV:-Default Output}"
