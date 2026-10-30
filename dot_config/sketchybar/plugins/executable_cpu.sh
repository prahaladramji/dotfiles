#!/bin/zsh

source "$HOME/.config/sketchybar/colors.sh"

if [ "$SENDER" = "mouse.exited" ]; then
  sketchybar --set "$NAME" popup.drawing=off
  exit 0
fi

CORE_COUNT=$(/usr/sbin/sysctl -n machdep.cpu.thread_count 2>/dev/null || echo 8)
CPU_USAGE=$(ps -A -o %cpu | awk -v cores="$CORE_COUNT" '{s+=$1} END {printf "%.0f", s/cores}')

sketchybar --set "$NAME" label="${CPU_USAGE}%"

if [ "$SENDER" = "mouse.entered" ]; then
  BOOT_TIME=$(/usr/sbin/sysctl -n kern.boottime 2>/dev/null | awk '{sub(/,/, "", $4); print $4}')
  NOW=$(date +%s)
  DIFF=$((NOW - BOOT_TIME))
  DAYS=$((DIFF / 86400))
  HOURS=$(((DIFF % 86400) / 3600))
  MINS=$(((DIFF % 3600) / 60))
  UP=""
  [ "$DAYS" -gt 0 ] && UP="${DAYS}d "
  [ "$HOURS" -gt 0 ] && UP="${UP}${HOURS}h "
  UP="${UP}${MINS}m"

  LOAD=$(/usr/sbin/sysctl -n vm.loadavg 2>/dev/null | awk '{print $2, $3, $4}')
  TOP_PROC=$(ps -Aceo %cpu,comm -r | awk 'NR==2 {printf "%s (%s%%)", $2, $1}')
  sketchybar --set "${NAME}.tooltip" label="Up: ${UP} | Load: ${LOAD} | Top: ${TOP_PROC}" \
    --set "$NAME" popup.drawing=on
fi
