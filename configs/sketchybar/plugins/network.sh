#!/usr/bin/env bash
# Network: Ethernet (with its address) when a wired port is up, otherwise
# Wi-Fi (with the network name when macOS shares it; it may be redacted)
# shellcheck source=../colors.sh
source "$CONFIG_DIR/colors.sh"

case "$SENDER" in
  mouse.entered | mouse.exited) exec "$CONFIG_DIR/plugins/item.sh" ;;
esac
ports="$(networksetup -listallhardwareports)"

for dev in $(awk '/Hardware Port: .*Ethernet/ {getline; print $2}' <<<"$ports"); do
  ip="$(ipconfig getifaddr "$dev" 2>/dev/null)"
  if [ -n "$ip" ]; then
    sketchybar --set "$NAME" icon="󰈀" icon.color="$FG" icon.padding_right=$((SPACE_ITEM / 2)) label.drawing=on label="$ip"
    exit 0
  fi
done

wifi="$(awk '/Hardware Port: Wi-Fi/ {getline; print $2}' <<<"$ports")"
if [ -n "$(ipconfig getifaddr "$wifi" 2>/dev/null)" ]; then
  ssid="$(ipconfig getsummary "$wifi" | awk -F ' SSID : ' '/ SSID : / {print $2}')"
  case "$ssid" in "" | "<redacted>") ssid="Wi-Fi" ;; esac
  sketchybar --set "$NAME" icon="󰖩" icon.color="$FG" icon.padding_right=$((SPACE_ITEM / 2)) label.drawing=on label="$ssid"
else
  sketchybar --set "$NAME" icon="󰖪" icon.color="$FG_DIM" icon.padding_right="$PAD_ITEM" label.drawing=off
fi
