#!/usr/bin/env bash

CITY=$(curl -4 -sS --max-time 5 "http://ip-api.com/json" 2>/dev/null | jq -r '.city // empty' 2>/dev/null)
if [ -n "$CITY" ]; then
  CITY_ESCAPED="${CITY// /+}"
  SHORT_WEATHER=$(curl -4 -sS --max-time 10 "https://wttr.in/${CITY_ESCAPED}?format=%c%t" 2>/dev/null | sed 's/  */ /g; s/^ *//; s/ *$//')
  FULL_WEATHER=$(curl -4 -sS --max-time 10 "https://wttr.in/${CITY_ESCAPED}?format=%l:+%c%t+(%f)++%h++%w+uv:%u" 2>/dev/null | sed 's/^ *//; s/ *$//')
else
  SHORT_WEATHER=$(curl -4 -sS --max-time 10 "https://wttr.in/?format=%c%t" 2>/dev/null | sed 's/  */ /g; s/^ *//; s/ *$//')
  FULL_WEATHER=$(curl -4 -sS --max-time 10 "https://wttr.in/?format=%l:+%c%t+(%f)++%h++%w+uv:%u" 2>/dev/null | sed 's/^ *//; s/ *$//')
fi

if [ -n "$SHORT_WEATHER" ] && [[ "$SHORT_WEATHER" != *"Unknown"* ]]; then
  jq -nc --arg text "$SHORT_WEATHER" --arg tooltip "${FULL_WEATHER:-$SHORT_WEATHER}" \
    '{text: $text, tooltip: $tooltip}'
else
  jq -nc '{text: "", tooltip: ""}'
fi
