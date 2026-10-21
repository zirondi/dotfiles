#!/usr/bin/env bash
# Starts the eww bar and dock (called by i3 on start and on reload).
#   launch.sh              (re)start eww with the bar and the dock
#   launch.sh toggle-bar   show or hide the bar ($mod+B, configs/design/KEYMAP.md)
# The bar is `edge` from each side of the monitor (configs/design/THEME.md, Bar
# shape). eww geometry has no "100% minus", so the width is computed here from
# eww's monitor 0 (the first one xrandr lists).
edge=8        # THEME.md edge
bar_height=32 # THEME.md bar-height

# Prints the --size option for the bar (nothing if xrandr fails: full width)
bar_size() {
  local width
  width="$(xrandr --listmonitors 2>/dev/null | awk 'NR == 2 { split($3, a, "/"); print a[1] }')"
  [ -n "$width" ] && echo "--size=$((width - 2 * edge))x$bar_height"
}

if [ "${1:-}" = "toggle-bar" ]; then
  # shellcheck disable=SC2046 # bar_size prints one word or nothing
  exec eww open --toggle bar $(bar_size)
fi

eww kill >/dev/null 2>&1
eww daemon
# Wait until the daemon answers, so the bar opens with its --size
for _ in $(seq 50); do eww ping >/dev/null 2>&1 && break; sleep 0.1; done
# shellcheck disable=SC2046
eww open bar $(bar_size)
eww open dock
