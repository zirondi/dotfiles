#!/usr/bin/env bash
# Bluetooth power and paired devices for the bar and its menu (configs/design/SURFACES.md).
#   bluetooth.sh                   JSON: power state and paired devices list
#   bluetooth.sh toggle            toggle power
#   bluetooth.sh power on|off      set power
#   bluetooth.sh connect <MAC>     connect device in background
#   bluetooth.sh disconnect <MAC>  disconnect device in background

powered() {
  bluetoothctl show 2>/dev/null | grep -q 'Powered: yes'
}

get_devices() {
  local line mac name conn
  bluetoothctl devices Paired 2>/dev/null | while IFS= read -r line; do
    [ -z "$line" ] && continue
    read -r _ mac name <<< "$line"
    [ -z "$mac" ] && continue
    [ -z "$name" ] && name="$mac"
    conn=false
    if bluetoothctl info "$mac" 2>/dev/null | grep -q 'Connected: yes'; then
      conn=true
    fi
    printf '%s\t%s\t%s\n' "$mac" "$name" "$conn"
  done | jq -Rsc 'split("\n") | map(select(length > 0) | split("\t") | {mac: .[0], name: .[1], connected: (.[2] == "true")})'
}

status_json() {
  local on devices
  if powered; then
    on=true
    devices="$(get_devices)"
  else
    on=false
    devices="[]"
  fi
  # notice: zero or one dim row for the menu. A list drawn with `for`, not a
  # row with :visible: eww sizes a window before hiding its invisible rows, and
  # on X11 the window never shrinks back, which left an empty row at the end
  jq -nc --argjson on "$on" --argjson devices "${devices:-[]}" \
    '{on: $on, devices: $devices,
      notice: (if $on | not then ["Bluetooth is off"]
               elif ($devices | length) == 0 then ["No paired devices"]
               else [] end)}'
}

update_eww() {
  command -v eww >/dev/null 2>&1 || return 0
  eww update bt="$(status_json)" 2>/dev/null || true
}

case "${1:-}" in
  toggle)
    if powered; then
      bluetoothctl power off >/dev/null 2>&1
    else
      bluetoothctl power on >/dev/null 2>&1
    fi
    update_eww
    exit 0
    ;;
  power)
    if [ "${2:-}" = "off" ]; then
      bluetoothctl power off >/dev/null 2>&1
    elif [ "${2:-}" = "on" ]; then
      bluetoothctl power on >/dev/null 2>&1
    elif powered; then
      bluetoothctl power off >/dev/null 2>&1
    else
      bluetoothctl power on >/dev/null 2>&1
    fi
    update_eww
    exit 0
    ;;
  connect)
    [ -z "${2:-}" ] && exit 1
    ( bluetoothctl connect "$2" >/dev/null 2>&1
      update_eww ) &
    exit 0
    ;;
  disconnect)
    [ -z "${2:-}" ] && exit 1
    ( bluetoothctl disconnect "$2" >/dev/null 2>&1
      update_eww ) &
    exit 0
    ;;
esac

status_json
