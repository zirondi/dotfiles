#!/usr/bin/env bash
# -------------------------------------------------------------------
# sync-dotfiles.sh — Two-way sync of this repo with another workstation
# -------------------------------------------------------------------
# Carries uncommitted work between machines (macmini <-> nitro5) without
# going through GitHub. Unison copies whatever changed on either side and
# stops on conflicts (the same file changed on both) instead of overwriting.
#
# Usage:
#   ./sync-dotfiles.sh <ssh-host> [--interactive] [unison options...]
#
#   ./sync-dotfiles.sh nitro5                # from the Mac
#   ./sync-dotfiles.sh macmini               # from the notebook (same result)
#   ./sync-dotfiles.sh nitro5 --interactive  # review each change, resolve conflicts
#
# Only the working tree travels: .git is never synced. Copying a live repo
# file by file corrupted it (2026-10-21: an orphan pack without its index, a
# stale multi-pack-index and a stash ref without its objects on the Mac, and
# every sync stopped on conflicts in .git). Commits move with git instead
# (push and pull, or `git push <host>:<repo> main:<branch>` between the two).
#
# The repo sits at the same path relative to $HOME on every workstation
# (repos/github/me/public/dotfiles), so both roots are derived from it.
# Hosts are SSH aliases from configs/ssh/config. Both ends must run the same
# unison version (checked below; see docs/host-management.md).
# -------------------------------------------------------------------
set -euo pipefail

host="${1:?Usage: ./sync-dotfiles.sh <ssh-host> [--interactive] [unison options...]}"
shift

batch=(-batch)
if [ "${1:-}" = "--interactive" ]; then
  batch=()
  shift
fi

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
case "$repo" in
  "$HOME"/*) rel="${repo#"$HOME"/}" ;;
  *)
    echo "❌ $repo is not under \$HOME; cannot map it on $host" >&2
    exit 1
    ;;
esac

command -v unison >/dev/null || {
  echo "❌ unison not found (modules/shared/cli-dev.nix)" >&2
  exit 1
}

# Unison refuses (or corrupts archives) across versions; both ends come from
# the same nixpkgs pin (modules/shared/cli-dev.nix), so a mismatch means one
# host has not been rebuilt yet
local_version="$(unison -version)"
remote_version="$(ssh "$host" /run/current-system/sw/bin/unison -version)"
if [ "$local_version" != "$remote_version" ]; then
  echo "❌ unison differs: here '$local_version', $host '$remote_version'" >&2
  echo "   Rebuild the older host (just switch / just deploy $host --nix) first." >&2
  exit 1
fi

echo "🔄 Syncing $rel with $host..."
# -servercmd: the remote's non-interactive SSH PATH may lack Nix's bin dir
# -ignore: git metadata (this repo's and the services submodule's .git file),
#          build links, macOS metadata and decrypted secrets stay local; only
#          the encrypted *.sops.yaml next to them travel
exec unison "$repo" "ssh://$host/$rel" \
  "${batch[@]}" \
  -servercmd /run/current-system/sw/bin/unison \
  -times -links true -fastcheck true \
  -ignore 'Name .git' \
  -ignore 'Name result' \
  -ignore 'Name result-*' \
  -ignore 'Name .direnv' \
  -ignore 'Name .DS_Store' \
  -ignore 'Regex .*/secrets/.*' \
  -ignorenot 'Regex .*/secrets/.*\.sops\.yaml' \
  "$@"
