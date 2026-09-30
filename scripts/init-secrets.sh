#!/usr/bin/env bash
# -------------------------------------------------------------------
# init-secrets.sh — Initialize secrets stubs for Compose Services
# -------------------------------------------------------------------
# Usage:
#   ./scripts/init-secrets.sh <service-name>
# -------------------------------------------------------------------
set -eo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

SVC="${1:?❌ Usage: ./scripts/init-secrets.sh <service-name>}"

# Locate service directory: check current repo services/, sibling workspace folders, or custom env
find_service_dir() {
  local svc_name="$1"
  local candidates=(
    "${SERVICES_DIR:-}"
    "$REPO_ROOT/services/$svc_name"
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

SVC_DIR=$(find_service_dir "$SVC" || true)

if [ -z "$SVC_DIR" ] || [ ! -d "$SVC_DIR" ]; then
  echo "❌ Service '$SVC' not found in services directories."
  exit 1
fi

if [ ! -f "$SVC_DIR/compose.yml" ]; then
  echo "❌ No compose.yml found in $SVC_DIR."
  exit 1
fi

echo "🔍 Scanning $SVC_DIR/compose.yml for secrets..."

# Extract all secret filenames declared using `file: ./secrets/XYZ`
SECRETS=$(grep -Eo "file: \./secrets/[a-zA-Z0-9_-]+" "$SVC_DIR/compose.yml" | awk -F'/' '{print $NF}')

if [ -z "$SECRETS" ]; then
  echo "✅ No local secrets found in compose.yml for $SVC."
  exit 0
fi

mkdir -p "$SVC_DIR/secrets"
touch "$SVC_DIR/secrets/.gitkeep"

CREATED_ANY=false

for SEC in $SECRETS; do
  SOPS_FILE="$SVC_DIR/secrets/$SEC.sops.yaml"
  
  if [ ! -f "$SOPS_FILE" ]; then
    echo "⚙️  Initializing SOPS stub for: $SEC"
    # Create the plain text stub at the final path
    echo "TODO_REPLACEME" > "$SOPS_FILE"
    
    # Encrypt it in place using binary type so it preserves raw text upon decryption
    sops -e -i --input-type binary "$SOPS_FILE"
    
    echo "   ✅ Created $SOPS_FILE."
    CREATED_ANY=true
  else
    echo "   ⏭️  $SOPS_FILE already exists, skipping."
  fi
done

if [ "$CREATED_ANY" = true ]; then
  echo ""
  echo "🎉 Stubs created! To edit them with your real values, run:"
  echo "   sops $SVC_DIR/secrets/<secret_name>.sops.yaml"
fi
