#!/usr/bin/env bash
# Tokens from configs/design/THEME.md, the only place SketchyBar takes colors
# and sizes from. Names are the token names in capitals (`accent-2` = ACCENT_2).
# modules/darwin/desktop.nix also reads BORDER_ACTIVE, BORDER_INACTIVE and
# BORDER_WINDOW from here for JankyBorders: keep those three as plain
# `export NAME=value` lines, and run `just switch` after changing them.
# Values not in THEME.md are marked TODO(design-gap).

# --- Color (0xAARRGGBB) ---
export BG=0xff0e0b1c
export FG=0xfff5f5f7
export FG_DIM=0xff8e8e93
export ACCENT=0xffe04cc8
export ACCENT_2=0xff7c4dff
export RED=0xffff453a
export ORANGE=0xffff9f0a
export YELLOW=0xffffd60a
export GREEN=0xff32d74b

export BG_BAR=0xb30e0b1c     # bg at 70%
export BG_SURFACE=0xe60e0b1c # bg at 90%
export OUTLINE=0x33ffffff    # white at 20%
export SEPARATOR=0x33ffffff  # white at 20%
export HOVER=0x14ffffff      # white at 8%
export SELECTED=0x59e04cc8   # accent at 35%
export BORDER_ACTIVE=0xffe04cc8
export BORDER_INACTIVE=0xff3a2577
# "No background": the normal state of rows and bar items, which keep their
# background drawn (transparent) so their height never changes
export NONE=0x00000000

# --- Type (SketchyBar font strings, "Family:Style:Size") ---
export FONT="Red Hat Mono"
export FONT_ICON="Hack Nerd Font Propo"
export TEXT="$FONT:Regular:13.0"
export TEXT_STRONG="$FONT:Bold:13.0"
export TEXT_SMALL="$FONT:Regular:11.0"
export ICON="$FONT_ICON:Bold:14.0"
export ICON_LARGE="$FONT_ICON:Bold:16.0"
export ICON_ROW="$FONT_ICON:Regular:13.0" # row icons are `text` size (SURFACES.md, Anatomy)
export TEXT_ADVANCE_PX100=780             # Red Hat Mono advance at `text` (600/1000 em × 13 px), in 1/100 px

# --- Size and spacing (px) ---
export BAR_HEIGHT=32
export BAR_OFFSET=6
export EDGE=8
export GAP=8
export SURFACE_TOP=44
export ROW_HEIGHT=26
export PAD_SURFACE=6
export PAD_ROW_X=10 # pad-row is "0 10 px"
export ICON_SLOT=18
export SPACE_ICON=8
export SURFACE_WIDTH=240
export PANEL_WIDTH=300
export SEPARATOR_SPACE=4 # space above and below a separator (SURFACES.md, Anatomy)
export PILL_HEIGHT=22    # workspace pill (THEME.md, "Bar items")

# --- Shape and depth ---
export RADIUS_OUTER=10
export RADIUS_INNER=6
export BORDER_WINDOW=2
export BORDER_SURFACE=1
export BLUR=30

# --- Bar item spacing ---
# TODO(design-gap): THEME.md has no tokens for these; values from the
# prototype (.bar, .item, .ws, .slider in configs/design/prototype/index.html)
export PAD_BAR=6       # inside the bar, at both ends
export ITEM_HEIGHT=24  # hover/selected background of a bar item
export PAD_ITEM=6      # inside a bar item, at both ends
export SPACE_ITEM=6    # between a bar item's icon and its label
export GAP_ITEM=2      # between bar items
export PAD_PILL=7      # inside a workspace pill, at both ends
export GAP_PILL=4      # between workspace pills
export SLIDER_TRACK=4  # height of the volume slider's track
export SLIDER_KNOB=12  # size of the volume slider's knob
