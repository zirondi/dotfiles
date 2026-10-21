#!/usr/bin/env bash
# Workspace pill (THEME.md, "Bar items"): hidden when empty, `accent-2` text
# when it has windows, `accent` background and text-strong when focused,
# `hover` background under the pointer (focused wins). No urgent state: macOS
# gives no urgency data (CAPABILITIES.md).
# shellcheck source=../lib/popup.sh
source "$CONFIG_DIR/lib/popup.sh"

sid="$1"
case "$SENDER" in
  mouse.entered) : >"$POPUP_STATE/$NAME.hover" ;;
  mouse.exited) rm -f "$POPUP_STATE/$NAME.hover" ;;
esac
focused="${FOCUSED_WORKSPACE:-$(aerospace list-workspaces --focused 2>/dev/null)}"

if [ "$sid" = "$focused" ]; then
  sketchybar --set "$NAME" drawing=on background.color="$ACCENT" \
    label.color="$FG" label.font="$TEXT_STRONG"
elif [ -n "$(aerospace list-windows --workspace "$sid" 2>/dev/null)" ]; then
  sketchybar --set "$NAME" drawing=on background.color="$(item_color "$NAME")" \
    label.color="$ACCENT_2" label.font="$TEXT"
else
  rm -f "$POPUP_STATE/$NAME.hover"
  sketchybar --set "$NAME" drawing=off
fi
