#!/usr/bin/env bash
# The month grid of the clock panel (configs/design/SURFACES.md, `panel`),
# drawn by eww instead of GTK's calendar, whose cells can't be sized.
#   calendar.sh [YYYY-MM]        print the month as JSON (default: this month)
#   calendar.sh show [YYYY-MM]   put it in the eww variable `cal`
# JSON: {title, prev, next, weekdays, weeks: [[{d, c}]]}, with c = "out" for
# days of the neighbouring months and "today" for today. Weeks start on
# Sunday, as in Brazilian calendars.
set -euo pipefail

if [ "${1:-}" = "show" ]; then
  eww update cal="$("$0" "${2:-}")"
  exit 0
fi

month="${1:-$(date +%Y-%m)}"
first="$month-01"
today="$(date +%F)"
title="$(LC_TIME=pt_BR.UTF-8 date -d "$first" '+%B %Y')"
title="${title^}"
prev="$(date -d "$first -1 month" +%Y-%m)"
next="$(date -d "$first +1 month" +%Y-%m)"

# Start on the Sunday on or before the 1st; stop after the week holding the
# month's last day.
day="$(date -d "$first -$(date -d "$first" +%w) days" +%F)"
weeks=""
while :; do
  week=""
  for _ in 1 2 3 4 5 6 7; do
    c=""
    [ "${day:0:7}" != "$month" ] && c="out"
    [ "$day" = "$today" ] && c="today"
    week+="${week:+,}{\"d\":\"$((10#${day:8:2}))\",\"c\":\"$c\"}"
    day="$(date -d "$day +1 day" +%F)"
  done
  weeks+="${weeks:+,}[$week]"
  [ "${day:0:7}" != "$month" ] && break
done

printf '{"title":"%s","prev":"%s","next":"%s","weekdays":["D","S","T","Q","Q","S","S"],"weeks":[%s]}\n' \
  "$title" "$prev" "$next" "$weeks"
