#!/usr/bin/env bash
# Hover on bar buttons (configs/design/THEME.md, "Bar items"): `hover` behind
# the item while the pointer is over it, `selected` while its popup is open
# (lib/popup.sh, item_color). Items with their own script hand
# mouse.entered / mouse.exited over to this one.
#
# Runs under the same lock as hover.sh for the item, so a hover event and the
# popup closing (which repaints the item too) never interleave.
# shellcheck source=../lib/popup.sh
source "${CONFIG_DIR:-$HOME/.config/sketchybar}/lib/popup.sh"

if [ -z "$POPUP_LOCKED" ]; then
  export POPUP_LOCKED=1
  exec /usr/bin/lockf -k -t 3 "$POPUP_STATE/${NAME%%.*}.lock" "$0" "$@"
fi

case "$SENDER" in
  mouse.entered) : >"$POPUP_STATE/$NAME.hover" ;;
  mouse.exited) rm -f "$POPUP_STATE/$NAME.hover" ;;
  *) exit 0 ;;
esac
sketchybar --set "$NAME" background.color="$(item_color "$NAME")"
