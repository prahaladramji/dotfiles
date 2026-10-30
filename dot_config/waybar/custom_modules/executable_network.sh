#!/usr/bin/env bash

STATE_FILE="/tmp/waybar_network_alt"
CACHE_FILE="/tmp/waybar_wan_ip_cache"
CACHE_TTL=300

if [ "$1" = "toggle" ]; then
  if [ -f "$STATE_FILE" ]; then
    rm -f "$STATE_FILE"
  else
    touch "$STATE_FILE"
  fi
  pkill -RTMIN+8 waybar 2>/dev/null
  exit 0
fi

DEFAULT_ROUTE=$(ip route show default 2>/dev/null | head -n1)
DEFAULT_IFACE=$(echo "$DEFAULT_ROUTE" | awk '{for(i=1;i<=NF;i++) if($i=="dev") print $(i+1)}')
ROUTER=$(echo "$DEFAULT_ROUTE" | awk '{for(i=1;i<=NF;i++) if($i=="via") print $(i+1)}')

if [ -z "$DEFAULT_IFACE" ]; then
  jq -nc '{
    text: "<span color=\"#f7768e\">󰖪</span>",
    tooltip: "Status: Disconnected",
    class: "disconnected"
  }'
  exit 0
fi

IP_ADDR=$(ip -4 -o addr show dev "$DEFAULT_IFACE" 2>/dev/null | awk '{split($4, a, "/"); print a[1]; exit}')

if [ -d "/sys/class/net/${DEFAULT_IFACE}/wireless" ] || [ -d "/sys/class/net/${DEFAULT_IFACE}/phy80211" ]; then
  ICON="<span color='#7aa2f7'>󰖩</span>"
  SSID=$(iwgetid -r "$DEFAULT_IFACE" 2>/dev/null)
  if [ -z "$SSID" ] && command -v nmcli >/dev/null 2>&1; then
    SSID=$(nmcli -t -f GENERAL.CONNECTION device show "$DEFAULT_IFACE" 2>/dev/null | cut -d: -f2-)
  fi
else
  ICON="<span color='#7aa2f7'>󰈀</span>"
  SSID=""
fi

if [ -f "$STATE_FILE" ] && [ -n "$IP_ADDR" ]; then
  TEXT="${ICON} ${IP_ADDR}"
elif [ -n "$SSID" ] && [ "$SSID" != "--" ]; then
  TEXT="${ICON} ${SSID}"
else
  TEXT="${ICON}"
fi

NOW=$(date +%s)
CACHE_TIME=0
if [ -f "$CACHE_FILE" ]; then
  CACHE_TIME=$(stat -c %Y "$CACHE_FILE" 2>/dev/null || echo 0)
fi

if [ $((NOW - CACHE_TIME)) -ge "$CACHE_TTL" ]; then
  (
    IPV4=$(curl -4 -sS --max-time 3 "https://api.ipify.org" 2>/dev/null)
    IPV6=$(curl -6 -sS --max-time 3 "https://api6.ipify.org" 2>/dev/null)
    {
      echo "IPV4=${IPV4}"
      echo "IPV6=${IPV6}"
    } > "${CACHE_FILE}.tmp" && mv "${CACHE_FILE}.tmp" "$CACHE_FILE"
    pkill -RTMIN+8 waybar 2>/dev/null
  ) >/dev/null 2>&1 &
fi

IPV4=""
IPV6=""
if [ -f "$CACHE_FILE" ]; then
  # shellcheck disable=SC1090
  source "$CACHE_FILE"
fi

TOOLTIP="LAN (${DEFAULT_IFACE}): ${IP_ADDR:-No IP}"
[ -n "$ROUTER" ] && TOOLTIP="${TOOLTIP} | gw: ${ROUTER}"
[ -n "$IPV4" ] && TOOLTIP="${TOOLTIP}"$'\n'"WAN (v4): ${IPV4}"
if [ -n "$IPV6" ] && [[ "$IPV6" == *:* ]]; then
  TOOLTIP="${TOOLTIP}"$'\n'"WAN (v6): ${IPV6}"
fi

jq -nc --arg text "$TEXT" --arg tooltip "$TOOLTIP" \
  '{text: $text, tooltip: $tooltip, class: "connected"}'
