#!/bin/zsh

source "$HOME/.config/sketchybar/colors.sh"
zmodload zsh/stat 2>/dev/null

AEROSPACE="/opt/homebrew/bin/aerospace"
SKETCHYBAR="/opt/homebrew/opt/sketchybar/bin/sketchybar"

STATE_DIR="/tmp/sketchybar_aerospace_sync"
LOCK_DIR="$STATE_DIR/lock"
DIRTY_FILE="$STATE_DIR/dirty"
mkdir -p "$STATE_DIR"

# Mark state dirty BEFORE acquiring the lock so rapid workspace switches
# (e.g. 1-2-3) coalesce into a single serialized stream of live queries
# and older invocations can never overwrite SketchyBar out of order.
: > "$DIRTY_FILE"

HAS_LOCK=0

acquire_lock() {
  if mkdir "$LOCK_DIR" 2>/dev/null; then
    print -r -- "$$" > "$LOCK_DIR/pid"
    HAS_LOCK=1
    return 0
  fi

  # Only reclaim a lock if it has been idle for >= 2s (prevents racing with a
  # freshly acquired lock right after a normal unlock/exit).
  local lock_mtime now holder_pid
  lock_mtime=$(zstat +mtime "$LOCK_DIR" 2>/dev/null || echo 0)
  now=${EPOCHSECONDS:-$(date +%s)}
  if (( lock_mtime > 0 && now - lock_mtime >= 2 )); then
    holder_pid=$(<"$LOCK_DIR/pid") 2>/dev/null || holder_pid=""
    if [[ -z "$holder_pid" ]] || ! kill -0 "$holder_pid" 2>/dev/null; then
      rm -rf "$LOCK_DIR" 2>/dev/null
      if mkdir "$LOCK_DIR" 2>/dev/null; then
        print -r -- "$$" > "$LOCK_DIR/pid"
        HAS_LOCK=1
        return 0
      fi
    fi
  fi
  return 1
}

cleanup() {
  rm -f "$STATE_DIR/ws_$$" "$STATE_DIR/nonempty_$$" 2>/dev/null
  if (( HAS_LOCK )); then
    rm -rf "$LOCK_DIR" 2>/dev/null
  fi
}

acquire_lock || exit 0
trap cleanup EXIT INT TERM HUP

sync_workspaces() {
  local ws_tmp="$STATE_DIR/ws_$$"
  local ne_tmp="$STATE_DIR/nonempty_$$"

  # Query live AeroSpace state in parallel (never trust stale FOCUSED_WORKSPACE env var)
  "$AEROSPACE" list-workspaces --all --format '%{workspace}|%{workspace-is-focused}|%{workspace-is-visible}' > "$ws_tmp" 2>/dev/null &
  local p1=$!
  "$AEROSPACE" list-workspaces --monitor all --empty no > "$ne_tmp" 2>/dev/null &
  local p2=$!
  wait "$p1" "$p2" 2>/dev/null

  local focused="" ws is_focused is_visible
  typeset -A VISIBLE_WS NON_EMPTY_WS

  while IFS='|' read -r ws is_focused is_visible; do
    [[ -z "$ws" ]] && continue
    [[ "$is_focused" == "true" ]] && focused="$ws"
    [[ "$is_visible" == "true" ]] && VISIBLE_WS[$ws]=1
  done < "$ws_tmp"

  while IFS= read -r ws; do
    [[ -n "$ws" ]] && NON_EMPTY_WS[$ws]=1
  done < "$ne_tmp"

  rm -f "$ws_tmp" "$ne_tmp"

  # Skip update if AeroSpace returned no focused workspace (e.g., mid-restart)
  [[ -n "$focused" ]] || return 0

  local sid show_ws
  local -a args=()
  for sid in 1 2 3 4 5 6 7 8 9 10; do
    if [[ "$sid" == "$focused" ]]; then
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
}

while true; do
  while [[ -f "$DIRTY_FILE" ]]; do
    rm -f "$DIRTY_FILE"
    sync_workspaces
  done

  HAS_LOCK=0
  rm -rf "$LOCK_DIR"

  # Close TOCTOU window: if another trigger set DIRTY_FILE right before we
  # unlocked, re-acquire the lock and run one final live sync.
  if [[ -f "$DIRTY_FILE" ]] && acquire_lock; then
    continue
  fi
  break
done
