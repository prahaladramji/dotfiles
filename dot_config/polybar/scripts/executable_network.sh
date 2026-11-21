#!/usr/bin/env bash
set -euo pipefail

STATE_FILE="/tmp/polybar_network_compact_${UID}"

if [[ "${1:-}" == "toggle" ]]; then
  if [[ -f "$STATE_FILE" ]]; then
    rm -f "$STATE_FILE"
  else
    touch "$STATE_FILE"
  fi
  polybar-msg action "#network.hook.0" >/dev/null 2>&1 || true
  exit 0
fi

DEFAULT_IFACE=$(ip route show default 2>/dev/null | awk '{for(i=1;i<=NF;i++) if($i=="dev") {print $(i+1); exit}}')
if [[ -z "$DEFAULT_IFACE" ]]; then
  printf '%%{F#e67e80}󰖪%%{F-} down\n'
  exit 0
fi

IP_ADDR=$(ip -4 -o addr show dev "$DEFAULT_IFACE" 2>/dev/null | awk '{split($4, a, "/"); print a[1]; exit}')

if [[ -f "$STATE_FILE" ]] || [[ -z "$IP_ADDR" ]]; then
  printf '%%{F#7fbbb3}󰈀%%{F-}\n'
else
  printf '%%{F#7fbbb3}󰈀%%{F-} %s\n' "$IP_ADDR"
fi
