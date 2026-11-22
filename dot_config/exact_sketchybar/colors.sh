#!/bin/zsh

export PATH="/opt/homebrew/bin:/opt/homebrew/opt/sketchybar/bin:/usr/sbin:/usr/bin:/bin:/sbin:$PATH"

# -----------------------------------------------------------------------------
# Tokyo Night Palette (Minimal Floating Pills)
# -----------------------------------------------------------------------------
export BG_COLOR=0xff1a1b26
export PILL_BG=0xe81a1b26
export PILL_BORDER=0xff2f3549
export BG_LIGHT_COLOR=0xf224283b
export FG_COLOR=0xffc0caf5
export SUBTEXT_COLOR=0xffa9b1d6
export MUTED_COLOR=0xff565f89
export BLACK=0xff15161e
export RED=0xfff7768e
export GREEN=0xff9ece6a
export YELLOW=0xffe0af68
export BLUE=0xff7aa2f7
export MAGENTA=0xffbb9af7
export CYAN=0xff7dcfff
export WHITE=0xffa9b1d6
export ORANGE=0xffff9e64
export TRANSPARENT=0x00000000

# Module-specific colors
export WORKSPACES_COLOR=$SUBTEXT_COLOR
export WORKSPACES_FOCUSED_BG=$BLUE
export WORKSPACES_FOCUSED_FG=$BLACK
export WORKSPACES_URGENT_BG=$RED
export WORKSPACES_URGENT_FG=$BLACK

export MODE_COLOR=$ORANGE
export WEATHER_COLOR=$MAGENTA
export PUBLIC_IP_COLOR=$CYAN
export CLOCK_COLOR=$BLUE
export CPU_COLOR=$GREEN
export MEMORY_COLOR=$MAGENTA
export TEMP_COLOR=$YELLOW
export BATTERY_COLOR=$CYAN
export BATTERY_CHARGING_COLOR=$GREEN
export BATTERY_WARNING_COLOR=$YELLOW
export BATTERY_CRITICAL_COLOR=$RED
export BLUETOOTH_COLOR=$BLUE
export BLUETOOTH_DISABLED_COLOR=$RED
export NETWORK_COLOR=$BLUE
export NETWORK_DISCONNECTED_COLOR=$RED
export VOLUME_COLOR=$ORANGE
export VOLUME_MUTED_COLOR=$RED
export BACKLIGHT_COLOR=$YELLOW
export DISK_COLOR=$CYAN
export UPTIME_COLOR=$GREEN
export IDLE_COLOR=$SUBTEXT_COLOR
export IDLE_ACTIVE_COLOR=$RED

# -----------------------------------------------------------------------------
# Hover Popup Helpers (Pre-Cached Tooltips, Zero Click Lag, Warm Glide)
# -----------------------------------------------------------------------------
zmodload zsh/datetime 2>/dev/null

export HOVER_IN_DELAY="${HOVER_IN_DELAY:-0.25}"
export HOVER_GLIDE_DELAY="${HOVER_GLIDE_DELAY:-0.08}"
export HOVER_WARM_WINDOW="${HOVER_WARM_WINDOW:-0.40}"
export HOVER_DIR="/tmp/sketchybar_hover"

hover_enter() {
  local item="${1:-$NAME}"
  mkdir -p "$HOVER_DIR"
  local token="enter_$$_${RANDOM}"
  print -r -- "$token" > "$HOVER_DIR/$item"
  print -r -- "$item" > "$HOVER_DIR/_target"

  local prev_open warm_ts delay="$HOVER_IN_DELAY"
  prev_open=$(<"$HOVER_DIR/_open") 2>/dev/null || prev_open=""
  if [[ -n "$prev_open" && "$prev_open" != "$item" ]]; then
    sketchybar --set "$prev_open" popup.drawing=off
    rm -f "$HOVER_DIR/_open"
    delay="$HOVER_GLIDE_DELAY"
  elif [[ -f "$HOVER_DIR/_warm" ]]; then
    warm_ts=$(<"$HOVER_DIR/_warm") 2>/dev/null || warm_ts=0
    if (( EPOCHREALTIME - warm_ts <= HOVER_WARM_WINDOW )); then
      delay="$HOVER_GLIDE_DELAY"
    fi
  fi

  sleep "$delay"

  local cur_token cur_target
  cur_token=$(<"$HOVER_DIR/$item") 2>/dev/null || cur_token=""
  cur_target=$(<"$HOVER_DIR/_target") 2>/dev/null || cur_target=""
  [[ "$cur_token" == "$token" && "$cur_target" == "$item" ]] || return 1

  print -r -- "$item" > "$HOVER_DIR/_open"
  print -r -- "$EPOCHREALTIME" > "$HOVER_DIR/_warm"
  sketchybar --set "$item" popup.drawing=on
  return 0
}

hover_exit() {
  local item="${1:-$NAME}"
  mkdir -p "$HOVER_DIR"
  print -r -- "exit_$$_${RANDOM}" > "$HOVER_DIR/$item"

  local prev_open
  prev_open=$(<"$HOVER_DIR/_open") 2>/dev/null || prev_open=""
  if [[ "$prev_open" == "$item" ]]; then
    rm -f "$HOVER_DIR/_open"
    print -r -- "$EPOCHREALTIME" > "$HOVER_DIR/_warm"
  fi
  sketchybar --set "$item" popup.drawing=off
  return 0
}

hover_cancel() {
  local item="${1:-$NAME}"
  mkdir -p "$HOVER_DIR"
  print -r -- "cancel_$$_${RANDOM}" > "$HOVER_DIR/$item"
  rm -f "$HOVER_DIR/_open" "$HOVER_DIR/_warm"
}
