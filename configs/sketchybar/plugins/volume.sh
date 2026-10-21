#!/usr/bin/env bash
# Volume item: label/icon on volume_change, scroll to change it, click for the
# output popup (slider + devices via SwitchAudioSource), Cmd+click for
# Sound Settings
# shellcheck source=../lib/popup.sh
source "$CONFIG_DIR/lib/popup.sh"

# Outputs left out of the popup: the monitors (never used for sound) and the
# leftover Background Music virtual devices
HIDDEN_OUTPUTS=$'22P1W\nE2240\nBackground Music\nBackground Music (UI Sounds)'

current_volume() { osascript -e 'output volume of (get volume settings)'; }

show() {
  local vol="$1" icon
  case "$vol" in
    0 | "" | "missing value") icon="" ;;
    [0-9] | [1-5][0-9]) icon="" ;;
    *) icon="" ;;
  esac
  sketchybar --set "$NAME" icon="$icon" label="$vol%" \
    --set volume.slider slider.percentage="$vol" label="$vol%"
}

# Output rows after the slider and the "Output" line that sketchybarrc built:
# the current output is the `selected` row
build_popup() {
  popup_close "$NAME" # rows back to rest before they are removed
  # SketchyBar's item regex has no (a|b) alternation: one pattern per prefix
  sketchybar --remove '/volume\.dev\..*/' --remove '/volume\.act\..*/' \
    --remove '/volume\.sep2.*/' >/dev/null 2>&1
  local current i=0 dev
  current="$(SwitchAudioSource -c -t output)"
  while IFS= read -r dev; do
    [ -z "$dev" ] && continue
    grep -qxF -- "$dev" <<<"$HIDDEN_OUTPUTS" && continue
    if [ "$dev" = "$current" ]; then
      popup_entry volume "dev.$i" "" "$dev" "true" selected
    else
      popup_entry volume "dev.$i" "󰓃" "$dev" "SwitchAudioSource -t output -s \"$dev\""
    fi
    i=$((i + 1))
  done < <(SwitchAudioSource -a -t output)
  popup_separator volume sep2
  popup_entry volume act.settings "" "Sound Settings…" "open x-apple.systempreferences:com.apple.Sound-Settings.extension"
  popup_end volume
}

case "$SENDER" in
  volume_change) show "$INFO" ;;
  mouse.scrolled)
    vol="$(current_volume)"
    vol=$((vol + SCROLL_DELTA * 2))
    [ "$vol" -lt 0 ] && vol=0
    [ "$vol" -gt 100 ] && vol=100
    osascript -e "set volume output volume $vol"
    ;;
  mouse.clicked)
    if [ "$MODIFIER" = "cmd" ]; then
      open x-apple.systempreferences:com.apple.Sound-Settings.extension
    elif popup_is_open "$NAME"; then
      popup_close "$NAME"
    else
      build_popup
      popup_open "$NAME"
    fi
    ;;
  mouse.entered | mouse.exited) exec "$CONFIG_DIR/plugins/item.sh" ;;
  # Pointer left the bar and the popups, or a click went to another app
  # (see popup_close.sh)
  mouse.exited.global | front_app_switched) popup_close "$NAME" ;;
  *) show "$(current_volume)" ;;
esac
