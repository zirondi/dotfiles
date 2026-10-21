#!/usr/bin/env bash
# Total CPU use across all cores
case "$SENDER" in
  mouse.entered | mouse.exited) exec "$CONFIG_DIR/plugins/item.sh" ;;
esac
cores="$(sysctl -n hw.ncpu)"
pct="$(ps -A -o %cpu= | awk -v n="$cores" '{s += $1} END {printf "%d", s / n}')"
sketchybar --set "$NAME" label="$pct%"
