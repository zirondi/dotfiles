#!/usr/bin/env bash
# -------------------------------------------------------------------
# backup-volumes.sh — Backup all service volumes to Google Drive
# -------------------------------------------------------------------
# Usage:
#   ./backup-volumes.sh              # Sync all volumes
#   ./backup-volumes.sh --dry-run    # Preview without changes
#
# Files changed or deleted since the last run are moved to
# <remote>-archive/<timestamp>/ instead of being lost.
#
# Environment:
#   BACKUP_REMOTE  — rclone destination (default: gdrive:backups/<hostname>)
#   BACKUP_SOURCE  — directory to back up (default: ~/volumes)
#   BACKUP_LOG     — log file (default: ~/logs/rclone-backup.log)
# -------------------------------------------------------------------
set -euo pipefail

REMOTE="${BACKUP_REMOTE:-gdrive:backups/$(hostname -s)}"
SOURCE="${BACKUP_SOURCE:-${HOME}/volumes}"
LOG="${BACKUP_LOG:-${HOME}/logs/rclone-backup.log}"
DATE=$(date +%Y-%m-%d_%H%M)
DRY_RUN=()

if [ "${1:-}" = "--dry-run" ]; then
  DRY_RUN=(--dry-run)
  echo "[$DATE] DRY RUN — no changes will be made."
fi

mkdir -p "$(dirname "$LOG")"

echo "[$DATE] Starting rclone backup..." | tee -a "$LOG"

rclone sync "$SOURCE" "$REMOTE" \
  ${DRY_RUN[@]+"${DRY_RUN[@]}"} \
  --backup-dir "${REMOTE}-archive/${DATE}" \
  --transfers 4 \
  --checkers 8 \
  --log-file "$LOG" \
  --log-level INFO \
  --exclude "*.log" \
  --exclude "*.tmp" \
  --exclude "*.sock" \
  --stats-one-line \
  2>&1

echo "[$DATE] Backup completed." | tee -a "$LOG"
