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
