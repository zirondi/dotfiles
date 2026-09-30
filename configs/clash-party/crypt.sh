#!/usr/bin/env bash
# -------------------------------------------------------------------
# crypt.sh — Manage encryption/decryption for Clash Party / Mihomo
# -------------------------------------------------------------------
# Usage:
#   ./crypt.sh [--init]     # Create dummy config and encrypt if none exists
#   ./crypt.sh --encrypt|-e # Encrypt config.yaml -> config.yaml.age
#   ./crypt.sh --decrypt|-d # Decrypt config.yaml.age -> config.yaml
# -------------------------------------------------------------------
set -eo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_RAW="$SCRIPT_DIR/config.yaml"
CONFIG_ENC="$SCRIPT_DIR/config.yaml.age"
KEY_FILE="${SOPS_AGE_KEY_FILE:-$HOME/.config/sops/age/keys.txt}"

get_admin_age_pubkey() {
  if [ -f "$KEY_FILE" ]; then
    grep -o 'age1[a-z0-9]*' "$KEY_FILE" | head -n 1
    return 0
  fi
  # Fallback to repository default admin key
  echo "age1d2njeymz4gafrp8wt0xnc3kvz9flw9cwanddjktrnyt38ye96chsdffk64"
}

ACTION="${1:-init}"

case "$ACTION" in
  --decrypt|-d|decrypt)
    if [ ! -f "$CONFIG_ENC" ]; then
      echo "❌ Encrypted file not found: $CONFIG_ENC"
      exit 1
    fi
    if [ ! -f "$KEY_FILE" ]; then
      echo "❌ Age key file not found: $KEY_FILE"
      exit 1
    fi
    echo "🔓 Decrypting $CONFIG_ENC -> $CONFIG_RAW..."
    age -d -i "$KEY_FILE" -o "$CONFIG_RAW" "$CONFIG_ENC"
    echo "✅ Decrypted to $CONFIG_RAW (Remember: this file is gitignored for security)."
    exit 0
    ;;

  --encrypt|-e|encrypt)
    if [ ! -f "$CONFIG_RAW" ]; then
      echo "❌ Plain text file not found: $CONFIG_RAW"
      exit 1
    fi
    PUBKEY=$(get_admin_age_pubkey)
    echo "🔒 Encrypting $CONFIG_RAW -> $CONFIG_ENC (using $PUBKEY)..."
    age -r "$PUBKEY" -o "$CONFIG_ENC" "$CONFIG_RAW"
    echo "✅ Successfully encrypted to $CONFIG_ENC (safe to commit to Git)."
    exit 0
    ;;

  --init|init|"")
    PUBKEY=$(get_admin_age_pubkey)

    if [ ! -f "$CONFIG_RAW" ] && [ ! -f "$CONFIG_ENC" ]; then
      echo "⚙️  Initializing Clash Party configuration in $SCRIPT_DIR..."
      cat > "$CONFIG_RAW" <<'EOF'
# ===================================================================
# Clash Party / Mihomo Configuration
# Manage this file with:
#   Encrypt: ./crypt.sh --encrypt
#   Decrypt: ./crypt.sh --decrypt
# ===================================================================
port: 7890
socks-port: 7891
allow-lan: false
mode: rule
log-level: info

# Intercept traffic at macOS level
tun:
  enable: true
  stack: mixed
  auto-route: true
  auto-detect-interface: true

proxies:
  - name: "Tunel-1"
    type: wireguard
    server: 203.0.113.10          # Endpoint IP/Host do Peer
    port: 51820                   # Porta do Peer
    ip: 10.0.0.2                  # Seu Address da [Interface]
    private-key: "DUMMY_PRIVATE_KEY_1"
    public-key: "DUMMY_PUBLIC_KEY_1"
    dns: [1.1.1.1]
    udp: true

  - name: "Tunel-2"
    type: wireguard
    server: 198.51.100.20
    port: 51820
    ip: 10.10.0.2
    private-key: "DUMMY_PRIVATE_KEY_2"
    public-key: "DUMMY_PUBLIC_KEY_2"
    dns: [1.1.1.1]
    udp: true

rules:
  # Example: Route Discord (main app + all helpers) through Tunel-1
  - PROCESS-PATH-REGEX,.*Discord\.app.*,Tunel-1

  # Final Rule: All remaining traffic bypasses the VPN (direct to normal internet)
  - MATCH,DIRECT
EOF
      echo "   📄 Created dummy $CONFIG_RAW"
      echo "   🔒 Encrypting initial dummy to $CONFIG_ENC..."
      age -r "$PUBKEY" -o "$CONFIG_ENC" "$CONFIG_RAW"
      echo "   ✅ Created $CONFIG_ENC"
    elif [ -f "$CONFIG_ENC" ] && [ ! -f "$CONFIG_RAW" ]; then
      echo "   ℹ️  $CONFIG_ENC already exists. To decrypt for editing, run:"
      echo "      ./crypt.sh --decrypt"
    else
      echo "   ℹ️  $CONFIG_RAW already exists. To re-encrypt after editing, run:"
      echo "      ./crypt.sh --encrypt"
    fi

    echo ""
    echo "🎉 Clash Party setup ready!"
    echo "   - Unencrypted YAML is gitignored (will never be accidentally committed)."
    echo "   - To encrypt your changes: ./crypt.sh --encrypt"
    echo "   - To decrypt to edit:      ./crypt.sh --decrypt"
    exit 0
    ;;

  *)
    echo "❌ Unknown action: $ACTION"
    echo "Usage: ./crypt.sh [--init|--encrypt|--decrypt]"
    exit 1
    ;;
esac
