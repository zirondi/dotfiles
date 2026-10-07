#!/usr/bin/env bash
# -------------------------------------------------------------------
# lib/builder.sh — Local Linux Nix builder running in a container
# -------------------------------------------------------------------
# Source this file, do not execute it:
#   source "$(dirname "${BASH_SOURCE[0]}")/lib/builder.sh"
#
# Builds NixOS systems for hosts that share this machine's CPU
# architecture (e.g. rpi3 from an Apple Silicon Mac) inside a persistent
# `nixos/nix` container, so low-powered targets never compile anything.
# Evaluation and SSH stay on this machine; only store paths travel:
#   .drv closure  ->  container  (nix-store --export | --import)
#   built closure ->  target     (only the paths the target is missing)
#
# Environment:
#   BUILDER_RUNTIME  — container CLI (default: podman, else docker)
#   BUILDER_NAME     — container name (default: nix-builder)
#   BUILDER_IMAGE    — image (default: docker.io/nixos/nix:2.35.2)
#   BUILDER_CORES    — cores per build (default: all, or 2 below 4 GiB RAM)
# -------------------------------------------------------------------

BUILDER_NAME="${BUILDER_NAME:-nix-builder}"
BUILDER_IMAGE="${BUILDER_IMAGE:-docker.io/nixos/nix:2.35.2}"
if [ -z "${BUILDER_RUNTIME:-}" ]; then
  if command -v podman >/dev/null 2>&1; then
    BUILDER_RUNTIME="podman"
  else
    BUILDER_RUNTIME="docker"
  fi
fi

# Print the Linux system this machine's builder produces (e.g. aarch64-linux),
# or return 1 when no container runtime is available
builder_system() {
  command -v "$BUILDER_RUNTIME" >/dev/null 2>&1 || return 1
  case "$(uname -m)" in
    arm64|aarch64) echo "aarch64-linux" ;;
    x86_64) echo "x86_64-linux" ;;
    *) return 1 ;;
  esac
}

# Run a command inside the builder (stdin is forwarded)
_builder_exec() {
  "$BUILDER_RUNTIME" exec -i "$BUILDER_NAME" "$@"
}

# Create and/or start the builder container; /nix lives in a named volume
builder_ensure() {
  if ! "$BUILDER_RUNTIME" container inspect "$BUILDER_NAME" >/dev/null 2>&1; then
    echo "   📦 Creating builder container '$BUILDER_NAME' ($BUILDER_IMAGE)..."
    "$BUILDER_RUNTIME" run -d --name "$BUILDER_NAME" \
      --security-opt no-new-privileges=true \
      -v "${BUILDER_NAME}-store:/nix" \
      "$BUILDER_IMAGE" sleep infinity >/dev/null
  elif [ "$("$BUILDER_RUNTIME" container inspect -f '{{.State.Running}}' "$BUILDER_NAME")" != "true" ]; then
    "$BUILDER_RUNTIME" start "$BUILDER_NAME" >/dev/null
  fi
}

# Nix settings for builds, sized to the memory the container actually has
_builder_nix_config() {
  local cores="${BUILDER_CORES:-}"
  if [ -z "$cores" ]; then
    # First line of /proc/meminfo is "MemTotal: <kB> kB" (the image has no awk)
    cores="$(_builder_exec sh -c 'read -r _ kb _ < /proc/meminfo; if [ "$kb" -lt 3500000 ]; then echo 2; else nproc; fi' </dev/null)"
  fi
  printf 'experimental-features = nix-command flakes\nmax-jobs = 2\ncores = %s\n' "$cores"
}

# builder_build <drv-path> <gc-root-name>
# Realise a locally evaluated derivation in the builder; prints the out path.
# The result is kept as a GC root so `builder_gc` never drops the last build.
builder_build() {
  local drv="$1" root="$2" out
  builder_ensure

  echo "   📤 Sending derivation closure to the builder..." >&2
  # shellcheck disable=SC2046 # one argument per store path is intended
  nix-store --export $(nix-store -qR "$drv") | _builder_exec nix-store --import >/dev/null

  echo "   🔨 Building in '$BUILDER_NAME' (cached paths are downloaded, the rest compiled)..." >&2
  out="$(_builder_exec env NIX_CONFIG="$(_builder_nix_config)" \
    nix-store --realise "$drv" --add-root "/nix/var/nix/gcroots/builder/$root" </dev/null | tail -n 1)"
  # --add-root prints the root symlink; resolve it to the store path
  _builder_exec readlink -f "$out" </dev/null
}

# builder_copy_to <out-path> <target-ssh>
# Copy to the target only the store paths of the closure it does not have yet.
builder_copy_to() {
  local out="$1" target="$2" missing count
  missing="$(_builder_exec nix-store -qR "$out" </dev/null \
    | ssh "$target" 'xargs nix-store --check-validity --print-invalid')"

  if [ -z "$missing" ]; then
    echo "   ✅ Target already has every store path."
    return 0
  fi

  count="$(printf '%s\n' "$missing" | wc -l | tr -d ' ')"
  echo "   🚚 Copying $count new store paths to $target..."
  printf '%s\n' "$missing" | _builder_exec sh -c 'cat > /tmp/missing-paths'
  # shellcheck disable=SC2016 # expanded inside the container
  _builder_exec sh -c 'nix-store --export $(cat /tmp/missing-paths)' </dev/null \
    | ssh "$target" 'nix-store --import >/dev/null'
}

# Garbage-collect the builder's store (the last build of each host is kept)
builder_gc() {
  builder_ensure
  _builder_exec nix-collect-garbage -d </dev/null
}
