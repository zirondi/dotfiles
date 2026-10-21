#!/usr/bin/env bash
# Battery on a MacBook; on machines without one (macmini) the same item shows
# the whole system's power draw instead, from the SMC through macmon (no sudo)
# shellcheck source=../colors.sh
source "$CONFIG_DIR/colors.sh"

info="$(pmset -g batt)"
if ! grep -q InternalBattery <<<"$info"; then
  watts="$(macmon pipe -s 1 -i 500 2>/dev/null | jq -r '.sys_power // empty' | awk '{printf "%.1f", $1}')"
  # Power changes faster than the battery: refresh every 10 s
  sketchybar --set "$NAME" drawing=on update_freq=10 icon="󰚥" icon.color="$ACCENT_2" \
    label="${watts:-?} W"
  exit 0
fi

pct="$(grep -Eo '[0-9]+%' <<<"$info" | head -1 | tr -d '%')"
color="$FG"
case "$pct" in
  100 | 9[0-9]) icon="" ;;
  [6-8][0-9]) icon="" ;;
  [3-5][0-9]) icon="" ;;
  [1-2][0-9]) icon=""; color="$YELLOW" ;;
  *) icon=""; color="$RED" ;;
esac
if grep -q 'AC Power' <<<"$info"; then
  icon=""
  color="$GREEN"
fi

sketchybar --set "$NAME" drawing=on icon="$icon" icon.color="$color" label="$pct%"
