#!/usr/bin/env bash
# Apps for the eww dock as JSON, re-emitted on i3 window events.
# Pinned apps (dock-pinned, one desktop id per line) come first, then any other
# running app. Clicking focuses a running app or launches it; right-click
# opens the dock menu (New Window or Open, Keep in / Remove from Dock, Quit).
CONFIG_DIR="${CONFIG_DIR:-$HOME/.config/eww}"
PINNED="$CONFIG_DIR/dock-pinned"
DIRS=(/run/current-system/sw/share/applications /etc/profiles/per-user/"$USER"/share/applications "$HOME/.local/share/applications")

desktop_file() { # <id>
  local d
  for d in "${DIRS[@]}"; do [ -f "$d/$1.desktop" ] && echo "$d/$1.desktop" && return; done
}
field() { grep -m1 "^$2=" "$1" 2>/dev/null | cut -d= -f2-; }

# One row per app, tab-separated: id, class, name, icon, desktop file
row() { printf '%s\t%s\t%s\t%s\t%s\n' "$1" "$2" "$3" "$4" "$5"; }

emit() { # [JSON array of window ids being closed, still in the tree]
  local closing="${1:-[]}" tree running focused rows="" seen=" " id file cls name icon
  tree="$(i3-msg -t get_tree)"
  # Line 1: the focused class; then one running class per line
  running="$(jq -r --argjson closing "$closing" '
    ([.. | objects | select(.focused == true and .window != null) | .window_properties.class // "" | ascii_downcase][0] // ""),
    ([.. | objects | select(.window != null and (.window | IN($closing[]) | not) and .window_properties.class != null)
      | .window_properties.class | ascii_downcase] | unique | .[])' <<<"$tree")"
  focused="$(head -n1 <<<"$running")"
  running="$(tail -n +2 <<<"$running")"

  while IFS= read -r id; do
    [ -z "$id" ] && continue
    file="$(desktop_file "$id")"
    [ -z "$file" ] && continue
    cls="$(field "$file" StartupWMClass)"; cls="${cls:-$id}"; cls="${cls,,}"
    name="$(field "$file" Name)"; icon="$(field "$file" Icon)"
    rows+="$(row "$id" "$cls" "$name" "${icon:-$id}" "$file")"$'\n'
    seen="$seen$cls "
  done < "$PINNED"

  while IFS= read -r cls; do
    [ -z "$cls" ] && continue
    case "$seen" in *" $cls "*) continue ;; esac
    file="$(desktop_file "$cls")"
    name="$(field "$file" Name)"; icon="$(field "$file" Icon)"
    rows+="$(row "$cls" "$cls" "${name:-$cls}" "${icon:-$cls}" "$file")"$'\n'
  done <<<"$running"

  jq -Rnc --arg running "$running" --arg focused "$focused" '
    ($running | split("\n")) as $run
    | [inputs | select(. != "") | split("\t")
       | {id: .[0], cls: .[1], name: .[2], icon: .[3], file: .[4],
          running: (.[1] as $c | $run | index($c) != null), focused: (.[1] == $focused)}]' <<<"$rows"
}

# eww grows a window to fit new content but never shrinks it (X11), so a
# shorter list leaves an empty slot at the end of the dock. Reopening the
# window lays it out again at its natural size. The list is written first
# with `eww update`, which returns once the daemon holds it: reopening on a
# timer alone sometimes beat the listener's update and reopened at the old
# size. Detached, because closing the dock also stops this listener.
reopen() { # <dock JSON>
  # shellcheck disable=SC2016 # $1 expands in the inner sh
  setsid -f sh -c 'cd /; eww update dock_apps="$1"; eww close dock; eww open dock' sh "$1" >/dev/null 2>&1
}

case "${1:-}" in
  # dock.sh open <class> <desktop-file>: focus the app if running, else launch it
  open)
    if i3-msg -t get_tree | jq -e --arg c "$2" '[.. | objects | select(.window_properties.class? | ascii_downcase? == $c)] | length > 0' >/dev/null; then
      i3-msg "[class=\"(?i)^$2\$\"] focus" >/dev/null
    elif [ -n "${3:-}" ]; then
      dex "$3" >/dev/null 2>&1 &
    fi
    exit 0
    ;;

  # dock.sh refresh: redraw after the pinned list changed (no window event)
  refresh)
    prev="$(eww get dock_apps | jq length)"
    out="$(emit)"
    eww update dock_apps="$out"
    [ "$(jq length <<<"$out")" -lt "${prev:-0}" ] && reopen "$out"
    exit 0
    ;;

  # dock.sh menu <id> <class> <desktop-file> <running>: the `dock-menu` surface
  # (configs/design/SURFACES.md), drawn by rofi at the pointer
  menu)
    id="$2" cls="$3" file="$4" running="$5"
    pgrep -u "$USER" -f 'rofi .*menu\.rasi' >/dev/null && exit 0
    name="$(field "$file" Name)"
    pinned=false; grep -qxF "$id" "$PINNED" && pinned=true
    rows=()
    if [ "$running" = true ]; then rows+=("New Window"); else rows+=("Open"); fi
    if $pinned; then rows+=("Remove from Dock"); elif [ -n "$file" ]; then rows+=("Keep in Dock"); fi
    [ "$running" = true ] && rows+=("Quit")
    choice="$(printf '%s\n' "${rows[@]}" |
      rofi -dmenu -theme "$HOME/.config/rofi/menu.rasi" -monitor -3 -no-custom \
        -mesg "<b>${name:-$cls}</b>")"
    case "$choice" in
      "New Window" | Open) [ -n "$file" ] && dex "$file" >/dev/null 2>&1 & ;;
      "Keep in Dock") basename "$file" .desktop >>"$PINNED" && exec "$0" refresh ;;
      "Remove from Dock")
        # Rewrite in place: dock-pinned is a link into the repo (configs/eww)
        rest="$(grep -vxF "$id" "$PINNED")"
        printf '%s\n' "$rest" >"$PINNED"
        exec "$0" refresh
        ;;
      Quit) i3-msg "[class=\"(?i)^$cls\$\"] kill" >/dev/null ;;
    esac
    exit 0
    ;;
esac

# Listener. i3 sends window::close before it removes the window from the
# tree, so the closing window is left out by its id. Events come in bursts
# (new, focus, title...): drain what is queued and redraw once, so the dock
# never lags behind the windows. Title changes do not affect it.
closing_ids() { jq -r 'if .change == "close" then .container.window // empty else empty end' <<<"$1"; }

out="$(emit)"
echo "$out"
# Largest list drawn since the dock was last opened: the window never
# shrinks by itself, so any shorter list needs a reopen
widest="$(jq length <<<"$out")"
i3-msg -t subscribe -m '["window"]' | while read -r ev; do
  case "$ev" in *'"change":"title"'*) continue ;; esac
  ids="$(closing_ids "$ev")"
  while read -r -t 0.05 more; do ids+=$'\n'"$(closing_ids "$more")"; done
  out="$(emit "$(jq -Rnc '[inputs | select(. != "") | tonumber]' <<<"$ids")")"
  echo "$out"
  n="$(jq length <<<"$out")"
  if [ "$n" -lt "$widest" ]; then
    reopen "$out"
    widest="$n"
  elif [ "$n" -gt "$widest" ]; then
    widest="$n"
  fi
done
