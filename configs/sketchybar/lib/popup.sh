#!/usr/bin/env bash
# The one place popup looks are defined (configs/design/SURFACES.md): every
# SketchyBar popup (Apple menu, volume, calendar) is built with these
# functions, so all of them match. Colors and sizes come from colors.sh.
#
#   popup_style     <item>                      container: bg-surface, outline,
#                                               blur, top at surface-top, top padding
#   popup_entry     <parent> <name> <icon> <label> <action> [kind]
#                                               one clickable row; clicking closes
#                                               the popup and runs <action>.
#                                               kind: "selected" (the current
#                                               choice) or "destructive"
#   popup_header    <parent> <name> <label>     header row (text-strong), not clickable
#   popup_text      <parent> <name> <label>     secondary row (fg-dim), not clickable
#   popup_separator <parent> <name>             line between groups of rows
#   popup_end       <parent>                    bottom padding; call after the last row
#   popup_scroll    <item> <text> <chars>       label cut to <chars> with "…"; while
#                                               hovered the rest scrolls into view
#   popup_open      <item>                      show the popup, item `selected`
#   popup_close     <item>                      close the popup, rows back to rest
#   item_color      <item>                      background of a bar item for its state
#
# Variants: the calendar (clock) and the volume popup are panels (panel-width),
# every other popup is a menu (surface-width). Rows have a fixed width so the
# hover background spans the popup; a longer label is cut.
#
# Row and bar item states (hover, selected, destructive) all go through
# plugins/hover.sh and plugins/item.sh, which keep the per-item state in
# POPUP_STATE.
# shellcheck source=../colors.sh
source "${CONFIG_DIR:-$HOME/.config/sketchybar}/colors.sh"

POPUP_PLUGIN_DIR="${CONFIG_DIR:-$HOME/.config/sketchybar}/plugins"
POPUP_STATE="$HOME/.cache/sketchybar/popup"
[ -d "$POPUP_STATE" ] || (umask 077 && mkdir -p "$POPUP_STATE")

# Icon cell at the start of a row: pad-row, then the icon centered in icon-slot
POPUP_ICON_CELL=$((PAD_ROW_X + ICON_SLOT))
# Scrolling is done by animating label.padding_left (SketchyBar's own
# scroll_texts cannot be stopped once a pass has started, see hover.sh), so the
# distance is worked out here: the label font is monospaced.
POPUP_SCROLL_SPEED=50 # px per second
# shellcheck disable=SC2034 # read by hover.sh
POPUP_SCROLL_PAUSE=30 # frames (60 = 1 s) before a hovered row starts to move

popup_width() { # <parent>: outer width of the popup
  case "$1" in
    clock | volume) echo "$PANEL_WIDTH" ;;
    *) echo "$SURFACE_WIDTH" ;;
  esac
}

popup_row_width() { # <parent>: width of a row inside pad-surface and the outline
  echo $(($(popup_width "$1") - 2 * PAD_SURFACE - 2 * BORDER_SURFACE))
}

# The popup's cell height is 0, so every item sets its own height through a
# background that is always drawn (NONE when it should not show). SketchyBar
# places an item padding_left from the popup's outer edge, the outline
# included, and adds the outline once on the right: hence the extra
# BORDER_SURFACE on the left.
popup_item_args() { # <parent> <height>
  echo "width=$(popup_row_width "$1") padding_left=$((PAD_SURFACE + BORDER_SURFACE)) padding_right=$PAD_SURFACE" \
    "background.drawing=on background.color=$NONE background.height=$2 background.corner_radius=$RADIUS_INNER"
}

popup_spacer() { # <parent> <name> <height>
  # shellcheck disable=SC2046 # popup_item_args returns words on purpose
  sketchybar --add item "$1.$2" "popup.$1" \
    --set "$1.$2" icon.drawing=off label.drawing=off $(popup_item_args "$1" "$3")
}

popup_style() {
  sketchybar --set "$1" \
    popup.background.color="$BG_SURFACE" popup.background.corner_radius="$RADIUS_OUTER" \
    popup.background.border_width="$BORDER_SURFACE" popup.background.border_color="$OUTLINE" \
    popup.blur_radius="$BLUR" popup.height=0 \
    popup.y_offset=$((SURFACE_TOP - BAR_OFFSET - BAR_HEIGHT))
  sketchybar --remove "$1.pad_top" >/dev/null 2>&1
  popup_spacer "$1" pad_top "$PAD_SURFACE"
}

popup_end() {
  sketchybar --remove "$1.pad_end" >/dev/null 2>&1
  popup_spacer "$1" pad_end "$PAD_SURFACE"
}

popup_entry() {
  local parent="$1" name="$2" icon="$3" label="$4" action="$5" kind="${6:-}"
  local row="$parent.$name" bg="$NONE"
  rm -f "$POPUP_STATE/$row.scroll" # left over from an earlier build of the row
  if [ -n "$kind" ]; then echo "$kind" >"$POPUP_STATE/$row.kind"; else rm -f "$POPUP_STATE/$row.kind"; fi
  [ "$kind" = selected ] && bg="$SELECTED"
  # The click closes first (through hover.sh, in order with the hover events),
  # then runs the action
  # shellcheck disable=SC2046 # popup_item_args returns words on purpose
  sketchybar --add item "$row" "popup.$parent" \
    --set "$row" $(popup_item_args "$parent" "$ROW_HEIGHT") background.color="$bg" \
      icon="$icon" icon.font="$ICON_ROW" icon.color="$FG" icon.align=center \
      icon.width="$POPUP_ICON_CELL" icon.padding_left="$PAD_ROW_X" icon.padding_right=0 \
      label="$label" label.font="$TEXT" label.color="$FG" \
      label.padding_left="$SPACE_ICON" label.padding_right="$PAD_ROW_X" \
      script="$POPUP_PLUGIN_DIR/hover.sh" \
      click_script="SENDER=popup.close NAME=$parent POPUP_SEQ=\$\$ '$POPUP_PLUGIN_DIR/hover.sh'; $action" \
    --subscribe "$row" mouse.entered mouse.exited
}

# A row with no icon: the label starts at pad-row, like a header
popup_no_icon() { # <row>
  sketchybar --set "$1" icon.drawing=off label.padding_left="$PAD_ROW_X"
}

popup_line() { # <parent> <name> <label> <font> <color>
  # Entering a header clears the lit row, like entering another row
  # shellcheck disable=SC2046 # popup_item_args returns words on purpose
  sketchybar --add item "$1.$2" "popup.$1" \
    --set "$1.$2" $(popup_item_args "$1" "$ROW_HEIGHT") icon.drawing=off \
      label="$3" label.font="$4" label.color="$5" \
      label.padding_left="$PAD_ROW_X" label.padding_right="$PAD_ROW_X" \
      script="$POPUP_PLUGIN_DIR/hover.sh text" \
    --subscribe "$1.$2" mouse.entered
}

popup_header() { popup_line "$1" "$2" "$3" "$TEXT_STRONG" "$FG"; }
popup_text() { popup_line "$1" "$2" "$3" "$TEXT" "$FG_DIM"; }

popup_separator() { # <parent> <name>: three items, space / 1 px line / space
  popup_spacer "$1" "$2.a" "$SEPARATOR_SPACE"
  popup_spacer "$1" "$2.line" "$BORDER_SURFACE"
  sketchybar --set "$1.$2.line" background.color="$SEPARATOR" background.corner_radius=0
  popup_spacer "$1" "$2.b" "$SEPARATOR_SPACE"
}

popup_scroll() { # <item> <text> <chars>
  local item="$1" text="$2" chars="$3" cut shift hover
  if [ "${#text}" -le "$chars" ]; then
    sketchybar --set "$item" label="$text"
    return
  fi
  cut="${text:0:$((chars - 1))}…"
  # Hovered, the icon is hidden and the full label starts where the cut one
  # did; it then moves left until its last character sits where the "…" was
  shift=$(((${#text} - chars) * TEXT_ADVANCE_PX100 / 100))
  hover=$((POPUP_ICON_CELL + SPACE_ICON))
  (
    umask 077 # event titles are private
    printf '%s\n%s\n%s %s %s %s\n' "$cut" "$text" "$SPACE_ICON" "$hover" \
      "$((hover - shift))" "$((shift * 60 / POPUP_SCROLL_SPEED))" >"$POPUP_STATE/$item.scroll"
  )
  sketchybar --set "$item" label="$cut"
}

# Bar item background for its state (THEME.md, "Bar items"): `selected` while
# its popup is open, `hover` under the pointer, otherwise none
item_color() { # <item>
  if [ -e "$POPUP_STATE/$1.open" ]; then
    echo "$SELECTED"
  elif [ -e "$POPUP_STATE/$1.hover" ]; then
    echo "$HOVER"
  else
    echo "$NONE"
  fi
}

popup_is_open() { [ "$(sketchybar --query "$1" | jq -r '.popup.drawing')" = on ]; }

# Call popup_close first (it orders this open after any close still on its
# way, see hover.sh), then build the rows, then open
popup_open() {
  : >"$POPUP_STATE/$1.open"
  sketchybar --set "$1" popup.drawing=on background.color="$SELECTED"
}

# $$ is the PID SketchyBar gave the calling event script: hover.sh uses it to
# order this close against the row events
popup_close() {
  POPUP_SEQ=$$ NAME="$1" SENDER=popup.close "$POPUP_PLUGIN_DIR/hover.sh"
}
