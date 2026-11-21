#!/usr/bin/env bash
set -euo pipefail

trap 'kill 0 2>/dev/null || true' EXIT

print_count() {
  local count
  count=$(i3-msg -t get_tree 2>/dev/null | jq '[.. | objects | select(.name? == "__i3_scratch") | .floating_nodes[]?] | length' 2>/dev/null || echo 0)
  if [[ "$count" =~ ^[0-9]+$ ]] && (( count > 0 )); then
    printf '%%{F#7fbbb3}%%{F-} %d\n' "$count"
  else
    printf '\n'
  fi
}

print_count
while IFS= read -r _; do
  print_count
done < <(i3-msg -t subscribe -m '["window"]' 2>/dev/null)
