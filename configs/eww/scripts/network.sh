#!/usr/bin/env bash
# One network item, same rule as SketchyBar: Ethernet when connected,
# otherwise Wi-Fi. The label is the local address; the network name goes in
# the tooltip.
line="$(nmcli -t -f DEVICE,TYPE,STATE device 2>/dev/null)"
addr() { ip -4 -o addr show dev "$1" | awk '{print $4}' | cut -d/ -f1 | head -1; }

eth="$(awk -F: '$2 == "ethernet" && $3 == "connected" {print $1; exit}' <<<"$line")"
if [ -n "$eth" ]; then
  jq -nc --arg ip "$(addr "$eth")" --arg dev "$eth" \
    '{kind: "eth", icon: "󰈀", ip: $ip, tooltip: ("Ethernet (" + $dev + ")")}'
  exit 0
fi

wifi="$(awk -F: '$2 == "wifi" && $3 == "connected" {print $1; exit}' <<<"$line")"
if [ -n "$wifi" ]; then
  ssid="$(nmcli -t -f ACTIVE,SSID device wifi 2>/dev/null | awk -F: '$1 == "yes" {print $2; exit}')"
  jq -nc --arg ip "$(addr "$wifi")" --arg ssid "$ssid" \
    '{kind: "wifi", icon: "󰖩", ip: $ip, tooltip: ("Wi-Fi: " + $ssid)}'
else
  jq -nc '{kind: "off", icon: "󰖪", ip: "", tooltip: "Offline"}'
fi
