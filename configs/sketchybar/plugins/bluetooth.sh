#!/usr/bin/env bash
# Bluetooth power state; `toggle` switches it (blueutil)
# shellcheck source=../colors.sh
source "$CONFIG_DIR/colors.sh"

case "$SENDER" in
  mouse.entered | mouse.exited) exec "$CONFIG_DIR/plugins/item.sh" ;;
esac
[ "$1" = "toggle" ] && blueutil --power toggle

if [ "$(blueutil --power)" = "1" ]; then
  sketchybar --set "$NAME" icon="󰂯" icon.color="$FG"
else
  sketchybar --set "$NAME" icon="󰂲" icon.color="$FG_DIM"
fi
