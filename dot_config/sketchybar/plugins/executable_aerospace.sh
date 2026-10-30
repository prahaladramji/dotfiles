#!/bin/zsh

source "$HOME/.config/sketchybar/colors.sh"

SID="$1"
FOCUSED="${FOCUSED_WORKSPACE:-$(/opt/homebrew/bin/aerospace list-workspaces --focused 2>/dev/null)}"

# Workspaces 1-5 are always persistent. Workspaces 6-10 appear when focused or non-empty.
SHOW_WORKSPACE="on"
if [ "$SID" -gt 5 ] && [ "$SID" != "$FOCUSED" ]; then
  WIN_COUNT=$(/opt/homebrew/bin/aerospace list-windows --workspace "$SID" --count 2>/dev/null || echo 0)
  if [ "${WIN_COUNT:-0}" -eq 0 ]; then
    SHOW_WORKSPACE="off"
  fi
fi

if [ "$SID" = "$FOCUSED" ]; then
  sketchybar --set "$NAME" \
    drawing=on \
    label.color="$WORKSPACES_FOCUSED_FG" \
    label.font="Hack Nerd Font:Bold:13.0" \
    background.drawing=on \
    background.color="$WORKSPACES_FOCUSED_BG"
else
  sketchybar --set "$NAME" \
    drawing="$SHOW_WORKSPACE" \
    label.color="$WORKSPACES_COLOR" \
    label.font="Hack Nerd Font:Regular:13.0" \
    background.drawing=off
fi
