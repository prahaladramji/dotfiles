#!/usr/bin/env bash
set -euo pipefail

if command -v btop >/dev/null 2>&1; then
  exec alacritty --class floater -e btop
elif command -v htop >/dev/null 2>&1; then
  exec alacritty --class floater -e htop
else
  exec alacritty --class floater -e top
fi
