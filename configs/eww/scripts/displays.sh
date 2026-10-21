#!/usr/bin/env bash
# Monitor layouts for the laptop screen (eDP, always the primary one: it holds
# the dock) and one external monitor. "Displays" in the logo menu opens the
# menu; i3 runs `auto` at login.
#   displays.sh above    external above the laptop, centered (the lab setup)
#   displays.sh right    external to the right, tops aligned
#   displays.sh left     external to the left, tops aligned
#   displays.sh mirror   both show the same picture at the laptop's mode
#   displays.sh laptop   external off
#   displays.sh external laptop screen off (the dock moves to the external)
#   displays.sh auto     `above` when an external is connected, else `laptop`
#   displays.sh force    toggle the HDMI fallback for monitors without EDID
#                        (hdmi-1080p.service, hosts/nitro5/hdmi-1080p.nix)
#   displays.sh menu     choose one in a menu (rofi), or arrange by hand (arandr)
# After a change it redraws the wallpaper (feh draws it for the screen size of
# the moment; same file as the login one in configs/i3/config), and restarts
# picom (it keeps drawing the old screen size otherwise) and eww (one bar per
# monitor, configs/eww/launch.sh).
LAUNCH="$HOME/.config/eww/launch.sh"

internal="$(xrandr --query | awk '/^eDP[^ ]* connected/ { print $1; exit }')"
external="$(xrandr --query | awk '/ connected/ && $1 !~ /^eDP/ { print $1; exit }')"

# Current size of an output as "<width> <height>"
size() { xrandr --query | awk -v o="$1" '$1 == o { for (i = 3; i <= NF; i++) if ($i ~ /^[0-9]+x[0-9]+\+/) { split($i, a, /[x+]/); print a[1], a[2]; exit } }'; }

apply() {
  feh --no-fehbg --bg-fill "$HOME/Pictures/wallpaper.jpg"
  systemctl --user restart picom 2>/dev/null
  # Give X a moment to announce the new monitors: eww opens bars by monitor
  # name and missed them when started right after xrandr
  sleep 1
  setsid -f "$LAUNCH" >/dev/null 2>&1
}

above() {
  local ew eh iw ex ix
  xrandr --output "$external" --auto --output "$internal" --auto --primary
  read -r ew eh < <(size "$external")
  read -r iw _ < <(size "$internal")
  # Center the narrower one under or over the wider one
  ex=0 ix=0
  if [ "$ew" -ge "$iw" ]; then ix=$(((ew - iw) / 2)); else ex=$(((iw - ew) / 2)); fi
  xrandr --output "$external" --pos "${ex}x0" --output "$internal" --primary --pos "${ix}x${eh}"
}

case "${1:-}" in
  above | right | left | mirror | external)
    [ -z "$external" ] && { echo "displays.sh: no external monitor connected" >&2; exit 1; }
    ;;
esac

case "${1:-}" in
  above) above ;;
  right) xrandr --output "$internal" --auto --primary --pos 0x0 --output "$external" --auto --right-of "$internal" ;;
  left) xrandr --output "$internal" --auto --primary --output "$external" --auto --left-of "$internal" ;;
  mirror) xrandr --output "$internal" --auto --primary --output "$external" --mode "$(size "$internal" | tr ' ' x)" --same-as "$internal" ;;
  external) xrandr --output "$external" --auto --primary --pos 0x0 --output "$internal" --off ;;
  laptop) xrandr --output "$internal" --auto --primary ${external:+--output "$external" --off} ;;
  auto)
    # xrandr --auto also turns off outputs that are no longer connected
    if [ -n "$external" ]; then above; else xrandr --auto --output "$internal" --primary; fi
    ;;
  force)
    # A splitter or adapter without EDID leaves the port "disconnected"; the
    # service loads a generic 1080p one and forces the port (or undoes it)
    if systemctl is-active --quiet hdmi-1080p.service; then
      systemctl stop hdmi-1080p.service
    elif ! systemctl start hdmi-1080p.service; then
      notify-send -u critical "Displays" "Could not force 1080p on HDMI (journalctl -u hdmi-1080p)"
      exit 1
    fi
    sleep 1
    exec "$0" auto
    ;;
  menu)
    force_row="Force 1080p on HDMI (no EDID)"
    systemctl is-active --quiet hdmi-1080p.service && force_row="Stop forcing 1080p on HDMI"
    choice="$(printf '%s\n' "Monitor above the laptop" "Monitor to the right" "Monitor to the left" "Mirror" "Laptop only" "Monitor only" "Arrange…" "$force_row" |
      rofi -dmenu -theme menu -monitor -5 -theme-str 'window { location: center; anchor: center; }' \
        -l 8 -no-custom -p displays -mesg "<b>Displays</b>")"
    case "$choice" in
      "Monitor above the laptop") exec "$0" above ;;
      "Monitor to the right") exec "$0" right ;;
      "Monitor to the left") exec "$0" left ;;
      Mirror) exec "$0" mirror ;;
      "Laptop only") exec "$0" laptop ;;
      "Monitor only") exec "$0" external ;;
      "Arrange…") arandr; apply ;;
      "$force_row") exec "$0" force ;;
    esac
    exit 0
    ;;
  *)
    echo "usage: displays.sh above|right|left|mirror|laptop|external|auto|force|menu" >&2
    exit 2
    ;;
esac
apply
