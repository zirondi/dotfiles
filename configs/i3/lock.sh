#!/usr/bin/env bash
# Lock screen for i3 (i3lock-color): the wallpaper with the ring in the
# configs/design/THEME.md palette, so a locked screen never looks like a dead one.
# Run by xss-lock (before suspend and on `loginctl lock-session`, bound to
# $mod+Q). Extra arguments are passed on (xss-lock adds --nofork).
# Never stack a second locker: only one can grab the keyboard and pointer,
# and the one on top would then leave a screen that ignores all input.
# Suspend can fire two lock requests within a second, so a pgrep check races;
# the flock is atomic, and i3lock keeps fd 9 (and the lock) until it exits.
exec 9>"${XDG_RUNTIME_DIR:-/tmp}/i3-lock.lock"
flock -n 9 || exit 0

wallpaper="$HOME/Pictures/wallpaper.jpg"
image=()
[ -r "$wallpaper" ] && image=(--image "$wallpaper" --fill)

exec i3lock "${image[@]}" --color=0e0b1c \
  --clock --indicator --radius=110 --ring-width=8 \
  --inside-color=0e0b1cb3 --ring-color=7c4dffff --line-uses-inside \
  --keyhl-color=e04cc8ff --bshl-color=ff453aff --separator-color=00000000 \
  --insidever-color=0e0b1cb3 --ringver-color=e04cc8ff \
  --insidewrong-color=0e0b1cb3 --ringwrong-color=ff453aff \
  --time-color=f5f5f7ff --date-color=f5f5f7cc --verif-color=f5f5f7ff --wrong-color=ff453aff \
  --time-font="Hack Nerd Font" --date-font="Hack Nerd Font" \
  --verif-font="Hack Nerd Font" --wrong-font="Hack Nerd Font" \
  --time-str="%H:%M" --date-str="%a %d %b" --verif-text="..." --wrong-text="Senha errada" --noinput-text="" \
  --greeter-text="Digite sua senha e tecle Enter" --greeter-color=f5f5f7cc \
  --greeter-font="Hack Nerd Font" --greeter-size=16 --greeter-pos="ix:iy+170" \
  --show-failed-attempts \
  "$@"
