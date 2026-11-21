#!/usr/bin/env bash
set -euo pipefail

ALT_FILE="/tmp/polybar_clock_alt_${UID}"
TZ_FILE="/tmp/polybar_clock_tz_${UID}"
SOCK_PATH="/tmp/polybar_calendar_${UID}.sock"

TIMEZONES=("" "PST8PDT")
TZ_COUNT=${#TIMEZONES[@]}

get_tz_idx() {
  local idx=0
  if [[ -f "$TZ_FILE" ]]; then
    idx=$(<"$TZ_FILE")
  fi
  if ! [[ "$idx" =~ ^[0-9]+$ ]] || (( idx < 0 || idx >= TZ_COUNT )); then
    idx=0
  fi
  echo "$idx"
}

send_daemon() {
  local cmd="$1"
  if [[ -S "$SOCK_PATH" ]]; then
    python3 -c '
import socket, sys
s = socket.socket(socket.AF_UNIX, socket.SOCK_DGRAM)
try:
    s.sendto(sys.argv[1].encode(), sys.argv[2])
except OSError:
    pass
finally:
    s.close()
' "$cmd" "$SOCK_PATH" 2>/dev/null || true
  fi
}

print_clock() {
  local idx tz icon label
  idx=$(get_tz_idx)
  tz="${TIMEZONES[$idx]}"

  if [[ -n "$tz" ]]; then
    icon="%{F#d699b6}󰖟%{F-}"
    if [[ -f "$ALT_FILE" ]]; then
      label=$(TZ="$tz" date '+%H:%M (%Z) · %a, %b %d, %Y')
    else
      label=$(TZ="$tz" date '+%H:%M (%Z) · %b %d')
    fi
  else
    icon="%{F#7fbbb3}󰥔%{F-}"
    if [[ -f "$ALT_FILE" ]]; then
      label=$(date '+%H:%M (%Z) · %a, %b %d, %Y')
    else
      label=$(date '+%H:%M · %b %d')
    fi
  fi

  printf '%s %%{T2}%s%%{T-}\n' "$icon" "$label"
}

case "${1:-print}" in
  print)
    print_clock
    ;;
  toggle-format)
    if [[ -f "$ALT_FILE" ]]; then
      rm -f "$ALT_FILE"
    else
      touch "$ALT_FILE"
    fi
    polybar-msg action "#clock.hook.0" >/dev/null 2>&1 || true
    send_daemon "refresh"
    ;;
  tz-next)
    idx=$(get_tz_idx)
    idx=$(( (idx + 1) % TZ_COUNT ))
    printf '%d\n' "$idx" > "$TZ_FILE"
    polybar-msg action "#clock.hook.0" >/dev/null 2>&1 || true
    send_daemon "tz-changed"
    ;;
  tz-prev)
    idx=$(get_tz_idx)
    idx=$(( (idx - 1 + TZ_COUNT) % TZ_COUNT ))
    printf '%d\n' "$idx" > "$TZ_FILE"
    polybar-msg action "#clock.hook.0" >/dev/null 2>&1 || true
    send_daemon "tz-changed"
    ;;
  toggle-mode)
    send_daemon "toggle-mode"
    ;;
  scroll-up)
    send_daemon "scroll-up"
    ;;
  scroll-down)
    send_daemon "scroll-down"
    ;;
esac
