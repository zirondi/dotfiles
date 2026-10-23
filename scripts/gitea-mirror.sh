#!/usr/bin/env bash
# -------------------------------------------------------------------
# gitea-mirror.sh — Mirror every GitHub repository into the Gitea on rpi3
# -------------------------------------------------------------------
# Usage:
#   ./scripts/gitea-mirror.sh [--forks] [--dry-run]
#
# Lists the repositories of the gh user and of every organisation the user
# belongs to, creates the matching organisations in Gitea, and creates a
# pull mirror for each repository that Gitea does not have yet. Existing
# mirrors are left alone (Gitea refreshes them on its own schedule), so the
# script is safe to re-run after new repositories appear on GitHub.
#
# Environment:
#   GITEA_URL     — default https://gitea.rpi3.leazirondi.com.br
#   GITEA_TOKEN   — Gitea admin API token; default: vault entry "Gitea API token"
#   GITHUB_TOKEN  — read-only GitHub token that Gitea keeps to refresh
#                   private mirrors, used for every owner. Without it, each
#                   owner's token comes from the vault entry
#                   "GitHub Gitea mirror <owner>" (a fine-grained token covers
#                   a single owner), falling back to "GitHub Gitea mirror"
# Tokens never reach the command line: curl reads the header from a private
# temporary file and the bodies from stdin.
# -------------------------------------------------------------------
set -euo pipefail

GITEA_URL="${GITEA_URL:-https://gitea.rpi3.leazirondi.com.br}"
INCLUDE_FORKS=false
DRY_RUN=false
for arg in "$@"; do
  case "$arg" in
    --forks) INCLUDE_FORKS=true ;;
    --dry-run) DRY_RUN=true ;;
    *) echo "❌ Unknown option: $arg" >&2; exit 1 ;;
  esac
done

for cmd in gh jq curl; do
  command -v "$cmd" >/dev/null || { echo "❌ $cmd not found" >&2; exit 1; }
done

GITEA_TOKEN="${GITEA_TOKEN:-$(rbw get "Gitea API token")}"
[ -n "$GITEA_TOKEN" ] || { echo "❌ Missing the Gitea token" >&2; exit 1; }

# github_token OWNER — prints the token Gitea should keep for OWNER's mirrors
github_token() {
  if [ -n "${GITHUB_TOKEN:-}" ]; then
    printf '%s' "$GITHUB_TOKEN"
  else
    rbw get "GitHub Gitea mirror $1" 2>/dev/null || rbw get "GitHub Gitea mirror"
  fi
}

# gitea METHOD PATH [JSON on stdin] — prints the HTTP status, body to $BODY
BODY="$(mktemp)"
HEADER="$(mktemp)"
trap 'rm -f "$BODY" "$HEADER"' EXIT
chmod 600 "$HEADER"
printf 'Authorization: token %s\n' "$GITEA_TOKEN" > "$HEADER"
gitea() {
  local method="$1" path="$2"
  local args=(-s -o "$BODY" -w '%{http_code}' -X "$method"
    -H "@$HEADER" -H 'Content-Type: application/json')
  [ "$method" = GET ] || args+=(--data-binary @-)
  curl "${args[@]}" "$GITEA_URL/api/v1$path"
}

GITEA_USER="$(gitea GET /user </dev/null >/dev/null; jq -r .login "$BODY")"
GH_USER="$(gh api user --jq .login)"
mapfile -t OWNERS < <(echo "$GH_USER"; gh api user/orgs --jq '.[].login')

created=0 skipped=0 failed=0
for owner in "${OWNERS[@]}"; do
  # Personal repositories go to the Gitea admin; each organisation gets its own
  target="$owner"
  if [ "$owner" = "$GH_USER" ]; then
    target="$GITEA_USER"
  elif [ "$(gitea GET "/orgs/$owner" </dev/null)" = 404 ]; then
    echo "🏢 Creating organisation $owner"
    $DRY_RUN || jq -n --arg o "$owner" '{username: $o, visibility: "private"}' | gitea POST /orgs >/dev/null
  fi

  owner_token="$(github_token "$owner")"
  while IFS=$'\t' read -r name private fork; do
    if [ "$fork" = true ] && ! $INCLUDE_FORKS; then
      continue
    fi
    if [ "$(gitea GET "/repos/$target/$name" </dev/null)" = 200 ]; then
      skipped=$((skipped + 1))
      continue
    fi
    echo "🪞 $owner/$name → $target/$name"
    if $DRY_RUN; then
      continue
    fi
    status="$(jq -n --arg url "https://github.com/$owner/$name.git" --arg tok "$owner_token" \
      --arg owner "$target" --arg name "$name" --argjson private "$private" \
      '{clone_addr: $url, auth_token: $tok, service: "github", mirror: true,
        mirror_interval: "8h", repo_owner: $owner, repo_name: $name,
        private: $private, releases: true, issues: false, pull_requests: false,
        wiki: false, labels: false, milestones: false, lfs: false}' \
      | gitea POST /repos/migrate)"
    if [ "$status" = 201 ]; then
      created=$((created + 1))
    else
      failed=$((failed + 1))
      echo "   ❌ HTTP $status: $(jq -r '.message // empty' "$BODY")" >&2
    fi
  done < <(gh repo list "$owner" --limit 500 --json name,isPrivate,isFork \
    --jq '.[] | [.name, .isPrivate, .isFork] | @tsv')
done

echo "✅ Created $created, already mirrored $skipped, failed $failed"
[ "$failed" -eq 0 ]
