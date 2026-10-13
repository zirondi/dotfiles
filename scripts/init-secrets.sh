#!/usr/bin/env bash
# -------------------------------------------------------------------
# init-secrets.sh — Initialize secrets stubs for Compose Services
# -------------------------------------------------------------------
# Usage:
#   ./scripts/init-secrets.sh <service-name>
# -------------------------------------------------------------------
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"

SVC="${1:?❌ Usage: ./scripts/init-secrets.sh <service-name>}"

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
SECRETS=$(compose_secret_names "$SVC_DIR/compose.yml")

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
    # sops does not find the config when run from outside the services tree,
    # and a failed run must not leave the plain text stub behind
    if ! sops --config "$(dirname "$SVC_DIR")/.sops.yaml" -e -i --input-type binary "$SOPS_FILE"; then
      rm -f "$SOPS_FILE"
      echo "❌ Could not encrypt $SOPS_FILE."
      exit 1
    fi
    
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
