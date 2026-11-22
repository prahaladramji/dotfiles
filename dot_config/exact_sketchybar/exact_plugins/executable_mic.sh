#!/bin/zsh

source "$HOME/.config/sketchybar/colors.sh"

ITEM="${NAME:-mic}"
DEV_CACHE="/tmp/sketchybar_mic_dev"

if [ "$1" = "toggle" ]; then
  hover_cancel "$ITEM"
  MIC_VOL=$(osascript -e 'input volume of (get volume settings)' 2>/dev/null || echo 0)
  if [ "${MIC_VOL:-0}" -gt 0 ]; then
    osascript -e 'set volume input volume 0'
    MIC_VOL=0
    sketchybar --set "$ITEM" icon="󰍭" icon.color="$VOLUME_MUTED_COLOR" icon.padding_right=7 label.drawing=off
  else
    osascript -e 'set volume input volume 80'
    MIC_VOL=80
    sketchybar --set "$ITEM" icon="󰍬" icon.color="$VOLUME_COLOR" icon.padding_right=7 label.drawing=off
  fi
  IN_DEV=$(<"$DEV_CACHE") 2>/dev/null || IN_DEV="Default Input"
  sketchybar --set "${ITEM}.tooltip" label="${IN_DEV} (${MIC_VOL}%)"
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

MIC_VOL=$(osascript -e 'input volume of (get volume settings)' 2>/dev/null || echo 0)
IN_DEV=$(system_profiler SPAudioDataType 2>/dev/null | awk '/^[ ]{8}[^ ].*:$/ {dev=$0; sub(/^[ ]+/, "", dev); sub(/:$/, "", dev)} /Default Input Device: Yes/ {print dev; exit}')
IN_DEV="${IN_DEV:-Default Input}"
print -r -- "$IN_DEV" > "$DEV_CACHE"

if [ "${MIC_VOL:-0}" -le 0 ]; then
  sketchybar --set "$ITEM" \
    icon="󰍭" \
    icon.color="$VOLUME_MUTED_COLOR" \
    icon.padding_right=7 \
    label.drawing=off \
    --set "${ITEM}.tooltip" label="${IN_DEV} (${MIC_VOL}%)"
else
  sketchybar --set "$ITEM" \
    icon="󰍬" \
    icon.color="$VOLUME_COLOR" \
    icon.padding_right=7 \
    label.drawing=off \
    --set "${ITEM}.tooltip" label="${IN_DEV} (${MIC_VOL}%)"
fi
