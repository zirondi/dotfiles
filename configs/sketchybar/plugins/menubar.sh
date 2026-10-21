#!/usr/bin/env bash
# Swaps SketchyBar and the native menu bar. The native one is needed for app
# icons, which SketchyBar cannot mirror on macOS 27. Bound to $mod+B in
# AeroSpace (configs/design/KEYMAP.md); the button in the bar does the same.
#   menubar.sh toggle   swap bars
#   menubar.sh show     switch to the native menu bar
autohide() {
  osascript -e "tell application \"System Events\" to $1 autohide menu bar of dock preferences${2:+ to $2}"
}

native() {
  autohide set false
  sketchybar --bar hidden=on
}
sketchy() {
  autohide set true
  sketchybar --bar hidden=off
}

case "$1" in
  toggle) if [ "$(autohide get)" = "true" ]; then native; else sketchy; fi ;;
  show) native ;; # native menu bar, e.g. to reach an app's icon
esac
