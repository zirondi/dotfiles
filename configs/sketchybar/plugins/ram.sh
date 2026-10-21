#!/usr/bin/env bash
# Memory in use (active + wired + compressed), as macOS Activity Monitor counts it
case "$SENDER" in
  mouse.entered | mouse.exited) exec "$CONFIG_DIR/plugins/item.sh" ;;
esac
total="$(sysctl -n hw.memsize)"
pct="$(vm_stat | awk -v total="$total" '
  /page size of/ {size = $8}
  /Pages active/ {used += $3}
  /Pages wired down/ {used += $4}
  /Pages occupied by compressor/ {used += $5}
  END {printf "%d", used * size * 100 / total}')"
sketchybar --set "$NAME" label="$pct%"
