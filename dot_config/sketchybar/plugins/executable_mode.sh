#!/bin/zsh

source "$HOME/.config/sketchybar/colors.sh"

CURRENT_MODE=$(/opt/homebrew/bin/aerospace list-modes --current 2>/dev/null || echo "main")

if [ "$CURRENT_MODE" = "main" ] || [ -z "$CURRENT_MODE" ]; then
  sketchybar --set "$NAME" drawing=off
else
  sketchybar --set "$NAME" \
    drawing=on \
    label="$CURRENT_MODE"
fi
