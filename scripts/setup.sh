#!/usr/bin/env bash
# -------------------------------------------------------------------
# setup.sh — Bootstrap a fresh NixOS machine from your dotfiles
# -------------------------------------------------------------------
# Designed to be curl'd and piped into bash from a fresh NixOS install.
#
# Usage:
#   curl -sL https://setup.leazirondi.com.br/nix-setup | bash -s <hostname>
#
# Or download first:
#   curl -sLO https://setup.leazirondi.com.br/nix-setup
#   chmod +x nix-setup && sudo ./nix-setup <hostname>
#
# Examples:
#   curl -sL https://setup.leazirondi.com.br/nix-setup | sudo bash -s nitro5
#
# What it does:
#   1. Enables Nix Flakes
#   2. Installs git (if missing)
#   3. Clones your dotfiles repo
#   4. Generates hardware-configuration.nix (if not already in repo)
#   5. Runs nixos-rebuild switch --flake .#<hostname>
#   6. Sets up user dotfiles (stow or Home Manager, depending on your config)
#   7. Installs Oh My Zsh + plugins
#   8. Reminds you about post-install tasks (Tailscale, secrets, etc.)
# -------------------------------------------------------------------
set -eo pipefail

# ========================
# Configuration
# ========================
# TODO: Update this to your actual GitHub username/repo
DOTFILES_REPO="https://github.com/zirondi/dotfiles.git"
DOTFILES_DIR="/root/dotfiles"   # Cloned as root during install; symlinked to user home after
USER_NAME="zirondi"

# ========================
# Colors & Logging
# ========================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

log()     { echo -e "${BLUE}[setup]${NC} $*"; }
warn()    { echo -e "${YELLOW}[warn]${NC} $*"; }
error()   { echo -e "${RED}[error]${NC} $*" >&2; exit 1; }
success() { echo -e "${GREEN}[✅]${NC} $*"; }

# ========================
# Banner
# ========================
echo -e "${CYAN}${BOLD}"
echo "  ╔══════════════════════════════════════════╗"
echo "  ║        NixOS Bootstrap Installer         ║"
echo "  ║       github.com/zirondi/dotfiles         ║"
echo "  ╚══════════════════════════════════════════╝"
echo -e "${NC}"

# ========================
# Validation
# ========================
HOSTNAME="${1:?❌ Please provide a hostname. Usage: $0 <hostname>}"

# Must be NixOS
if [[ -f /etc/os-release ]]; then
  grep -qi "nixos" /etc/os-release || error "This script is designed for NixOS only."
else
  error "Cannot detect OS. Are you on NixOS?"
fi

# Must be root (or sudo)
if [[ $EUID -ne 0 ]]; then
  error "Please run as root: sudo bash -s $HOSTNAME"
fi

log "Starting bootstrap for hostname: ${BOLD}$HOSTNAME${NC}"
echo ""

# ========================
# Step 1: Enable Flakes
# ========================
log "Step 1/7: Enabling Nix Flakes..."
mkdir -p /etc/nix
if ! grep -q "experimental-features" /etc/nix/nix.conf 2>/dev/null; then
  echo "experimental-features = nix-command flakes" >> /etc/nix/nix.conf
  success "Flakes enabled"
else
  log "Flakes already enabled, skipping"
fi

# ========================
# Step 2: Install git
# ========================
log "Step 2/7: Ensuring git is available..."
if ! command -v git &>/dev/null; then
  nix-env -iA nixos.git
  success "Git installed"
else
  log "Git already available, skipping"
fi

# ========================
# Step 3: Clone dotfiles
# ========================
log "Step 3/7: Cloning dotfiles repository..."
if [[ -d "$DOTFILES_DIR" ]]; then
  warn "Dotfiles directory already exists at $DOTFILES_DIR"
  log "Pulling latest changes..."
  git -C "$DOTFILES_DIR" pull --ff-only || warn "Pull failed — continuing with existing state"
else
  git clone "$DOTFILES_REPO" "$DOTFILES_DIR"
  success "Dotfiles cloned to $DOTFILES_DIR"
fi

# ========================
# Step 4: Hardware configuration
# ========================
log "Step 4/7: Checking hardware configuration..."
HOST_DIR="$DOTFILES_DIR/hosts/$HOSTNAME"
HW_CONFIG="$HOST_DIR/hardware-configuration.nix"

if [[ ! -d "$HOST_DIR" ]]; then
  warn "No host directory found at $HOST_DIR"
  warn "Creating directory and generating hardware config..."
  mkdir -p "$HOST_DIR"
fi

# Generate hardware config if missing or if it's the placeholder template
if [[ ! -f "$HW_CONFIG" ]] || grep -q "TEMPLATE" "$HW_CONFIG" 2>/dev/null; then
  log "Generating hardware configuration for this machine..."
  nixos-generate-config --show-hardware-config > "$HW_CONFIG"
  success "Hardware config generated at $HW_CONFIG"

  echo ""
  warn "⚠️  A new hardware-configuration.nix was generated."
  warn "    You should commit this to your dotfiles repo after bootstrap."
  echo ""
else
  log "Using existing hardware configuration for '$HOSTNAME'"
fi

# ========================
# Step 5: Verify host exists in flake
# ========================
log "Step 5/7: Verifying flake host '$HOSTNAME' exists..."
if ! grep -q "$HOSTNAME" "$DOTFILES_DIR/flake.nix" 2>/dev/null; then
  echo ""
  warn "⚠️  Hostname '$HOSTNAME' not found in flake.nix!"
  warn "    You may need to add it manually before the next step."
  warn "    Expected entry: nixosConfigurations.$HOSTNAME = ..."
  echo ""
  read -rp "Continue anyway? (y/N) " -n 1 REPLY
  echo ""
  [[ "$REPLY" =~ ^[Yy]$ ]] || error "Aborting. Add '$HOSTNAME' to flake.nix and re-run."
fi

# ========================
# Step 6: Apply NixOS configuration
# ========================
log "Step 6/7: Building and applying NixOS configuration..."
log "This may take a while on first run (downloading all packages)..."
echo ""

nixos-rebuild switch --flake "$DOTFILES_DIR#$HOSTNAME" || {
  echo ""
  error "nixos-rebuild failed! Check the output above for errors."
}

echo ""
success "NixOS configuration applied!"

# ========================
# Step 7: User environment setup
# ========================
log "Step 7/7: Setting up user environment..."
USER_HOME="/home/$USER_NAME"

if [[ -d "$USER_HOME" ]]; then
  # Symlink dotfiles to user home
  ln -sfn "$DOTFILES_DIR" "$USER_HOME/dotfiles"
  chown -h "$USER_NAME:users" "$USER_HOME/dotfiles"
  success "Dotfiles linked to $USER_HOME/dotfiles"

  # If using stow (non-Home Manager path)
  # Home Manager users: your configs are already applied by nixos-rebuild
  if ! grep -q "home-manager" "$DOTFILES_DIR/flake.nix" 2>/dev/null; then
    log "Home Manager not detected — falling back to stow..."
    if command -v stow &>/dev/null && [[ -d "$DOTFILES_DIR/configs" ]]; then
      cd "$DOTFILES_DIR"
      stow -d configs -t "$USER_HOME" zsh kitty starship 2>/dev/null || \
        warn "Some stow targets may not exist yet (this is fine)"
      success "Stow configurations applied"
    fi
  else
    log "Home Manager detected — dotfiles managed declaratively ✨"
  fi

  # Home manager takes care of Zsh completely.
else
  warn "User home $USER_HOME not found — user may not have been created yet"
  warn "Run this script again after first reboot if needed"
fi

# ========================
# Done!
# ========================
echo ""
echo -e "${GREEN}${BOLD}══════════════════════════════════════════════${NC}"
echo -e "${GREEN}${BOLD}  ✅  Bootstrap complete!                     ${NC}"
echo -e "${GREEN}${BOLD}══════════════════════════════════════════════${NC}"
echo ""
log "Next steps:"
echo "  1. Reboot:            sudo reboot"
echo "  2. Log in as:         $USER_NAME"
echo "  3. Change password:   passwd"

# Tailscale reminder
if grep -rq "tailscale" "$DOTFILES_DIR/hosts/" 2>/dev/null; then
  echo "  4. Auth Tailscale:    sudo tailscale up"
fi

# Git commit reminder
echo ""
warn "Don't forget to commit any generated files (hardware-configuration.nix)"
warn "back to your dotfiles repo!"
