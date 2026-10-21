#!/usr/bin/env bash
# Clock in the middle of the bar. Click: the month and the next events, every
# row clickable (opens Calendar there); Cmd+click: Calendar. Events come from
# the macOS Calendar database (icalBuddy), where the user's calendars already
# live; khal (Nextcloud via vdirsyncer) is the fallback, as on Linux.
# launchd starts SketchyBar without a locale, so LC_TIME is set here.
# Character-wise truncation needs a UTF-8 locale (launchd starts SketchyBar without one)
export LANG="${LANG:-en_US.UTF-8}"
# shellcheck source=../lib/popup.sh
source "$CONFIG_DIR/lib/popup.sh"
export LC_TIME=pt_BR.UTF-8
# Event rows are cut to this many characters; hovering scrolls the rest in
EVENT_CHARS=34

# Open Calendar on the day <offset> days from today, in week view
calendar_at() {
  echo "osascript -e 'tell application \"Calendar\"' -e 'activate' -e 'switch view to week view' -e 'view calendar at ((current date) + ($1 * days))' -e 'end tell'"
}

days_from_today() { # <dd> <mm>
  local y now day
  y="$(/bin/date '+%Y')"
  now="$(/bin/date -j -f '%Y-%m-%d %H:%M' "$(/bin/date '+%Y-%m-%d') 12:00" '+%s')"
  day="$(/bin/date -j -f '%Y-%m-%d %H:%M' "$y-$2-$1 12:00" '+%s' 2>/dev/null)" || { echo 0; return; }
  echo $(((day - now) / 86400))
}

# One line per week: "<offset of its first day>\t<row text>"
month_grid() {
  local first wday days d line today start
  first="$(/bin/date '+%Y-%m-01')"
  wday="$(/bin/date -j -f '%Y-%m-%d' "$first" '+%w')" # 0 = Sunday, Brazilian week
  days="$(/bin/date -j -v+1m -v-1d -f '%Y-%m-%d' "$first" '+%d')"
  today="$(/bin/date '+%-d')"
  line="$(printf '%*s' $((wday * 4)) '')"
  start=1
  for ((d = 1; d <= 10#$days; d++)); do
    if [ "$d" -eq "$today" ]; then line+="$(printf '[%2d]' "$d")"; else line+="$(printf ' %2d ' "$d")"; fi
    if [ $(((wday + d) % 7)) -eq 0 ] || [ "$d" -eq $((10#$days)) ]; then
      printf '%d\t%s\n' $((start - today)) "$line"
      line="" start=$((d + 1))
    fi
  done
}

# Next events: "<dd/mm>  <HH:MM>  <title>"
events() {
  if [ -x /opt/homebrew/bin/icalBuddy ]; then
    /opt/homebrew/bin/icalBuddy -n -nc -nrd -b "" -iep "datetime,title" -po "datetime,title" \
      -ps "| |" -df "%d/%m" -tf "%H:%M" -li 8 eventsToday+6 2>/dev/null |
      sed -E 's/^([0-9]+\/[0-9]+) at ([0-9:]+)( - [0-9:]+)? (.*)$/\1  \2  \4/'
  elif command -v khal >/dev/null && ls ~/.local/share/vdirsyncer/calendars/*/ >/dev/null 2>&1; then
    khal list today 6d --format '{start-date}  {start-time}  {title}' --day-format '' 2>/dev/null | sed '/^$/d' | head -8
  fi
}

# Panel (SURFACES.md): month header, week rows, next events, Open Calendar
build_popup() {
  # Put the lit row back to rest first: removing a row while its scroll is
  # still animating would leave the animation pointing at a freed item
  popup_close "$NAME"
  # SketchyBar's item regex has no (a|b) alternation: one pattern per prefix
  sketchybar --remove '/clock\.row\..*/' --remove '/clock\.act\..*/' \
    --remove '/clock\.ev\..*/' --remove '/clock\.sep.*/' >/dev/null 2>&1
  local title i=0 offset row ev d m
  title="$(/bin/date '+%B de %Y')"
  popup_header clock row.title "${title^}"
  popup_text clock row.days "  D   S   T   Q   Q   S   S"
  while IFS=$'\t' read -r offset row; do
    popup_entry clock "row.w$i" "" "$row" "$(calendar_at "$offset")"
    popup_no_icon "clock.row.w$i"
    i=$((i + 1))
  done < <(month_grid)

  i=0
  while IFS= read -r ev; do
    [ -z "$ev" ] && continue
    if [ "$i" -eq 0 ]; then
      popup_separator clock sep.ev
      popup_header clock row.evhead "Next days"
    fi
    d="${ev:0:2}" m="${ev:3:2}"
    popup_entry clock "ev.e$i" "" "$ev" "$(calendar_at "$(days_from_today "$d" "$m")")"
    popup_scroll "clock.ev.e$i" "$ev" "$EVENT_CHARS"
    i=$((i + 1))
  done < <(events)

  popup_separator clock sep.act
  popup_entry clock act.open "" "Open Calendar" "open -a Calendar"
  popup_end clock
}

case "$SENDER" in
  mouse.clicked)
    if [ "$MODIFIER" = "cmd" ]; then
      open -a Calendar
    elif popup_is_open "$NAME"; then
      popup_close "$NAME"
    else
      build_popup
      popup_open "$NAME"
    fi
    ;;
  mouse.entered | mouse.exited) exec "$CONFIG_DIR/plugins/item.sh" ;;
  # Pointer left the bar and the popups, or a click went to another app
  # (see popup_close.sh)
  mouse.exited.global | front_app_switched) popup_close "$NAME" ;;
  *) sketchybar --set "$NAME" label="$(/bin/date '+%a %d/%m  %H:%M')" ;;
esac
