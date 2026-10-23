#!/usr/bin/env bash
# Shows the focused app's menus (File, Edit, ...) as menu.0 … menu.13.
# sketchybar-menus (pkgs/sketchybar-menus) needs SketchyBar to have
# Accessibility; without it only the app name ($INFO) is shown.
# In a browser, menu.0 (the app name) shows the current tab's title instead,
# refreshed every few seconds (routine updates) since tab switches send no event.
# Character-wise truncation needs a UTF-8 locale (launchd starts SketchyBar without one)
export LANG="${LANG:-en_US.UTF-8}"
MAX=14
TITLE_MAX=40
BROWSERS='Zen|Helium|Google Chrome|Chromium|Safari|Firefox|Arc'

# lsappinfo knows the real frontmost app (a system dialog can own the
# frontmost window): its first line is "<Name>" ASN:..., and a later one "pid = N"
front_info() { lsappinfo info "$(lsappinfo front)"; }
front_app() { front_info | head -1 | sed -E 's/^"([^"]*)".*/\1/'; }
front_pid() { front_info | sed -nE 's/^ *pid = ([0-9]+).*/\1/p' | head -1; }
menus() { sketchybar-menus -p "$(front_pid)" "$@"; }

browser_title() {
  local t
  t="$(menus -t 2>/dev/null)"
  [ -z "$t" ] && return 1
  [ "${#t}" -gt "$TITLE_MAX" ] && t="${t:0:$((TITLE_MAX - 1))}…"
  echo "$t"
}

# Click on menu.N: open that menu of the frontmost app
if [ "${1:-}" = "click" ]; then
  menus -s "$2"
  exit 0
fi

# Routine tick: only the browser tab title can change; leave the menus alone
if [ "$SENDER" = "routine" ] || [ "$SENDER" = "forced" ]; then
  if [[ "$(front_app)" =~ ^($BROWSERS)$ ]] && t="$(browser_title)"; then
    # Only when the title changed: every --set redraws the bar. The last
    # title is kept in a file; reading it back with --query broke jq on
    # titles with special characters, which SketchyBar does not escape.
    last="${TMPDIR:-/tmp}/sketchybar-menu0-title"
    if [ "$(cat "$last" 2>/dev/null)" != "$t" ]; then
      printf '%s' "$t" > "$last"
      sketchybar --set menu.0 label="$t"
    fi
  fi
  exit 0
fi

sleep 0.15 # let the new app publish its menu bar
args=()
i=0
# Some apps (kitty) add the window title to the menu bar as one more item;
# skip it, the title is not a menu
trim() { local t="$1"; t="${t#"${t%%[![:space:]]*}"}"; echo "${t%"${t##*[![:space:]]}"}"; }
window_title="$(trim "$(menus -t 2>/dev/null)")"
while IFS= read -r title; do
  [ "$i" -ge "$MAX" ] && break
  [ -z "$title" ] && continue
  # The window-title item (kitty prefixes it with " :: "): match on "contains";
  # short titles are ignored so a real menu named like a window is never hidden
  [ "${#window_title}" -gt 3 ] && [[ "$title" == *"$window_title"* ]] && continue
  args+=(--set "menu.$i" drawing=on label="$title")
  i=$((i + 1))
done < <(menus -l 2>/dev/null)

if [ "$i" -gt 0 ] && [[ "$INFO" =~ ^($BROWSERS)$ ]] && t="$(browser_title)"; then
  args+=(--set menu.0 label="$t")
  printf '%s' "$t" > "${TMPDIR:-/tmp}/sketchybar-menu0-title"
else
  rm -f "${TMPDIR:-/tmp}/sketchybar-menu0-title"
fi
if [ "$i" -eq 0 ] && [ -n "$INFO" ]; then
  args+=(--set menu.0 drawing=on label="$INFO")
  i=1
fi
while [ "$i" -lt "$MAX" ]; do
  args+=(--set "menu.$i" drawing=off)
  i=$((i + 1))
done

sketchybar "${args[@]}"
