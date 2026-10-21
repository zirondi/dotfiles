#!/usr/bin/env bash
# Push a notification to the phone through ntfy.sh.
#
#   ntfy-send.sh [-t title] [-p priority] [-g tags] <message>
#   <claude-code-hook-json> | ntfy-send.sh --hook
#   <claude-code-hook-json> | ntfy-send.sh --mark
#
# The topic works as a password on ntfy.sh, so it never lives in this repo:
# it is read from NTFY_TOPIC or from ~/.config/ntfy/topic (one line, mode 600).
#
# Claude Code hooks (~/.claude/settings.json):
#   Notification     → --hook  (async) waits, then pushes only if still unanswered
#   UserPromptSubmit → --mark  records that the user replied
#
# Levels, so not every pause reaches the phone:
#   permission_prompt  Claude is blocked on an approval   high,    after NTFY_DELAY_PERMISSION (300 s)
#   anything else      Claude is waiting for a reply      default, after NTFY_DELAY_IDLE (900 s)
#   urgent             a timed physical step (sent by hand with -p urgent), immediately
# At most one push per pause: after a push, the next one needs a new reply first.
set -euo pipefail

state_dir="${XDG_CACHE_HOME:-$HOME/.cache}/claude-ntfy"

send() { # title priority tags message
  local topic="${NTFY_TOPIC:-}"
  local topic_file="${NTFY_TOPIC_FILE:-$HOME/.config/ntfy/topic}"
  if [ -z "$topic" ] && [ -r "$topic_file" ]; then
    topic="$(tr -d '[:space:]' <"$topic_file")"
  fi
  if [ -z "$topic" ]; then
    echo "ntfy-send: no topic (set NTFY_TOPIC or write $topic_file)" >&2
    exit 1
  fi
  curl -fsS --max-time 10 \
    -H "Title: $1" -H "Priority: $2" -H "Tags: $3" \
    -d "$4" "https://ntfy.sh/$topic" >/dev/null
}

session_of() { jq -r '.session_id // "default"' <<<"$1"; }

case "${1:-}" in
  --mark)
    input="$(cat)"
    mkdir -p "$state_dir"
    touch "$state_dir/$(session_of "$input").reply"
    exit 0
    ;;
  --hook)
    input="$(cat)"
    session="$(session_of "$input")"
    reply="$state_dir/$session.reply"
    sent="$state_dir/$session.sent"
    mkdir -p "$state_dir"

    message="$(jq -r '.message // "Claude Code precisa da sua atenção"' <<<"$input")"
    title="$(jq -r '.title // "Claude Code"' <<<"$input")"
    project="$(jq -r '.cwd // empty' <<<"$input")"
    [ -n "$project" ] && title="$title ($(basename "$project"))"

    if [ "$(jq -r '.notification_type // empty' <<<"$input")" = "permission_prompt" ]; then
      delay="${NTFY_DELAY_PERMISSION:-300}" priority="high" tags="lock"
    else
      delay="${NTFY_DELAY_IDLE:-900}" priority="default" tags="hourglass"
    fi

    # Already pushed during this pause: wait for a reply before pushing again
    if [ -e "$sent" ] && { [ ! -e "$reply" ] || [ "$sent" -nt "$reply" ]; }; then
      exit 0
    fi

    started="$state_dir/$session.waiting.$$"
    touch "$started"
    trap 'rm -f "$started"' EXIT
    sleep "$delay"

    # The user replied while we waited
    if [ -e "$reply" ] && [ "$reply" -nt "$started" ]; then
      exit 0
    fi
    send "$title" "$priority" "$tags" "$message"
    touch "$sent"
    exit 0
    ;;
esac

title="Claude Code"
priority="default"
tags="robot"
message=""

while [ $# -gt 0 ]; do
  case "$1" in
    -t) title="$2"; shift 2 ;;
    -p) priority="$2"; shift 2 ;;
    -g) tags="$2"; shift 2 ;;
    *) message="$*"; break ;;
  esac
done

[ -n "$message" ] || { echo "ntfy-send: empty message" >&2; exit 1; }
send "$title" "$priority" "$tags" "$message"
