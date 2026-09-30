#!/usr/bin/env bash
# -------------------------------------------------------------------
# sync-skills.sh — Synchronize AI Agent Skills via skills.sh (npm)
# -------------------------------------------------------------------
# Usage:
#   ./scripts/sync-skills.sh
# -------------------------------------------------------------------
set -eo pipefail

AGENTS_DIR="${HOME}/.agents"
LOCKFILE="${AGENTS_DIR}/.skill-lock.json"

if [ ! -f "$LOCKFILE" ]; then
  echo "❌ Skill lockfile not found at $LOCKFILE"
  echo "   Make sure your dotfiles are linked via Home Manager."
  exit 1
fi

echo "🔄 Syncing global AI Agent skills from $LOCKFILE using skills.sh..."
npx --yes skills update -g -y

echo ""
echo "📋 Currently installed global skills:"
npx --yes skills ls -g

echo ""
echo "✅ AI Agent skills successfully synced!"
