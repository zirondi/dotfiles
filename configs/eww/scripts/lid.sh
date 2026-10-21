#!/usr/bin/env bash
# "Keep awake with the lid closed": starts/stops lid-awake.service, a root
# service holding logind's handle-lid-switch inhibitor (modules/nixos/desktop.nix),
# so closing the lid neither suspends nor drops SSH. The user may start/stop it
# without a password, from the system menu or over SSH. A laptop icon shows in
# the bar while it is on.
#   lid.sh          print true/false
#   lid.sh toggle   turn it on/off
#   lid.sh on|off
unit=lid-awake.service
active() { systemctl is-active --quiet "$unit"; }

case "${1:-}" in
  toggle) if active; then systemctl stop "$unit"; else systemctl start "$unit"; fi ;;
  on) systemctl start "$unit" ;;
  off) systemctl stop "$unit" ;;
  *) active && echo true || echo false ;;
esac
