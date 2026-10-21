#!/usr/bin/env bash
# Starts the eww bars and dock (called by i3 on start and on reload, and by
# scripts/displays.sh after a layout change).
#   launch.sh                 (re)start eww: one bar per monitor, the dock on
#                             the laptop screen
#   launch.sh toggle-bar      soft fullscreen of the focused monitor: hide or
#                             show its bar (and the dock on the laptop screen)
#                             and the i3 gaps kept for them ($mod+B)
#   launch.sh open-bar <out>  open the bar of one monitor (scripts/cover.sh)
#   launch.sh open-dock       open the dock (scripts/cover.sh)
#   launch.sh primary         print the monitor that holds the dock
# A bar is `edge` from each side of its monitor (configs/design/THEME.md, Bar
# shape). eww geometry has no "100% minus", so each width is computed here.
# The laptop screen is always the primary one: it holds the dock, and only
# its workspaces keep the right gap for it (scripts/cover.sh sets that gap).
edge=8        # THEME.md edge
bar_height=32 # THEME.md bar-height
SOFT="${XDG_RUNTIME_DIR:-/tmp}/eww-soft" # monitors in soft fullscreen, one per line

# Active monitors as "<name> <width>"
monitors() { xrandr --listmonitors 2>/dev/null | awk 'NR > 1 { split($3, a, "/"); print $4, a[1] }'; }

# The laptop screen (eDP), or the first monitor when it is off
primary() {
  local m
  m="$(monitors | awk '$1 ~ /^eDP/ { print $1; exit }')"
  [ -z "$m" ] && m="$(monitors | awk 'NR == 1 { print $1 }')"
  echo "$m"
}

open_bar() { # <monitor>
  local width
  width="$(monitors | awk -v m="$1" '$1 == m { print $2 }')"
  [ -z "$width" ] && return
  # </dev/null: called in `while read` loops, eww must not eat their input
  eww open bar --id "bar-$1" --arg "monitor=$1" --size "$((width - 2 * edge))x$bar_height" </dev/null
}

open_dock() { eww open dock --arg "monitor=$(primary)"; }

case "${1:-}" in
  toggle-bar)
    out="$(i3-msg -t get_workspaces | jq -r '.[] | select(.focused) | .output')"
    if eww active-windows | grep -q "^bar-$out:"; then
      eww close "bar-$out"
      [ "$out" = "$(primary)" ] && eww close dock
      echo "$out" >>"$SOFT"
    else
      open_bar "$out"
      [ "$out" = "$(primary)" ] && open_dock
      sed -i "/^$out\$/d" "$SOFT" 2>/dev/null
    fi
    # cover.sh sets the gaps of that monitor's workspaces again
    i3-msg -t send_tick refit >/dev/null
    exit 0
    ;;
  open-bar) open_bar "$2"; exit 0 ;;
  open-dock) open_dock; exit 0 ;;
  primary) primary; exit 0 ;;
esac

eww kill >/dev/null 2>&1
eww daemon
# Wait until the daemon answers, so the bars open with their --size
for _ in $(seq 50); do eww ping >/dev/null 2>&1 && break; sleep 0.1; done
rm -f "$SOFT"
monitors | while read -r name _; do open_bar "$name"; done
open_dock

# Hide bars and dock under fullscreen windows and i3-nagbar, and keep the
# dock's gap on the laptop's workspaces; one listener, restarted with eww
pkill -u "$USER" -f '^bash .*/eww/scripts/cover\.sh$' >/dev/null 2>&1
setsid -f "$HOME/.config/eww/scripts/cover.sh" >/dev/null 2>&1
