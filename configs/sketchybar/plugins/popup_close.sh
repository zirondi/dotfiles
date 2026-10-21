#!/usr/bin/env bash
# Script of a bar item whose popup is built once in sketchybarrc (the Apple
# menu). Click: open or close the popup. Hover: plugins/item.sh.
# The popup also closes when the pointer leaves the bar and every popup
# (mouse.exited.global), or when another app takes focus. SketchyBar never
# sees clicks on other windows, so that is the only sign of a click elsewhere.
# shellcheck source=../lib/popup.sh
source "$CONFIG_DIR/lib/popup.sh"
case "$SENDER" in
  mouse.clicked)
    if popup_is_open "$NAME"; then
      popup_close "$NAME"
    else
      popup_close "$NAME"
      popup_open "$NAME"
    fi
    ;;
  mouse.entered | mouse.exited) exec "$CONFIG_DIR/plugins/item.sh" ;;
  mouse.exited.global | front_app_switched) popup_close "$NAME" ;;
esac
