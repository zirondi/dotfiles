#!/usr/bin/env bash
# -------------------------------------------------------------------
# deploy.sh — Build and deploy NixOS configs and Compose Services
# -------------------------------------------------------------------
# Usage:
#   ./deploy.sh <flake-host> <target-ssh> [options]
#
# Options:
#   --all       (default) Deploy NixOS rebuild AND Compose services
#   --nix       Only run NixOS rebuild
#   --svc       Only sync and restart Compose services
#
# Examples:
#   ./deploy.sh helsinki helsinki
##   ./deploy.sh <flake-host> [target-ssh] [options]
#
# Options:
#   --all       (default) Deploy NixOS rebuild AND Compose services
#   --nix       Only run NixOS rebuild
#   --svc       Only sync and restart Compose services
#
# Examples:
#   ./deploy.sh nitro5                        # Uses flake #nitro5 and SSH alias 'nitro5'
#   ./deploy.sh hetzner --nix                 # Only NixOS rebuild for 'hetzner'
#   ./deploy.sh rpi3 --svc pihole             # Sync & restart pihole on 'rpi3'
#   ./deploy.sh nitro5 root@10.0.0.80         # Explicit SSH override
# -------------------------------------------------------------------
set -eo pipefail

FLAKE_HOST="${1:?❌ Usage: ./deploy.sh <flake-host> [target-ssh] [--all|--nix|--svc [svc1 svc2...]]}"
shift 1

# If target is omitted or is a flag, default TARGET to FLAKE_HOST (resolved via ~/.ssh/config)
if [[ $# -eq 0 || "$1" == --* ]]; then
  TARGET="$FLAKE_HOST"
else
  TARGET="$1"
  shift 1
fi

MODE="--all"
SERVICES=()

if [ $# -gt 0 ]; then
  MODE="$1"
  shift
  if [[ "$MODE" == "--svc" || "$MODE" == "--all" ]]; then
    SERVICES=("$@")
  fi
fi
DOTFILES_FLAKE="${DOTFILES_FLAKE:-$HOME/dotfiles}"

if [[ ! -f "$DOTFILES_FLAKE/flake.nix" ]]; then
  echo "❌ No flake.nix found at $DOTFILES_FLAKE"
  exit 1
fi

# Locate services directory: check custom env, or sibling workspace folders, or submodule
find_service_dir() {
  local svc_name="$1"
  local candidates=(
    "${SERVICES_DIR:-}"
    "$DOTFILES_FLAKE/services/$svc_name"
    "$HOME/repos/github/me/public/services/$svc_name"
    "$HOME/repos/github/me/private/private-services/$svc_name"
  )
  for cand in "${candidates[@]}"; do
    if [ -n "$cand" ] && [ -d "$cand" ]; then
      echo "$cand"
      return 0
    fi
  done
  return 1
}

# Resolve global services base for --all
if [ -n "${SERVICES_DIR:-}" ] && [ -d "$SERVICES_DIR" ]; then
  SERVICES_BASE="$SERVICES_DIR"
elif [ -d "$DOTFILES_FLAKE/services" ] && [ "$(ls -A "$DOTFILES_FLAKE/services" 2>/dev/null)" ]; then
  SERVICES_BASE="$DOTFILES_FLAKE/services"
elif [ -d "$HOME/repos/github/me/public/services" ]; then
  SERVICES_BASE="$HOME/repos/github/me/public/services"
else
  SERVICES_BASE="$DOTFILES_FLAKE/services"
fi

echo "🚀 Starting deploy for $FLAKE_HOST to $TARGET (Mode: $MODE)"

if [[ "$MODE" == "--all" || "$MODE" == "--nix" ]]; then
  echo "🔨 [1/2] Rebuilding NixOS configuration..."
  
  if command -v nixos-rebuild >/dev/null 2>&1; then
    NIXOS_REBUILD_CMD="nixos-rebuild"
  else
    echo "   (Using nix run nixpkgs#nixos-rebuild since native command is not found)"
    NIXOS_REBUILD_CMD="nix run nixpkgs#nixos-rebuild --"
  fi

  $NIXOS_REBUILD_CMD switch \
    --flake "${DOTFILES_FLAKE}#${FLAKE_HOST}" \
    --target-host "$TARGET" \
    --build-host "$TARGET" \
    --elevate=sudo \
    --no-reexec
  
  echo "✅ NixOS rebuild successful!"
fi

if [[ "$MODE" == "--all" || "$MODE" == "--svc" ]]; then
  echo "🐳 [2/2] Syncing Compose services..."
  
  if [ ${#SERVICES[@]} -eq 0 ]; then
    echo "   Syncing all services from $SERVICES_BASE to $TARGET:~/services/..."
    rsync -avz --delete -e "ssh" \
      --exclude="*/node_modules/" \
      --exclude="*/.next/" \
      --exclude="*/.git/" \
      --include="*/" \
      --include="*/secrets/*.sops.yaml" \
      --include="*/secrets/*.sops" \
      --include="*/secrets/.gitkeep" \
      --exclude="*/secrets/*" \
      "$SERVICES_BASE/" "$TARGET:~/services/"
      
    echo "✅ All services synced! Manual start required since no specific services were targeted."
  else
    for SVC in "${SERVICES[@]}"; do
      SVC_LOCAL_DIR=$(find_service_dir "$SVC") || {
        echo "⚠️  Service '$SVC' not found in services directories. Skipping..."
        continue
      }
      
      echo "   🔍 Validating secrets for $SVC (source: $SVC_LOCAL_DIR)..."
      SECRETS=$(grep -Eo "file: \./secrets/[a-zA-Z0-9_-]+" "$SVC_LOCAL_DIR/compose.yml" | awk -F'/' '{print $NF}' || true)
      for SEC in $SECRETS; do
        if [ ! -f "$SVC_LOCAL_DIR/secrets/$SEC.sops.yaml" ] && [ ! -f "$SVC_LOCAL_DIR/secrets/$SEC.sops" ]; then
          echo "❌ Missing SOPS file for required secret '$SEC' in $SVC."
          echo "   Run './scripts/init-secrets.sh $SVC' to generate it!"
          exit 1
        fi
      done
      
      echo "   Syncing $SVC to $TARGET:~/services/$SVC/..."
      ssh "$TARGET" "mkdir -p ~/services/$SVC"
      
      rsync -avz --delete -e "ssh" \
        --exclude="node_modules/" \
        --exclude=".next/" \
        --exclude=".git/" \
        --include="*/" \
        --include="secrets/*.sops.yaml" \
        --include="secrets/*.sops" \
        --include="secrets/.gitkeep" \
        --exclude="secrets/*" \
        "$SVC_LOCAL_DIR/" "$TARGET:~/services/$SVC/"
        
      echo "   🔐 Decrypting SOPS secrets for $SVC..."
      ssh "$TARGET" "bash -c '
        cd ~/services/$SVC
        if ls secrets/*.sops.yaml 1> /dev/null 2>&1; then
          for sops_file in secrets/*.sops.yaml; do
            plain_file=\"\${sops_file%.sops.yaml}\"
            echo \"      -> Decrypting \$sops_file to \$plain_file\"
            sudo bash -c \"ssh-to-age -private-key -i /etc/ssh/ssh_host_ed25519_key > /tmp/sops_age.txt\"
            rm -f \"\$plain_file\"
            sudo env SOPS_AGE_KEY_FILE=/tmp/sops_age.txt sops --output-type binary -d \"\$sops_file\" > \"\$plain_file\"
            chmod 444 \"\$plain_file\"
            sudo rm -f /tmp/sops_age.txt
          done
        fi
      '"
      
      echo "   🚀 Starting $SVC..."
      ssh "$TARGET" "bash -c '
        cd ~/services/$SVC
        if [ -f secrets/tunnel_token ]; then
          export TUNNEL_TOKEN=\$(cat secrets/tunnel_token)
        fi
        if [ -f secrets/tunnel_token_unesp ]; then
          export TUNNEL_TOKEN_UNESP=\$(cat secrets/tunnel_token_unesp)
        fi
        export DOCKER_SOCK=\"/run/user/\$(id -u)/podman/podman.sock\"
        podman-compose up -d --build
      '"
    done
  fi
fi

echo "🎉 Deploy finished!"
