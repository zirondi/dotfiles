#!/usr/bin/env bash
# -------------------------------------------------------------------
# update.sh — Update flake inputs, then build and deploy
# -------------------------------------------------------------------
# Usage:
#   ./update.sh <flake-host> [target-ssh] [--input <name>]
#
# Examples:
#   ./update.sh nitro5                                # update all inputs and deploy to nitro5
#   ./update.sh hetzner --input nixpkgs               # update only nixpkgs for hetzner
#   ./update.sh nitro5 root@10.0.0.80                 # explicit SSH override
#
# Environment:
#   DOTFILES_FLAKE  — path to the flake repo (default: ~/dotfiles)
# -------------------------------------------------------------------
set -eo pipefail

FLAKE_HOST="${1:?❌ Usage: ./update.sh <flake-host> [target-ssh] [--input <name>]}"
shift 1

# If target is omitted or is a flag, default TARGET to FLAKE_HOST
if [[ $# -eq 0 || "$1" == --* ]]; then
  TARGET="$FLAKE_HOST"
else
  TARGET="$1"
  shift 1
fi

DOTFILES_FLAKE="${DOTFILES_FLAKE:-$HOME/dotfiles}"

# Parse optional --input flag (input names are positional in `nix flake update`)
UPDATE_ARGS=()
if [[ "${1:-}" == "--input" && -n "${2:-}" ]]; then
  UPDATE_ARGS+=("${2}")
  echo "🔄 Updating flake input '${2}'..."
else
  echo "🔄 Updating all flake inputs..."
fi

nix flake update "${UPDATE_ARGS[@]}" --flake "$DOTFILES_FLAKE"

echo ""
echo "🚀 Deploying with updated inputs..."
"$(dirname "${BASH_SOURCE[0]}")/deploy.sh" "$FLAKE_HOST" "$TARGET"
