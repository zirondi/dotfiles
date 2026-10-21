#!/usr/bin/env bash
# Bluetooth power as JSON; `toggle` switches it
powered() { bluetoothctl show 2>/dev/null | grep -q 'Powered: yes'; }

if [ "${1:-}" = "toggle" ]; then
  if powered; then bluetoothctl power off >/dev/null; else bluetoothctl power on >/dev/null; fi
  exit 0
fi
if powered; then echo '{"on": true}'; else echo '{"on": false}'; fi
