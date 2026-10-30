#!/usr/bin/env bash

STATE_FILE="/tmp/waybar_cpu_stat"
read -r _ user nice system idle iowait irq softirq steal _ < /proc/stat
TOTAL=$((user + nice + system + idle + iowait + irq + softirq + steal))
IDLE=$((idle + iowait))

if [ -f "$STATE_FILE" ]; then
  read -r PREV_TOTAL PREV_IDLE < "$STATE_FILE"
  DIFF_TOTAL=$((TOTAL - PREV_TOTAL))
  DIFF_IDLE=$((IDLE - PREV_IDLE))
  if [ "$DIFF_TOTAL" -gt 0 ]; then
    CPU_USAGE=$(( (100 * (DIFF_TOTAL - DIFF_IDLE)) / DIFF_TOTAL ))
  else
    CPU_USAGE=0
  fi
else
  CPU_USAGE=0
fi
echo "$TOTAL $IDLE" > "$STATE_FILE"

UPTIME_SEC=$(awk '{printf "%.0f", $1}' /proc/uptime)
DAYS=$((UPTIME_SEC / 86400))
HOURS=$(((UPTIME_SEC % 86400) / 3600))
MINS=$(((UPTIME_SEC % 3600) / 60))
UP=""
[ "$DAYS" -gt 0 ] && UP="${DAYS}d "
[ "$HOURS" -gt 0 ] && UP="${UP}${HOURS}h "
UP="${UP}${MINS}m"

LOAD=$(awk '{print $1, $2, $3}' /proc/loadavg)
TOP_PROC=$(ps -eo %cpu,comm --sort=-%cpu --no-headers | awk '$2 != "ps" {printf "%s (%s%%)", $2, $1; exit}')

TEXT="<span color='#9ece6a'>󰘚</span> ${CPU_USAGE}%"
TOOLTIP="Up: ${UP} | Load: ${LOAD} | Top: ${TOP_PROC}"

jq -nc --arg text "$TEXT" --arg tooltip "$TOOLTIP" \
  '{text: $text, tooltip: $tooltip}'
