#!/usr/bin/env bash
# -------------------------------------------------------------------
# lib/common.sh — Helpers shared by the scripts in scripts/
# -------------------------------------------------------------------
# Source this file, do not execute it:
#   source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"
#
# Environment:
#   DOTFILES_FLAKE  — path to the flake repo (default: ~/dotfiles)
#   SERVICES_PATH   — colon-separated list of directories holding
#                     <service>/compose.yml stacks; earlier entries win
#   SERVICES_DIR    — single directory searched before SERVICES_PATH
# -------------------------------------------------------------------

DOTFILES_FLAKE="${DOTFILES_FLAKE:-$HOME/dotfiles}"

# Physical repo root (resolves the ~/dotfiles symlink), used to locate sibling repos
_COMMON_REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"

# Default search order: services submodule, sibling public `services` checkout,
# sibling private `private-services` checkout.
SERVICES_PATH="${SERVICES_PATH:-$DOTFILES_FLAKE/services:$_COMMON_REPO_ROOT/../services:$_COMMON_REPO_ROOT/../../private/private-services}"

# Print every existing services root, one per line, in priority order
services_roots() {
  local roots=() root
  [ -n "${SERVICES_DIR:-}" ] && roots+=("$SERVICES_DIR")
  IFS=':' read -r -a _path_roots <<< "$SERVICES_PATH"
  roots+=("${_path_roots[@]}")
  for root in "${roots[@]}"; do
    [ -n "$root" ] && [ -d "$root" ] && echo "$root"
  done
  return 0
}

# Print the directory of <service-name>, or return 1 if no root has it
find_service_dir() {
  local svc_name="$1" root
  while IFS= read -r root; do
    if [ -d "$root/$svc_name" ]; then
      echo "$root/$svc_name"
      return 0
    fi
  done < <(services_roots)
  return 1
}

# Print the secret names a compose.yml declares via `file: ./secrets/<name>`
compose_secret_names() {
  grep -Eo "file: \./secrets/[a-zA-Z0-9_-]+" "$1" | awk -F'/' '{print $NF}' || true
}
