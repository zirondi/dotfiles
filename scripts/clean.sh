#!/usr/bin/env bash
# -------------------------------------------------------------------
# clean.sh — Clean old NixOS generations and garbage-collect on a host
# -------------------------------------------------------------------
# Usage:
#   ./clean.sh [target-host]
#
# Examples:
#   ./clean.sh nitro5                 # Clean Nitro 5 via SSH alias
#   ./clean.sh hetzner                # Clean Hetzner VPS via SSH alias
#   ./clean.sh rpi3                   # Clean Raspberry Pi via SSH alias
#   ./clean.sh                        # Run locally (defaults to localhost)
# -------------------------------------------------------------------
set -eo pipefail

TARGET="${1:-localhost}"

echo "🧹 Cleaning up old NixOS generations on $TARGET..."

if [[ "$TARGET" == "localhost" ]]; then
  # Run locally
  sudo nix-env --profile /nix/var/nix/profiles/system --delete-generations old
  sudo nix-collect-garbage -d
else
  # Run remotely via SSH (resolves user, port and host via ~/.ssh/config)
  ssh -t -o StrictHostKeyChecking=accept-new "$TARGET" \
    "sudo nix-env --profile /nix/var/nix/profiles/system --delete-generations old && sudo nix-collect-garbage -d"
fi

echo ""
echo "✅ Cleanup complete! Reclaimed disk space on $TARGET."
