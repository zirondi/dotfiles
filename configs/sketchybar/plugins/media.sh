#!/usr/bin/env bash
# Now playing through media-control (works around the macOS 15.4+ MediaRemote
# lock); hidden when nothing is playing or paused.
# Music shows "artist — title". Videos (a browser with no album, e.g. YouTube
# but not YouTube Music) show only the channel, so long titles stay out.
# Character-wise truncation needs a UTF-8 locale (launchd starts SketchyBar without one)
export LANG="${LANG:-en_US.UTF-8}"
MAX=40

case "$SENDER" in
  mouse.entered | mouse.exited) exec "$CONFIG_DIR/plugins/item.sh" ;;
esac

info="$(media-control get 2>/dev/null)"
title="$(jq -r '.title // empty' <<<"$info" 2>/dev/null)"
if [ -z "$title" ]; then
  sketchybar --set "$NAME" drawing=off
  exit 0
fi

artist="$(jq -r '.artist // empty' <<<"$info")"
album="$(jq -r '.album // empty' <<<"$info")"
app="$(jq -r '.bundleIdentifier // empty' <<<"$info")"
playing="$(jq -r '.playing' <<<"$info")"

case "$app" in
  *zen* | *helium* | *chrome* | *chromium* | *safari* | *firefox* | *arc*) browser=1 ;;
  *) browser=0 ;;
esac

if [ "$browser" = 1 ] && [ -z "$album" ]; then
  icon="󰕧"
  text="${artist:-Video}"
else
  if [ "$playing" = "true" ]; then icon=""; else icon=""; fi
  text="${artist:+$artist — }$title"
fi
[ "${#text}" -gt "$MAX" ] && text="${text:0:$((MAX - 1))}…"

sketchybar --set "$NAME" drawing=on icon="$icon" label="$text"
