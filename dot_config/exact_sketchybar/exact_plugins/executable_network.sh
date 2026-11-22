#!/bin/zsh

source "$HOME/.config/sketchybar/colors.sh"

ITEM="${NAME:-network}"
STATE_FILE="/tmp/sketchybar_network_alt"
CACHE_FILE="/tmp/sketchybar_network_cache"

apply_network_bar() {
  local icon="$1" ip="$2" ssid="$3"
  if [ -f "$STATE_FILE" ] && [ -n "$ip" ]; then
    sketchybar --set "$ITEM" \
      icon="$icon" \
      icon.color="$NETWORK_COLOR" \
      icon.padding_right=4 \
      label="$ip" \
      label.drawing=on
  elif [ -n "$ssid" ]; then
    sketchybar --set "$ITEM" \
      icon="$icon" \
      icon.color="$NETWORK_COLOR" \
      icon.padding_right=4 \
      label="$ssid" \
      label.drawing=on
  else
    sketchybar --set "$ITEM" \
      icon="$icon" \
      icon.color="$NETWORK_COLOR" \
      icon.padding_right=7 \
      label.drawing=off
  fi
}

# Fast path for click toggle (< 5ms using cached interface state)
if [ "$1" = "toggle" ]; then
  hover_cancel "$ITEM"
  if [ -f "$STATE_FILE" ]; then
    rm -f "$STATE_FILE"
  else
    touch "$STATE_FILE"
  fi
  if [ -f "$CACHE_FILE" ]; then
    {
      IFS= read -r CACHED_ICON
      IFS= read -r CACHED_IP
      IFS= read -r CACHED_SSID
    } < "$CACHE_FILE"
    if [ -n "$CACHED_ICON" ]; then
      apply_network_bar "$CACHED_ICON" "$CACHED_IP" "$CACHED_SSID"
      exit 0
    fi
  fi
fi

if [ "$1" != "toggle" ]; then
  if [ "$SENDER" = "mouse.exited" ]; then
    hover_exit "$ITEM"
    exit 0
  elif [ "$SENDER" = "mouse.entered" ]; then
    hover_enter "$ITEM"
    exit 0
  fi
fi

DEFAULT_IFACE=$(route -n get default 2>/dev/null | awk '/interface:/ {print $2}')

if [ -z "$DEFAULT_IFACE" ]; then
  rm -f "$CACHE_FILE"
  sketchybar --set "$ITEM" \
    icon="󰖪" \
    icon.color="$NETWORK_DISCONNECTED_COLOR" \
    icon.padding_right=7 \
    label.drawing=off \
    --set "network.tooltip.1" drawing=on label="Status: Disconnected" \
    --set "network.tooltip.2" drawing=off \
    --set "network.tooltip.3" drawing=off
  exit 0
fi

SUMMARY=$(ipconfig getsummary "$DEFAULT_IFACE" 2>/dev/null)
IP_ADDR=$(ipconfig getifaddr "$DEFAULT_IFACE" 2>/dev/null)
[ -z "$IP_ADDR" ] && IP_ADDR=$(ifconfig "$DEFAULT_IFACE" 2>/dev/null | awk '/inet / {print $2; exit}')
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

printf '%s\n%s\n%s\n' "$ICON" "$IP_ADDR" "$SSID" > "$CACHE_FILE"
apply_network_bar "$ICON" "$IP_ADDR" "$SSID"

LAN_LINE="LAN (${DEFAULT_IFACE}): ${IP_ADDR:-No IP}"
[ -n "$ROUTER" ] && LAN_LINE="${LAN_LINE} | gw: ${ROUTER}"
[ -n "$DOMAIN" ] && LAN_LINE="${LAN_LINE} (${DOMAIN})"
sketchybar --set "network.tooltip.1" drawing=on label="$LAN_LINE"

# Fetch WAN IPv4 & IPv6 in parallel during background update so hover is 0ms
if [ "$1" != "toggle" ]; then
  V4_TMP="/tmp/sketchybar_wan_v4"
  V6_TMP="/tmp/sketchybar_wan_v6"
  curl -4 -sS --max-time 2 "https://api.ipify.org" > "$V4_TMP" 2>/dev/null &
  P4=$!
  curl -6 -sS --max-time 2 "https://api6.ipify.org" > "$V6_TMP" 2>/dev/null &
  P6=$!
  wait "$P4" "$P6" 2>/dev/null

  IPV4=$(<"$V4_TMP") 2>/dev/null || IPV4=""
  IPV6=$(<"$V6_TMP") 2>/dev/null || IPV6=""

  ARGS=()
  if [ -n "$IPV4" ]; then
    ARGS+=(--set "network.tooltip.2" drawing=on label="WAN (v4): ${IPV4}")
  else
    ARGS+=(--set "network.tooltip.2" drawing=off)
  fi
  if [ -n "$IPV6" ] && [[ "$IPV6" == *:* ]]; then
    ARGS+=(--set "network.tooltip.3" drawing=on label="WAN (v6): ${IPV6}")
  else
    ARGS+=(--set "network.tooltip.3" drawing=off)
  fi
  sketchybar "${ARGS[@]}"
fi
