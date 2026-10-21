#!/usr/bin/env bash
# Apps for the eww dock as JSON, re-emitted on every i3 window event.
# Pinned apps (dock-pinned, one desktop id per line) come first, then any other
# running app. Clicking focuses a running app or launches it.
CONFIG_DIR="${CONFIG_DIR:-$HOME/.config/eww}"
PINNED="$CONFIG_DIR/dock-pinned"
DIRS=(/run/current-system/sw/share/applications /etc/profiles/per-user/"$USER"/share/applications "$HOME/.local/share/applications")

desktop_file() { # <id>
  local d
  for d in "${DIRS[@]}"; do [ -f "$d/$1.desktop" ] && echo "$d/$1.desktop" && return; done
}
field() { grep -m1 "^$2=" "$1" 2>/dev/null | cut -d= -f2-; }

emit() {
  local tree running focused out="[]" id file cls name icon is_run is_foc
  tree="$(i3-msg -t get_tree)"
  running="$(jq -r '[.. | objects | select(.window != null and .window_properties.class != null) | .window_properties.class | ascii_downcase] | unique | .[]' <<<"$tree")"
  focused="$(jq -r '[.. | objects | select(.focused == true and .window != null) | .window_properties.class // "" | ascii_downcase][0] // ""' <<<"$tree")"

  local seen=" "
  while IFS= read -r id; do
    [ -z "$id" ] && continue
    file="$(desktop_file "$id")"
    [ -z "$file" ] && continue
    cls="$(field "$file" StartupWMClass)"; cls="${cls:-$id}"; cls="${cls,,}"
    name="$(field "$file" Name)"; icon="$(field "$file" Icon)"
    is_run=false; grep -qxF "$cls" <<<"$running" && is_run=true
    is_foc=false; [ "$cls" = "$focused" ] && is_foc=true
    out="$(jq -c --arg id "$id" --arg cls "$cls" --arg name "$name" --arg icon "${icon:-$id}" --arg file "$file" \
      --argjson run "$is_run" --argjson foc "$is_foc" \
      '. + [{id: $id, cls: $cls, name: $name, icon: $icon, file: $file, running: $run, focused: $foc}]' <<<"$out")"
    seen="$seen$cls "
  done < "$PINNED"

  while IFS= read -r cls; do
    [ -z "$cls" ] && continue
    case "$seen" in *" $cls "*) continue ;; esac
    file="$(desktop_file "$cls")"
    name="$(field "$file" Name)"; icon="$(field "$file" Icon)"
    is_foc=false; [ "$cls" = "$focused" ] && is_foc=true
    out="$(jq -c --arg cls "$cls" --arg name "${name:-$cls}" --arg icon "${icon:-$cls}" --arg file "$file" \
      --argjson foc "$is_foc" \
      '. + [{id: $cls, cls: $cls, name: $name, icon: $icon, file: $file, running: true, focused: $foc}]' <<<"$out")"
  done <<<"$running"

  echo "$out"
}

# dock.sh open <class> <desktop-file>: focus the app if running, else launch it
if [ "${1:-}" = "open" ]; then
  if i3-msg -t get_tree | jq -e --arg c "$2" '[.. | objects | select(.window_properties.class? | ascii_downcase? == $c)] | length > 0' >/dev/null; then
    i3-msg "[class=\"(?i)^$2\$\"] focus" >/dev/null
  elif [ -n "${3:-}" ]; then
    dex "$3" >/dev/null 2>&1 &
  fi
  exit 0
fi

emit
i3-msg -t subscribe -m '["window"]' | while read -r _; do emit; done
