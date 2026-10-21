#!/usr/bin/env bash
# One bar popup open at a time (configs/design/SURFACES.md). The open one is
# kept in the eww variable `popup`, so the bar item that opened it shows
# `selected`.
#   popup.sh toggle <name>   open it (closing any other), or close it if open
#   popup.sh close <name>    close it (no-op for an empty name)
action="${1:-}"
name="${2:-}"
[ -z "$name" ] && exit 0
open="$(eww get popup 2>/dev/null)"

case "$action" in
  toggle)
    if [ "$open" = "$name" ]; then
      eww close "$name"
      eww update popup=""
      exit 0
    fi
    [ -n "$open" ] && eww close "$open"
    eww update popup="$name"
    eww open "$name"
    ;;
  close)
    eww close "$name" >/dev/null 2>&1
    [ "$open" = "$name" ] && eww update popup=""
    ;;
  *)
    echo "usage: popup.sh toggle|close <name>" >&2
    exit 2
    ;;
esac
exit 0
