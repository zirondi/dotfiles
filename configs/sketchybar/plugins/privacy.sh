#!/usr/bin/env bash
# Microphone (orange) and camera (green) in use, the twin of the macOS
# privacy dots that live in the hidden native menu bar. Both items stay hidden
# while idle. Data: sketchybar-privacy (pkgs/sketchybar-privacy).
state="$(sketchybar-privacy 2>/dev/null)"
mic="$(jq -r '.mic // false' <<<"$state")"
cam="$(jq -r '.camera // false' <<<"$state")"
sketchybar --set privacy.mic drawing="$([ "$mic" = true ] && echo on || echo off)" \
  --set privacy.cam drawing="$([ "$cam" = true ] && echo on || echo off)"
