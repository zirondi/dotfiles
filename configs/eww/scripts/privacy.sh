#!/usr/bin/env bash
# Microphone and camera in use, as JSON (twin of configs/sketchybar/plugins/privacy.sh).
# Mic: any recording stream in PipeWire/Pulse, ignoring the volume meters that
# pavucontrol opens. Camera: any process of this user holding /dev/video*.
mic=false
if pactl list source-outputs 2>/dev/null | grep -i 'application.name' | grep -viq 'pavucontrol\|peak'; then
  mic=true
fi
cam=false
for fd in /proc/[0-9]*/fd/*; do
  case "$(readlink "$fd" 2>/dev/null)" in /dev/video*) cam=true; break ;; esac
done
echo "{\"mic\": $mic, \"camera\": $cam}"
