#!/usr/bin/env bash
# Battery as JSON (hidden in the bar when there is none)
b="$(ls -d /sys/class/power_supply/BAT* 2>/dev/null | head -1)"
if [ -z "$b" ]; then
  echo '{"show": false}'
  exit 0
fi
pct="$(cat "$b/capacity")"
status="$(cat "$b/status")"
icons=("" "" "" "" "")
icon="${icons[$((pct > 95 ? 4 : pct / 20))]}"
class=""
[ "$pct" -le 20 ] && class="low"
[ "$pct" -le 10 ] && class="crit"
case "$status" in Charging | Full) icon="" class="charging" ;; esac
jq -nc --argjson pct "$pct" --arg icon "$icon" --arg status "$status" --arg class "$class" \
  '{show: true, pct: $pct, icon: $icon, status: $status, class: $class}'
