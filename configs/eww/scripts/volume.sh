#!/usr/bin/env bash
# Volume for the bar and its popup (twin of the SketchyBar volume item).
#   volume.sh              JSON: volume, icon and the output devices
#   volume.sh scroll up|down
#   volume.sh set <0-100>
#   volume.sh sink <name>  make it the default output and move playing streams
# Outputs whose description matches HIDDEN are left out of the popup (monitor
# HDMI audio, like the monitors hidden on macOS).
HIDDEN='HDMI|DisplayPort'

case "${1:-}" in
  scroll)
    [ "$2" = "up" ] && step="+2%" || step="-2%"
    pactl set-sink-volume @DEFAULT_SINK@ "$step"
    exit 0
    ;;
  set)
    pactl set-sink-volume @DEFAULT_SINK@ "$2%"
    exit 0
    ;;
  sink)
    pactl set-default-sink "$2"
    pactl list short sink-inputs | cut -f1 | xargs -r -I{} pactl move-sink-input {} "$2"
    exit 0
    ;;
esac

vol="$(pactl get-sink-volume @DEFAULT_SINK@ 2>/dev/null | grep -o '[0-9]*%' | head -1 | tr -d %)"
muted="$(pactl get-sink-mute @DEFAULT_SINK@ 2>/dev/null | grep -q yes && echo true || echo false)"
vol="${vol:-0}"
if [ "$muted" = "true" ] || [ "$vol" -eq 0 ]; then icon=""
elif [ "$vol" -lt 60 ]; then icon=""
else icon=""; fi

default="$(pactl get-default-sink 2>/dev/null)"
sinks="$(pactl list sinks 2>/dev/null | awk -v def="$default" -v hidden="$HIDDEN" '
  /^\tName: / {name = $2}
  /^\tDescription: / {sub(/^\tDescription: /, ""); if ($0 !~ hidden) printf "%s\t%s\t%s\n", name, $0, (name == def)}
' | jq -Rsc 'split("\n") | map(select(length > 0) | split("\t") | {name: .[0], desc: .[1], default: (.[2] == "1")})')"

jq -nc --argjson vol "$vol" --argjson muted "$muted" --arg icon "$icon" --argjson sinks "${sinks:-[]}" \
  '{vol: $vol, muted: $muted, icon: $icon, sinks: $sinks}'
