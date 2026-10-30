#!/bin/zsh

source "$HOME/.config/sketchybar/colors.sh"

if [ "$SENDER" = "mouse.exited" ]; then
  sketchybar --set "$NAME" popup.drawing=off
  exit 0
fi

STATE_FILE="/tmp/sketchybar_network_alt"
if [ "$1" = "toggle" ]; then
  if [ -f "$STATE_FILE" ]; then
    rm -f "$STATE_FILE"
  else
    touch "$STATE_FILE"
  fi
fi

DEFAULT_IFACE=$(route -n get default 2>/dev/null | awk '/interface:/ {print $2}')

if [ -z "$DEFAULT_IFACE" ]; then
  sketchybar --set "$NAME" \
    icon="󰖪" \
    icon.color="$NETWORK_DISCONNECTED_COLOR" \
    icon.padding_right=7 \
    label.drawing=off \
    --set "network.tooltip.1" drawing=on label="Status: Disconnected" \
    --set "network.tooltip.2" drawing=off \
    --set "network.tooltip.3" drawing=off
  [ "$SENDER" = "mouse.entered" ] && sketchybar --set "$NAME" popup.drawing=on
  exit 0
fi

SUMMARY=$(ipconfig getsummary "$DEFAULT_IFACE" 2>/dev/null)
IP_ADDR=$(ipconfig getifaddr "$DEFAULT_IFACE" 2>/dev/null)
IFACE_TYPE=$(echo "$SUMMARY" | awk -F ' : ' '/^  InterfaceType/ {print $2}')
SSID=$(echo "$SUMMARY" | awk -F ' : ' '/^  SSID/ {print $2}')
ROUTER=$(echo "$SUMMARY" | awk -F ' : ' '/Router / {print $2; exit}')
DOMAIN=$(echo "$SUMMARY" | awk -F ': ' '/domain_name \(string\)/ {print $2; exit}')

if [ "$IFACE_TYPE" = "WiFi" ]; then
  ICON="󰖩"
else
  ICON="󰈀"
fi

if [ "$SSID" = "<redacted>" ] || [ -z "$SSID" ]; then
  SSID=""
fi

if [ -f "$STATE_FILE" ] && [ -n "$IP_ADDR" ]; then
  sketchybar --set "$NAME" \
    icon="$ICON" \
    icon.color="$NETWORK_COLOR" \
    icon.padding_right=4 \
    label="$IP_ADDR" \
    label.drawing=on
elif [ -n "$SSID" ]; then
  sketchybar --set "$NAME" \
    icon="$ICON" \
    icon.color="$NETWORK_COLOR" \
    icon.padding_right=4 \
    label="$SSID" \
    label.drawing=on
else
  # Minimalist icon-only when connected and SSID is redacted
  sketchybar --set "$NAME" \
    icon="$ICON" \
    icon.color="$NETWORK_COLOR" \
    icon.padding_right=7 \
    label.drawing=off
fi

if [ "$SENDER" = "mouse.entered" ]; then
  LAN_LINE="LAN (${DEFAULT_IFACE}): ${IP_ADDR:-No IP}"
  [ -n "$ROUTER" ] && LAN_LINE="${LAN_LINE} | gw: ${ROUTER}"
  [ -n "$DOMAIN" ] && LAN_LINE="${LAN_LINE} (${DOMAIN})"
  sketchybar --set "network.tooltip.1" drawing=on label="$LAN_LINE"

  IPV4=$(curl -4 -sS --max-time 3 "https://api.ipify.org" 2>/dev/null)
  if [ -n "$IPV4" ]; then
    sketchybar --set "network.tooltip.2" drawing=on label="WAN (v4): ${IPV4}"
  else
    sketchybar --set "network.tooltip.2" drawing=off
  fi

  IPV6=$(curl -6 -sS --max-time 3 "https://api6.ipify.org" 2>/dev/null)
  if [ -n "$IPV6" ] && [[ "$IPV6" == *:* ]]; then
    sketchybar --set "network.tooltip.3" drawing=on label="WAN (v6): ${IPV6}"
  else
    sketchybar --set "network.tooltip.3" drawing=off
  fi

  sketchybar --set "$NAME" popup.drawing=on
fi
