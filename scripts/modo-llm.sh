#!/usr/bin/env bash
# -------------------------------------------------------------------
# modo-llm.sh — Free unified memory on the Mac before running local models
# -------------------------------------------------------------------
# Quits heavy apps politely (never a force quit), unloads every Ollama model
# except the one OpenCode uses, and prints memory pressure and swap before
# and after. A Podman machine is only reported, because the nix-builder
# container lives in it.
#
# Works over SSH once the terminal holds macOS Automation permission for the
# apps: macOS asks on the first run, on the Mac's own screen.
#
# Usage:
#   ./modo-llm.sh            # quit the apps below that are running
#   ./modo-llm.sh --dry-run  # only list what would be quit
#
#   KEEP_MODEL=qwen3.5-32k ./modo-llm.sh   # keep another model loaded
# -------------------------------------------------------------------
set -euo pipefail

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "modo-llm only runs on macOS." >&2
  exit 1
fi

DRY_RUN=false
[[ "${1:-}" == "--dry-run" ]] && DRY_RUN=true

KEEP_MODEL="${KEEP_MODEL:-qwen3.5-64k}"

# Browsers, Electron apps, VMs and media libraries: the usual memory hogs
APPS=(
  "Google Chrome"
  "Helium"
  "Arc"
  "Safari"
  "Slack"
  "Discord"
  "Ferdium"
  "Spotify"
  "Docker Desktop"
  "OrbStack"
  "Visual Studio Code"
  "Visual Studio Code - Insiders"
  "Xcode"
  "Simulator"
  "Photos"
  "Music"
)

report() {
  echo "== $1"
  memory_pressure | tail -1
  echo "Swap: $(sysctl -n vm.swapusage)"
}

report "Before"

for app in "${APPS[@]}"; do
  running=$(osascript -e "application \"$app\" is running" 2>/dev/null || echo false)
  [[ "$running" == "true" ]] || continue
  if $DRY_RUN; then
    echo "would quit: $app"
  elif osascript -e "quit app \"$app\"" >/dev/null 2>&1; then
    echo "quit: $app"
  else
    echo "could not quit: $app (Automation permission, or an unsaved document)"
  fi
done

if command -v ollama >/dev/null 2>&1; then
  while read -r model; do
    [[ -z "$model" || "$model" == "$KEEP_MODEL"* ]] && continue
    if $DRY_RUN; then
      echo "would unload model: $model"
    else
      ollama stop "$model" && echo "unloaded model: $model"
    fi
  done < <(ollama ps 2>/dev/null | tail -n +2 | awk '{print $1}')
fi

if command -v podman >/dev/null 2>&1 &&
  podman machine list --format '{{.Running}}' 2>/dev/null | grep -q true; then
  echo "Podman machine is running and holds its memory: 'podman machine stop' if the builder is not needed."
fi

$DRY_RUN && exit 0
sleep 3
report "After"

echo "== Largest processes left"
ps -axo rss=,comm= | sort -rn | head -8 | awk '{printf "%6.0f MB  %s\n", $1 / 1024, $2}'
