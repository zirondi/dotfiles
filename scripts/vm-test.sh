#!/usr/bin/env bash
# -------------------------------------------------------------------
# vm-test.sh — Validate a NixOS flake config compiles, optionally
#              build a VM image for testing in UTM
# -------------------------------------------------------------------
# Usage:
#   ./vm-test.sh [flake-host]              # validate config compiles
#   ./vm-test.sh [flake-host] --image      # also build a bootable VM image
#
# Examples:
#   ./vm-test.sh                           # defaults to 'nitro5-vm'
#   ./vm-test.sh nitro5-vm                 # explicit host
#   ./vm-test.sh nitro5-vm --image         # build a QCOW2 image for UTM
#
# The flake-host should be a NixOS configuration that does NOT include
# hardware-specific modules like nvidia.nix. Use the provided
# hardware-configuration-vm.nix as the hardware config.
#
# Environment:
#   DOTFILES_FLAKE  — path to the flake repo (default: ~/dotfiles)
#
# --- UTM Setup Guide ---
# After building with --image:
# 1. Open UTM on your Mac
# 2. Create a new VM → Emulate → Linux
# 3. Enable "Use Apple Virtualization" for speed
# 4. Enable "Enable Rosetta" for x86_64 translation (if your flake is x86_64)
# 5. For the boot disk, import the QCOW2 image from the result-vm symlink
# 6. Allocate at least 4GB RAM and 2 CPU cores
# 7. Boot and verify your config works!
# -------------------------------------------------------------------
set -eo pipefail

FLAKE_HOST="${1:-nitro5-vm}"
DOTFILES_FLAKE="${DOTFILES_FLAKE:-$HOME/dotfiles}"

# Verify flake exists
if [[ ! -f "$DOTFILES_FLAKE/flake.nix" ]]; then
  echo "❌ No flake.nix found at $DOTFILES_FLAKE"
  echo "   Set DOTFILES_FLAKE to your dotfiles repo path."
  exit 1
fi

echo "🧪 Validating NixOS configuration for '$FLAKE_HOST'..."
echo "   Flake: $DOTFILES_FLAKE#$FLAKE_HOST"
echo ""

# Phase 1: Validate the configuration evaluates correctly
OUT=$(nix build \
  "${DOTFILES_FLAKE}#nixosConfigurations.${FLAKE_HOST}.config.system.build.toplevel" \
  --no-link --print-out-paths 2>&1) || {
    echo "❌ Configuration failed to build!"
    echo "$OUT"
    exit 1
  }

echo "✅ Configuration is valid!"
echo "   Store path: $OUT"
echo ""

# Phase 2: Optionally build a bootable VM image
if [[ "${2}" == "--image" ]]; then
  echo "📦 Building VM image (this may take a while)..."
  echo "   This creates a QCOW2 disk image suitable for UTM or QEMU."
  echo ""

  nix build \
    "${DOTFILES_FLAKE}#nixosConfigurations.${FLAKE_HOST}.config.system.build.vm" \
    -o result-vm

  echo ""
  echo "✅ VM image built!"
  echo "   Output: $(readlink -f result-vm)"
  echo ""
  echo "📋 To use with UTM:"
  echo "   1. Open UTM → Create New VM → Emulate → Linux"
  echo "   2. Enable 'Use Apple Virtualization' + 'Enable Rosetta'"
  echo "   3. Import the disk image from the result-vm output"
  echo "   4. Set at least 4GB RAM, 2 CPUs"
  echo "   5. Boot and test your configuration!"
fi
