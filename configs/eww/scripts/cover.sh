#!/usr/bin/env bash
# Keeps the bars and the dock out of the way, per monitor. Started by
# launch.sh; listens to i3.
#   - A fullscreen window on a visible workspace covers its whole monitor, with
#     that monitor's bar behind it (configs/design/WINDOWS.md); the dock only
#     when it is the laptop screen. eww draws them outside i3 (wm-ignore), so
#     their "bg" stacking only holds when they open; i3 raises a fullscreen
#     window above them anyway.
#   - i3-nagbar (config errors and warnings) is drawn at the top of a monitor,
#     under its bar. It sets no WM_CLASS; it is found as a window in i3's dock
#     area, which nothing else here uses (eww is outside i3).
#   - The gaps kept for the bar (top) and the dock (right, laptop screen only)
#     depend on the monitor, and on $mod+B (soft fullscreen of one monitor).
#     i3 gaps are per workspace, so they are set on each workspace as it gets
#     focus.
# Only windows this script closed are reopened: a bar hidden with $mod+B stays
# hidden.
STATE="${XDG_RUNTIME_DIR:-/tmp}/eww-covered" # eww windows this script closed
SOFT="${XDG_RUNTIME_DIR:-/tmp}/eww-soft"     # monitors in soft fullscreen (launch.sh)
LAUNCH="$HOME/.config/eww/launch.sh"
gap_top=38   # configs/i3/config `gaps top`: room for the bar
gap_right=82 # room for the dock (74 px + `edge`), see configs/i3/config
PRIMARY="$("$LAUNCH" primary)"

# Monitors whose bar must hide, one per line
covered_outputs() {
  local visible
  visible="$(i3-msg -t get_workspaces | jq -c '[.[] | select(.visible) | .name]')"
  # Workspaces are themselves fullscreen (mode 1) inside their output, so only
  # containers count; mode 2 is global fullscreen and covers every monitor
  i3-msg -t get_tree | jq -r --argjson vis "$visible" '
    ([.. | objects | select(.fullscreen_mode? == 2)] | length > 0) as $global
    | .nodes[] | select(.type == "output" and .name != "__i3") as $o
    | select($global
        or ([$o | .. | objects | select(.type == "dockarea") | .nodes[]? | select(.window != null)] | length > 0)
        or ([$o | .. | objects | select(.type == "workspace" and (.name | IN($vis[])))
             | .. | objects | select(.type == "con" and .fullscreen_mode == 1)] | length > 0))
    | $o.name'
}

update_cover() {
  local want open w out
  want="$(covered_outputs | while read -r out; do
    echo "bar-$out"
    [ "$out" = "$PRIMARY" ] && echo dock
  done)"
  open="$(eww active-windows | cut -d: -f1)"
  touch "$STATE"
  # Hide what must hide and is showing
  for w in $want; do
    if grep -qxF "$w" <<<"$open"; then
      eww close "$w"
      echo "$w" >>"$STATE"
    fi
  done
  # Bring back what this script hid and is no longer covered
  while read -r w; do
    [ -z "$w" ] && continue
    grep -qxF "$w" <<<"$want" && continue
    if [ "$w" = dock ]; then "$LAUNCH" open-dock; else "$LAUNCH" open-bar "${w#bar-}"; fi
    sed -i "/^$w\$/d" "$STATE"
  done < <(sort -u "$STATE")
}

# Gaps of the focused workspace: room for its monitor's bar on top and, on the
# laptop screen, for the dock on the right; none in soft fullscreen. Set only
# when they change.
declare -A gap_of
update_gap() {
  local ws out top right
  read -r ws out < <(i3-msg -t get_workspaces | jq -r '.[] | select(.focused) | "\(.name) \(.output)"')
  [ -z "$ws" ] && return
  top=$gap_top right=0
  [ "$out" = "$PRIMARY" ] && right=$gap_right
  if grep -qxF "$out" "$SOFT" 2>/dev/null; then top=0 right=0; fi
  [ "${gap_of[$ws]:-}" = "$top $right" ] && return
  i3-msg "gaps top current set $top; gaps right current set $right" >/dev/null
  gap_of[$ws]="$top $right"
}

rm -f "$STATE"
update_cover
update_gap
# Events come in bursts: drain what is queued and check once. A "tick" from
# launch.sh ($mod+B) only asks for the gaps to be set again.
i3-msg -t subscribe -m '["window", "workspace", "tick"]' | while read -r ev; do
  [[ "$ev" == *'"payload":"refit"'* ]] && gap_of=()
  while read -r -t 0.05 _; do :; done
  update_cover
  update_gap
done
