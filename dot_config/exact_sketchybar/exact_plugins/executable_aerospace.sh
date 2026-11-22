#!/bin/zsh

source "$HOME/.config/sketchybar/colors.sh"

AEROSPACE="/opt/homebrew/bin/aerospace"
SKETCHYBAR="/opt/homebrew/opt/sketchybar/bin/sketchybar"

FOCUSED="${FOCUSED_WORKSPACE:-$("$AEROSPACE" list-workspaces --focused 2>/dev/null)}"

typeset -A VISIBLE_WS NON_EMPTY_WS
for ws in ${(f)"$("$AEROSPACE" list-workspaces --monitor all --visible 2>/dev/null)"}; do
  [[ -n "$ws" ]] && VISIBLE_WS[$ws]=1
done
for ws in ${(f)"$("$AEROSPACE" list-workspaces --monitor all --empty no 2>/dev/null)"}; do
  [[ -n "$ws" ]] && NON_EMPTY_WS[$ws]=1
done

args=()
for sid in 1 2 3 4 5 6 7 8 9 10; do
  if [[ "$sid" == "$FOCUSED" ]]; then
    args+=(
      --set "space.$sid"
        drawing=on
        label.color="$WORKSPACES_FOCUSED_FG"
        label.font="Hack Nerd Font:Bold:15.0"
        background.drawing=on
        background.color="$WORKSPACES_FOCUSED_BG"
    )
  else
    # Workspaces 1-5 are persistent; 6-10 appear when visible on any monitor or non-empty
    show_ws="on"
    if (( sid > 5 )) && [[ -z "${VISIBLE_WS[$sid]}" && -z "${NON_EMPTY_WS[$sid]}" ]]; then
      show_ws="off"
    fi
    args+=(
      --set "space.$sid"
        drawing="$show_ws"
        label.color="$WORKSPACES_COLOR"
        label.font="Hack Nerd Font:Regular:15.0"
        background.drawing=off
    )
  fi
done

"$SKETCHYBAR" "${args[@]}"
