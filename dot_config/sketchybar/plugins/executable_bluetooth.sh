#!/bin/zsh

source "$HOME/.config/sketchybar/colors.sh"

if [ "$SENDER" = "mouse.exited" ]; then
  sketchybar --set "$NAME" popup.drawing=off
  exit 0
fi

BT_DATA=$(system_profiler SPBluetoothDataType 2>/dev/null)
STATE=$(echo "$BT_DATA" | awk '/State:/ {print $2; exit}')
CTRL_ADDR=$(echo "$BT_DATA" | awk '/Bluetooth Controller:/, /State:/ {if ($1 == "Address:") print $2}')

if [ "$STATE" = "On" ]; then
  DEVICE_LINES=$(echo "$BT_DATA" | sed -n '/Connected:/,/Not Connected:/p' | awk '
    /^[ ]{10}[^ ].*:$/ {
      if (dev != "" && !(dev in seen)) {
        seen[dev] = 1
        line = dev " - " addr
        if (batt != "") line = line " - 󰁹 " batt
        print line
      }
      dev = $0
      sub(/^[ ]+/, "", dev)
      sub(/:$/, "", dev)
      addr = ""; batt = ""
    }
    /^[ ]{14}Address:/ { addr = $2 }
    /^[ ]{14}.*Battery Level:/ {
      val = $NF
      if (batt == "") batt = val
    }
    END {
      if (dev != "" && !(dev in seen)) {
        line = dev " - " addr
        if (batt != "") line = line " - 󰁹 " batt
        print line
      }
    }
  ')

  COUNT=0
  if [ -n "$DEVICE_LINES" ]; then
    COUNT=$(echo "$DEVICE_LINES" | wc -l | tr -d ' ')
  fi

  sketchybar --set "bluetooth.tooltip.1" drawing=on label="Controller - ${CTRL_ADDR:-On}"
  for idx in 2 3 4 5; do
    sketchybar --set "bluetooth.tooltip.$idx" drawing=off
  done

  if [ "${COUNT:-0}" -gt 0 ]; then
    idx=2
    echo "$DEVICE_LINES" | while IFS= read -r dline; do
      [ "$idx" -gt 5 ] && break
      sketchybar --set "bluetooth.tooltip.$idx" drawing=on label="$dline"
      idx=$((idx + 1))
    done

    sketchybar --set "$NAME" \
      icon="" \
      icon.color="$BLUETOOTH_COLOR" \
      icon.padding_right=4 \
      label="$COUNT" \
      label.drawing=on
  else
    sketchybar --set "$NAME" \
      icon="" \
      icon.color="$BLUETOOTH_COLOR" \
      label.drawing=off \
      icon.padding_right=7
  fi
else
  sketchybar --set "bluetooth.tooltip.1" drawing=on label="Bluetooth: Off"
  for idx in 2 3 4 5; do
    sketchybar --set "bluetooth.tooltip.$idx" drawing=off
  done

  sketchybar --set "$NAME" \
    icon="" \
    icon.color="$BLUETOOTH_DISABLED_COLOR" \
    label.drawing=off \
    icon.padding_right=7
fi

if [ "$SENDER" = "mouse.entered" ]; then
  sketchybar --set "$NAME" popup.drawing=on
fi
