#!/usr/bin/env bash
# Now playing (MPRIS), same rules as configs/sketchybar/plugins/media.sh:
# music shows "artist — title"; browser videos with no album show only the
# channel. Emits one JSON line per change.
MAX=40
emit() {
  local status="$1" player="$2" artist="$3" album="$4" title="$5" icon text
  if [ -z "$status" ] || [ "$status" = "Stopped" ]; then
    echo '{"show": false, "icon": "", "text": ""}'
    return
  fi
  if [ "$status" = "Playing" ]; then icon=""; else icon=""; fi
  case "$player" in
    *zen* | *firefox* | *chromium* | *chrome* | *helium*)
      if [ -z "$album" ]; then icon="󰕧" text="${artist:-Video}"; fi ;;
  esac
  [ -z "${text:-}" ] && text="${artist:+$artist — }$title"
  [ "${#text}" -gt "$MAX" ] && text="${text:0:$((MAX - 1))}…"
  jq -nc --arg icon "$icon" --arg text "$text" '{show: true, icon: $icon, text: $text}'
}

emit ""
playerctl --follow metadata --format $'{{status}}\t{{playerName}}\t{{artist}}\t{{album}}\t{{title}}' 2>/dev/null |
  while IFS=$'\t' read -r status player artist album title; do
    emit "$status" "$player" "$artist" "$album" "$title"
  done
