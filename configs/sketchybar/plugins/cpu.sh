#!/usr/bin/env bash
# Total CPU use across all cores
cores="$(sysctl -n hw.ncpu)"
pct="$(ps -A -o %cpu= | awk -v n="$cores" '{s += $1} END {printf "%d", s / n}')"
sketchybar --set "$NAME" label="$pct%"
