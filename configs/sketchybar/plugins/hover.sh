#!/usr/bin/env bash
# Popup rows (lib/popup.sh): the row under the pointer is lit and, if its label
# is cut, scrolls the rest into view; leaving puts it back to rest at once.
# States (configs/design/SURFACES.md): at rest a row has no background, or
# `selected` when it is the current choice; lit it has `hover` (`selected`
# wins); a destructive row turns its text `red` while lit.
#
# Senders: mouse.entered / mouse.exited (rows), popup.close (popup_close and
# row clicks; NAME is then the popup's item). Argument "text": a header row,
# entering it only clears the lit row.
#
# SketchyBar runs every event script asynchronously, so the scripts of a quick
# pass (enter A, exit A, enter B) can finish out of order and leave a row lit
# after the pointer left. The events of one popup are therefore handled one at
# a time (lockf) and in the order SketchyBar sent them: it vforks each script
# in turn, so a lower PID is an older event, dropped once a newer one ran.
# Only the row in "$parent.lit" is ever away from rest, so leaving any other
# row needs no work.
#
# Scrolling animates label.padding_left instead of using scroll_texts: a
# scroll_texts pass is an animation chain on the text's scroll offset that no
# command can cancel (src/text.c, text_animate_scroll), so it kept running
# after the pointer left. A plain --set of the padding cancels its animation.
# shellcheck source=../lib/popup.sh
source "${CONFIG_DIR:-$HOME/.config/sketchybar}/lib/popup.sh"
parent="${NAME%%.*}"

if [ -z "$POPUP_LOCKED" ]; then
  export POPUP_LOCKED=1 POPUP_SEQ="${POPUP_SEQ:-$$}"
  exec /usr/bin/lockf -k -t 3 "$POPUP_STATE/$parent.lock" "$0" "$@"
fi

older() { # <pid> <file>: the pid is older than the one in the file (allowing for the counter wrapping)
  local last
  last="$(cat "$2" 2>/dev/null)"
  [ "$1" -lt "${last:-0}" ] && [ $((last - $1)) -lt 50000 ]
}
seq_file="$POPUP_STATE/$parent.seq"   # last row event or close
close_file="$POPUP_STATE/$parent.close" # last close (popup_close also runs before every open)
lit_file="$POPUP_STATE/$parent.lit"
if [ "$SENDER" = popup.close ]; then
  # A close is only stale next to a newer open, never next to row events: the
  # exit that closes a popup is sent just before the rows' own exits
  older "$POPUP_SEQ" "$close_file" && exit 0
  echo "$POPUP_SEQ" >"$close_file"
  older "$POPUP_SEQ" "$seq_file" || echo "$POPUP_SEQ" >"$seq_file"
else
  older "$POPUP_SEQ" "$seq_file" && exit 0
  echo "$POPUP_SEQ" >"$seq_file"
fi
lit="$(cat "$lit_file" 2>/dev/null)"

args=()
kind() { cat "$POPUP_STATE/$1.kind" 2>/dev/null; }

rest() { # <row>: the --set that puts the row back to rest
  local cut full base bg="$NONE"
  case "$(kind "$1")" in
    selected) bg="$SELECTED" ;;
    destructive) args+=(--set "$1" icon.color="$FG" label.color="$FG") ;;
  esac
  args+=(--set "$1" background.color="$bg")
  [ -f "$POPUP_STATE/$1.scroll" ] || return 0
  { IFS= read -r cut; IFS= read -r full; read -r base _; } <"$POPUP_STATE/$1.scroll"
  args+=(icon.drawing=on label="$cut" label.padding_left="$base")
}

case "$SENDER" in
  mouse.entered)
    [ "$lit" = "$NAME" ] && exit 0
    [ -n "$lit" ] && rest "$lit"
    if [ "$1" = text ]; then
      : >"$lit_file"
    else
      case "$(kind "$NAME")" in
        selected) args+=(--set "$NAME" background.color="$SELECTED") ;;
        destructive) args+=(--set "$NAME" background.color="$HOVER" icon.color="$RED" label.color="$RED") ;;
        *) args+=(--set "$NAME" background.color="$HOVER") ;;
      esac
      if [ -f "$POPUP_STATE/$NAME.scroll" ]; then
        { IFS= read -r _; IFS= read -r full; read -r _ hover end frames; } <"$POPUP_STATE/$NAME.scroll"
        # Full label in place of the cut one, a short pause, then move left
        # (two animations of one property in a message run one after another)
        args+=(icon.drawing=off label="$full" label.padding_left="$hover"
          --animate linear "$POPUP_SCROLL_PAUSE" --set "$NAME" label.padding_left="$hover"
          --animate linear "$frames" --set "$NAME" label.padding_left="$end")
      fi
      echo "$NAME" >"$lit_file"
    fi
    ;;
  mouse.exited)
    [ "$lit" = "$NAME" ] || exit 0
    rest "$NAME"
    : >"$lit_file"
    ;;
  popup.close)
    rm -f "$POPUP_STATE/$NAME.open"
    args+=(--set "$NAME" popup.drawing=off background.color="$(item_color "$NAME")")
    [ -n "$lit" ] && rest "$lit"
    : >"$lit_file"
    ;;
  *) exit 0 ;;
esac
[ "${#args[@]}" -gt 0 ] && sketchybar "${args[@]}"
exit 0
