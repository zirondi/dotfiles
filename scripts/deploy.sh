#!/usr/bin/env bash
# -------------------------------------------------------------------
# deploy.sh — Build and deploy NixOS configs and Compose Services
# -------------------------------------------------------------------
# Usage:
#   ./deploy.sh <flake-host> [target-ssh] [options]
#
# Options:
#   --all       (default) Deploy NixOS rebuild AND Compose services
#   --nix       Only run NixOS rebuild
#   --svc       Only the stack upload: copy the stacks and restart the named ones
#   --build-on local|target
#               Where the NixOS system is built. `local` uses the container
#               builder on this machine (scripts/lib/builder.sh) and copies
#               the result; `target` builds on the host itself. Default:
#               local when the host has this machine's CPU architecture
#               (e.g. rpi3 from an Apple Silicon Mac), target otherwise.
#   --build-only
#               Build with the local builder and stop (no copy, no switch)
#
# With no service names, --all/--svc copy every stack from the first
# services root to the host WITHOUT deleting anything remote (stacks
# deployed from other roots, e.g. private-services, are left alone).
#
# Environment: see scripts/lib/common.sh (DOTFILES_FLAKE, SERVICES_PATH)
#
# Examples:
#   ./deploy.sh nitro5                        # Uses flake #nitro5 and SSH alias 'nitro5'
#   ./deploy.sh hetzner --nix                 # Only NixOS rebuild for 'hetzner'
#   ./deploy.sh rpi3 --svc pihole             # Upload and restart pihole on 'rpi3'
#   ./deploy.sh nitro5 root@10.0.0.80         # Explicit SSH override
#   ./deploy.sh rpi3 root@rpi3 --nix          # Built on this Mac, copied to the Pi
# -------------------------------------------------------------------
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"
source "$(dirname "${BASH_SOURCE[0]}")/lib/builder.sh"

FLAKE_HOST="${1:?❌ Usage: ./deploy.sh <flake-host> [target-ssh] [--all|--nix|--svc [svc1 svc2...]]}"
shift 1

# If target is omitted or is a flag, default TARGET to FLAKE_HOST (resolved via ~/.ssh/config)
if [[ $# -eq 0 || "$1" == --* ]]; then
  TARGET="$FLAKE_HOST"
else
  TARGET="$1"
  shift 1
fi

# Pull the build options out of the argument list, wherever they appear
BUILD_ON=""
BUILD_ONLY=false
ARGS=()
while [ $# -gt 0 ]; do
  case "$1" in
    --build-on)
      BUILD_ON="${2:?❌ --build-on needs 'local' or 'target'}"
      shift 2
      ;;
    --build-only)
      BUILD_ONLY=true
      BUILD_ON="local"
      shift
      ;;
    *)
      ARGS+=("$1")
      shift
      ;;
  esac
done
set -- ${ARGS[@]+"${ARGS[@]}"}

case "$BUILD_ON" in
  ""|local|target) ;;
  *)
    echo "❌ Unknown --build-on value '$BUILD_ON'. Expected 'local' or 'target'."
    exit 1
    ;;
esac

MODE="--all"
SERVICES=()

if [ $# -gt 0 ]; then
  MODE="$1"
  shift
  case "$MODE" in
    --all|--svc) SERVICES=("$@") ;;
    --nix) ;;
    *)
      echo "❌ Unknown option '$MODE'. Expected --all, --nix or --svc."
      exit 1
      ;;
  esac
fi

if [[ ! -f "$DOTFILES_FLAKE/flake.nix" ]]; then
  echo "❌ No flake.nix found at $DOTFILES_FLAKE"
  exit 1
fi

if $BUILD_ONLY; then
  MODE="--nix"
fi

echo "🚀 Starting deploy for $FLAKE_HOST to $TARGET (Mode: $MODE)"

if [[ "$MODE" == "--all" || "$MODE" == "--nix" ]]; then
  FLAKE_ATTR="${DOTFILES_FLAKE}#nixosConfigurations.${FLAKE_HOST}"

  # Hosts sharing this machine's architecture are built here, not on the target
  if [ -z "$BUILD_ON" ]; then
    HOST_SYSTEM="$(nix eval --raw "${FLAKE_ATTR}.pkgs.stdenv.hostPlatform.system")"
    if [ "$(uname -s)" = "Darwin" ] && [ "$(builder_system || true)" = "$HOST_SYSTEM" ]; then
      BUILD_ON="local"
    else
      BUILD_ON="target"
    fi
  fi
fi

if [[ ( "$MODE" == "--all" || "$MODE" == "--nix" ) && "$BUILD_ON" == "local" ]]; then
  echo "🔨 [1/2] Building NixOS configuration in the local builder..."

  DRV="$(nix eval --raw "${FLAKE_ATTR}.config.system.build.toplevel.drvPath")"
  OUT="$(builder_build "$DRV" "$FLAKE_HOST")"
  echo "   ✅ Built $OUT"

  if $BUILD_ONLY; then
    echo "🎉 Build finished (--build-only: nothing was copied or activated)."
    exit 0
  fi

  builder_copy_to "$OUT" "$TARGET"

  echo "   🔁 Activating on $TARGET..."
  # Same steps as `nixos-rebuild switch`: set the system profile, then switch
  # inside a transient unit so a dropped SSH session cannot interrupt it.
  ssh -t "$TARGET" "
    set -e
    SUDO=''
    [ \"\$(id -u)\" = 0 ] || SUDO='sudo'
    \$SUDO nix-env -p /nix/var/nix/profiles/system --set '$OUT'
    \$SUDO systemd-run -E LOCALE_ARCHIVE -E NIXOS_INSTALL_BOOTLOADER=0 \\
      --collect --no-ask-password --pipe --quiet --service-type=exec \\
      --unit=nixos-rebuild-switch-to-configuration --wait \\
      '$OUT/bin/switch-to-configuration' switch
  "

  echo "✅ NixOS rebuild successful!"
elif [[ "$MODE" == "--all" || "$MODE" == "--nix" ]]; then
  echo "🔨 [1/2] Rebuilding NixOS configuration on $TARGET..."
  
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
  echo "🐳 [2/2] Stack upload..."
  
  if [ ${#SERVICES[@]} -eq 0 ]; then
    SERVICES_BASE="$(services_roots | head -n 1)"
    if [ -z "$SERVICES_BASE" ]; then
      echo "❌ No services directory found (checked: ${SERVICES_DIR:-} $SERVICES_PATH)"
      exit 1
    fi

    echo "   Uploading every stack from $SERVICES_BASE to $TARGET:~/services/..."
    # No --delete here: the host also runs stacks that live in other roots.
    rsync -avz -e "ssh" \
      --exclude="*/node_modules/" \
      --exclude="*/.next/" \
      --exclude="*/.git/" \
      --include="*/" \
      --include="*/secrets/*.sops.yaml" \
      --include="*/secrets/*.sops" \
      --include="*/secrets/.gitkeep" \
      --exclude="*/secrets/*" \
      "$SERVICES_BASE/" "$TARGET:~/services/"
      
    echo "✅ All stacks uploaded. Nothing was started, since no stack was named."
  else
    for SVC in "${SERVICES[@]}"; do
      SVC_LOCAL_DIR=$(find_service_dir "$SVC") || {
        echo "⚠️  Service '$SVC' not found in services directories. Skipping..."
        continue
      }
      
      echo "   🔍 Validating secrets for $SVC (source: $SVC_LOCAL_DIR)..."
      SECRETS=$(compose_secret_names "$SVC_LOCAL_DIR/compose.yml")
      for SEC in $SECRETS; do
        if [ ! -f "$SVC_LOCAL_DIR/secrets/$SEC.sops.yaml" ] && [ ! -f "$SVC_LOCAL_DIR/secrets/$SEC.sops" ]; then
          echo "❌ Missing SOPS file for required secret '$SEC' in $SVC."
          echo "   Run './scripts/init-secrets.sh $SVC' to generate it!"
          exit 1
        fi
      done
      
      echo "   Uploading $SVC to $TARGET:~/services/$SVC/..."
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
        set -e
        cd ~/services/$SVC
        if ls secrets/*.sops.yaml 1> /dev/null 2>&1; then
          for sops_file in secrets/*.sops.yaml; do
            plain_file=\"\${sops_file%.sops.yaml}\"
            echo \"      -> Decrypting \$sops_file to \$plain_file\"
            rm -f \"\$plain_file\"
            # The age identity is derived from the SSH host key and only ever lives
            # in the root process environment (never written to disk).
            sudo bash -c \"SOPS_AGE_KEY=\\\$(ssh-to-age -private-key -i /etc/ssh/ssh_host_ed25519_key) sops --output-type binary -d \$sops_file\" > \"\$plain_file\"
            chmod 444 \"\$plain_file\"
          done
        fi
      '"
      
      echo "   🚀 Starting $SVC..."
      ssh "$TARGET" "bash -c '
        set -e
        cd ~/services/$SVC
        if [ -f secrets/tunnel_token ]; then
          export TUNNEL_TOKEN=\$(cat secrets/tunnel_token)
        fi
        if [ -f secrets/tunnel_token_unesp ]; then
          export TUNNEL_TOKEN_UNESP=\$(cat secrets/tunnel_token_unesp)
        fi
        export DOCKER_SOCK=\"/run/user/\$(id -u)/podman/podman.sock\"
        export INSTANCE_HOST=\"$FLAKE_HOST\"
        # Addresses the Traefik entrypoints are bound to (empty when the host
        # has no tailnet address; only the traefik stack requires them)
        export TAILNET_IP=\"\$(tailscale ip -4 2>/dev/null | head -n 1)\"
        export PUBLIC_IP=\"\$(ip -4 route get 1.1.1.1 2>/dev/null | sed -n \"s/.* src \\([0-9.]*\\).*/\\1/p\")\"
        podman-compose up -d --build
      '"
    done
  fi
fi

echo "🎉 Deploy finished!"
