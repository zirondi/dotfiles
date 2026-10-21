#!/usr/bin/env bash
# The `confirm` surface (configs/design/SURFACES.md): asks before ending the
# session or the machine. Cancel is on the left and selected, so Enter and
# Esc cancel; the action is on the right in `red`. Drawn by rofi with
# configs/rofi/confirm.rasi.
#   confirm.sh restart|shutdown|logout
# Used by the logo menu (eww.yuck) and Cmd+Shift+Q (configs/i3/config).
case "${1:-}" in
  restart) title="Restart?" action="Restart" cmd=(systemctl reboot) ;;
  shutdown) title="Shut down?" action="Shut Down" cmd=(systemctl poweroff) ;;
  logout) title="Log out?" action="Log Out" cmd=(i3-msg exit) ;;
  *)
    echo "usage: confirm.sh restart|shutdown|logout" >&2
    exit 2
    ;;
esac

# Only one confirm at a time
pgrep -u "$USER" -f 'rofi .*confirm\.rasi' >/dev/null && exit 0

# -format i prints the row index; row 1 (the action) is marked urgent (red)
choice="$(printf 'Cancel\n%s\n' "$action" |
  rofi -dmenu -theme "$HOME/.config/rofi/confirm.rasi" -no-custom -format i \
    -selected-row 0 -u 1 \
    -mesg "<b>$title</b>
Open apps will be closed without saving.")"

[ "$choice" = "1" ] && exec "${cmd[@]}"
exit 0
