#!/bin/zsh

source "$HOME/.config/sketchybar/colors.sh"

if [ "$SENDER" = "mouse.exited" ]; then
  sketchybar --set "$NAME" popup.drawing=off
  exit 0
fi

MIC_VOL=$(osascript -e 'input volume of (get volume settings)' 2>/dev/null || echo 0)

if [ "$1" = "toggle" ]; then
  if [ "${MIC_VOL:-0}" -gt 0 ]; then
    osascript -e 'set volume input volume 0'
    MIC_VOL=0
  else
    osascript -e 'set volume input volume 80'
    MIC_VOL=80
  fi
fi

if [ "${MIC_VOL:-0}" -le 0 ]; then
  sketchybar --set "$NAME" \
    icon="󰍭" \
    icon.color="$VOLUME_MUTED_COLOR" \
    icon.padding_right=7 \
    label.drawing=off
else
  sketchybar --set "$NAME" \
    icon="󰍬" \
    icon.color="$VOLUME_COLOR" \
    icon.padding_right=7 \
    label.drawing=off
fi

if [ "$SENDER" = "mouse.entered" ]; then
  IN_DEV=$(system_profiler SPAudioDataType 2>/dev/null | awk '/^[ ]{8}[^ ].*:$/ {dev=$0; sub(/^[ ]+/, "", dev); sub(/:$/, "", dev)} /Default Input Device: Yes/ {print dev; exit}')
  sketchybar --set "${NAME}.tooltip" label="${IN_DEV:-Default Input} (${MIC_VOL}%)" \
    --set "$NAME" popup.drawing=on
fi
