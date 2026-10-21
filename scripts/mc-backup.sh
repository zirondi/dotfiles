#!/usr/bin/env bash
# -------------------------------------------------------------------
# mc-backup.sh — Restic backup of a Minecraft server running in screen
# -------------------------------------------------------------------
# Meant for a plain Debian host (not managed by this flake), run as root
# by configs/minecraft/mc-backup.service. While the copy runs, the world
# is flushed and saving is paused, so Restic never reads half-written
# region files; saving is turned back on even if the backup fails.
#
# Environment (EnvironmentFile=/etc/mc-backup/env):
#   MC_DIR                server directory (world, configs, plugins)
#   MC_USER               user that owns the screen session
#   MC_SCREEN             screen session name
#   RESTIC_REPOSITORY     e.g. rclone:gdrive:backups/minecraft
#   RESTIC_PASSWORD_FILE  file with the repository password
#   RCLONE_CONFIG         rclone.conf with the `gdrive` remote
#
# Retention: 7 daily, 4 weekly, 12 monthly snapshots.
# -------------------------------------------------------------------
set -euo pipefail

: "${MC_DIR:?MC_DIR is not set}"
: "${MC_USER:?MC_USER is not set}"
: "${MC_SCREEN:?MC_SCREEN is not set}"
: "${RESTIC_REPOSITORY:?RESTIC_REPOSITORY is not set}"
: "${RESTIC_PASSWORD_FILE:?RESTIC_PASSWORD_FILE is not set}"

LOG="$MC_DIR/logs/latest.log"
SAVE_TIMEOUT=120

# Type a command into the server console
console() {
  runuser -u "$MC_USER" -- screen -S "$MC_SCREEN" -p 0 -X stuff "$1"$'\r'
}

server_running() {
  runuser -u "$MC_USER" -- screen -list 2>/dev/null | grep -q "\.${MC_SCREEN}[[:space:]]"
}

# Wait until the console logs that the save finished
wait_for_save() {
  local from="$1" waited=0
  while ((waited < SAVE_TIMEOUT)); do
    if tail -n "+$((from + 1))" "$LOG" 2>/dev/null | grep -q "Saved the game"; then
      return 0
    fi
    sleep 2
    waited=$((waited + 2))
  done
  echo "⚠️  No 'Saved the game' after ${SAVE_TIMEOUT}s; backing up anyway."
}

if server_running; then
  trap 'console "save-on" || true' EXIT
  lines=0
  [[ -f "$LOG" ]] && lines="$(wc -l <"$LOG")"
  console "save-off"
  console "save-all flush"
  wait_for_save "$lines"
  echo "💾 World flushed; saving paused."
else
  echo "ℹ️  Screen session '$MC_SCREEN' not found; backing up the files as they are."
fi

# First run: create the repository. Exit code 10 means it does not exist
# (restic >= 0.17); anything else, such as a wrong password, is an error.
rc=0
restic cat config >/dev/null 2>&1 || rc=$?
if ((rc == 10)); then
  echo "🆕 Initializing $RESTIC_REPOSITORY"
  restic init
elif ((rc != 0)); then
  echo "❌ Cannot open $RESTIC_REPOSITORY (restic exit code $rc)."
  exit 1
fi

restic backup "$MC_DIR" \
  --tag minecraft \
  --exclude "$MC_DIR/logs" \
  --exclude "$MC_DIR/crash-reports" \
  --exclude "$MC_DIR/cache" \
  --exclude "$MC_DIR/libraries"

restic forget --prune --tag minecraft \
  --keep-daily 7 --keep-weekly 4 --keep-monthly 12

echo "✅ Backup finished."
