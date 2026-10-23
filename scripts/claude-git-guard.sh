#!/usr/bin/env bash
# -------------------------------------------------------------------
# claude-git-guard.sh — Claude Code PreToolUse hook for the Bash tool
# -------------------------------------------------------------------
# Blocks git commands that throw away uncommitted work: reset --hard,
# clean -f, checkout . and restore . (with or without -C <dir>). Exit 2
# makes Claude Code refuse the call and show the reason to the model.
# `git push`, `git commit` and `git branch -D` are not blocked here; the
# same activation that installs this hook adds them to permissions.ask,
# so they reach the user instead (modules/shared/home.nix).
#
# Input: the hook event as JSON on stdin ({"tool_input": {"command": ...}}).
# -------------------------------------------------------------------
set -euo pipefail

cmd="$(jq -r '.tool_input.command // empty' 2>/dev/null || true)"
[ -n "$cmd" ] || exit 0

# One git invocation, allowing global options such as -C <dir> before the verb
git='(^|[;&|(`[:space:]])git([[:space:]]+-[A-Za-z][[:space:]]+[^[:space:]]+|[[:space:]]+--[a-z-]+(=[^[:space:]]+)?)*[[:space:]]+'
patterns=(
  "${git}reset([[:space:]]+[^;&|]*)?[[:space:]]--hard"
  "${git}clean([[:space:]]+[^;&|]*)?[[:space:]]-[A-Za-z]*f"
  "${git}checkout([[:space:]]+--)?[[:space:]]+\.([[:space:]]|$|[;&|])"
  "${git}restore([[:space:]]+[^;&|]*)?[[:space:]]\.([[:space:]]|$|[;&|])"
)
for re in "${patterns[@]}"; do
  if [[ "$cmd" =~ $re ]]; then
    echo "Blocked by claude-git-guard: this git command discards uncommitted work. Leave the working tree for the user, or ask them to run it (AGENTS.md §1)." >&2
    exit 2
  fi
done
exit 0
