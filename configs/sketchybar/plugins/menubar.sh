#!/usr/bin/env bash
# Swaps SketchyBar and the native menu bar. The native one is needed for app
# icons, which SketchyBar cannot mirror on macOS 27. Bound to $mod+B by a
# Karabiner rule (configs/design/KEYMAP.md); the button in the bar does the same.
# While AeroSpace misbehaves, the native bar also turns AeroSpace off, giving
# back macOS's own window behaviour (snap, tiling); SketchyBar turns it back on.
# A disabled AeroSpace ignores its own bindings, hence Karabiner.
#   menubar.sh toggle   swap bars
#   menubar.sh show     switch to the native menu bar
# Karabiner runs this with a bare PATH
PATH="/opt/homebrew/bin:$PATH"

autohide() {
  osascript -e "tell application \"System Events\" to $1 autohide menu bar of dock preferences${2:+ to $2}"
}

native() {
  autohide set false
  sketchybar --bar hidden=on
  aerospace enable off
}
sketchy() {
  aerospace enable on
  autohide set true
  sketchybar --bar hidden=off
}

case "$1" in
  toggle) if [ "$(autohide get)" = "true" ]; then native; else sketchy; fi ;;
  show) native ;; # native menu bar, e.g. to reach an app's icon
esac
