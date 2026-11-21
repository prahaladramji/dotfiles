#!/usr/bin/env bash
set -euo pipefail

# Terminate running Polybar and helper daemons cleanly
pkill -x polybar 2>/dev/null || true
pkill -f "polybar/scripts/calendar_daemon.py" 2>/dev/null || true
pkill -f "polybar/scripts/scratchpad.sh" 2>/dev/null || true

for _ in $(seq 1 30); do
  pgrep -x polybar >/dev/null 2>&1 || break
  sleep 0.1
done

# Launch one Polybar instance per connected monitor
if command -v xrandr >/dev/null 2>&1; then
  MONITORS=$(xrandr --query | awk '/ connected/{print $1}')
else
  MONITORS=""
fi

if [[ -n "$MONITORS" ]]; then
  while IFS= read -r mon; do
    MONITOR="$mon" polybar --reload main >"/tmp/polybar_${UID}_${mon}.log" 2>&1 &
  done <<< "$MONITORS"
else
  polybar --reload main >"/tmp/polybar_${UID}.log" 2>&1 &
fi

# Start persistent GTK3 hover/click calendar + clock refresher daemon
if command -v python3 >/dev/null 2>&1; then
  "$HOME/.config/polybar/scripts/calendar_daemon.py" >"/tmp/polybar_calendar_${UID}.log" 2>&1 &
fi
