#!/usr/bin/env bash
# Next events for the calendar popup as a JSON list of lines (khal over the
# vdirsyncer copy of the Nextcloud calendars). Empty until the calendars are
# set up, so the popup shows no events section (same rule as SketchyBar).
ls ~/.local/share/vdirsyncer/calendars/*/ >/dev/null 2>&1 || { echo "[]"; exit 0; }
khal list today 6d --format '{start-date}  {start-time}  {title}' --day-format '' 2>/dev/null |
  sed '/^$/d' | head -8 | jq -Rsc 'split("\n") | map(select(length > 0))'
