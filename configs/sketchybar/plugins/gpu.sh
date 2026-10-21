#!/usr/bin/env bash
# Apple GPU use, from IOKit (no sudo needed)
case "$SENDER" in
  mouse.entered | mouse.exited) exec "$CONFIG_DIR/plugins/item.sh" ;;
esac
pct="$(ioreg -r -d 1 -c IOAccelerator | grep -o '"Device Utilization %"=[0-9]*' | head -1 | cut -d= -f2)"
sketchybar --set "$NAME" label="${pct:-0}%"
