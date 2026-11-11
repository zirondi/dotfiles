#!/usr/bin/env bash
# -------------------------------------------------------------------
# test-llm.sh — End-to-end test of OpenCode with the local model
# -------------------------------------------------------------------
# Clones a small fixture repo, hands OpenCode a PLANO.md with two edits to
# existing code and runs one "próximo passo" per step through the `etapas`
# agent (configs/opencode/agents/). Then checks that no step timed out, the
# unit tests pass, only the expected files changed, the model stayed 100% on
# the GPU and swap did not grow. Everything happens in a temporary directory,
# which is kept when a check fails.
#
# Usage:
#   ./test-llm.sh              # run modo-llm first, then the test
#   ./test-llm.sh --no-modo    # skip modo-llm
#   ./test-llm.sh --keep       # keep the work directory even on success
#
#   AGENT=build ./test-llm.sh          # same steps with the default agent
#   STEP_TIMEOUT=1800 ./test-llm.sh    # seconds allowed per step (default 900)
#   MODEL=qwen3.5-32k ./test-llm.sh    # model expected in `ollama ps`
# -------------------------------------------------------------------
set -uo pipefail

MODEL="${MODEL:-qwen3.5-64k}"
AGENT="${AGENT:-etapas}"
STEP_TIMEOUT="${STEP_TIMEOUT:-900}"
OLLAMA_URL="${OLLAMA_URL:-http://127.0.0.1:11434}"
SWAP_LIMIT_MB=256
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

RUN_MODO=true
KEEP=false
for arg in "$@"; do
  case "$arg" in
    --no-modo) RUN_MODO=false ;;
    --keep) KEEP=true ;;
    *)
      echo "unknown option: $arg" >&2
      exit 2
      ;;
  esac
done

IS_MAC=false
[[ "$(uname -s)" == "Darwin" ]] && IS_MAC=true

RESULTS=()
FAILED=0
check() { # check <ok|fail|skip> <label> [detail]
  local status="$1" label="$2" detail="${3:-}"
  case "$status" in
    ok) RESULTS+=("PASS  $label${detail:+  ($detail)}") ;;
    skip) RESULTS+=("SKIP  $label${detail:+  ($detail)}") ;;
    *)
      RESULTS+=("FAIL  $label${detail:+  ($detail)}")
      FAILED=$((FAILED + 1))
      ;;
  esac
}

swap_used_mb() {
  $IS_MAC || return 0
  sysctl -n vm.swapusage | awk '{for (i = 1; i <= NF; i++) if ($i == "used") {v = $(i + 2); sub(/M$/, "", v); print int(v)}}'
}

git_q() { # git without the user's signing and hooks, which a throwaway repo does not need
  git -c commit.gpgsign=false -c core.hooksPath=/dev/null -c user.name=test-llm -c user.email=test-llm@localhost "$@"
}

# --- Preflight -------------------------------------------------------
missing=()
for cmd in git python3 opencode ollama curl; do
  command -v "$cmd" >/dev/null 2>&1 || missing+=("$cmd")
done
if ((${#missing[@]})); then
  echo "missing commands: ${missing[*]}" >&2
  exit 1
fi
if ! curl -sf "$OLLAMA_URL/api/version" >/dev/null; then
  echo "Ollama is not answering at $OLLAMA_URL" >&2
  exit 1
fi
if ! ollama show "$MODEL" >/dev/null 2>&1; then
  echo "model $MODEL not found: run 'ollama pull qwen3.5:9b', then 'just switch' creates the alias" >&2
  exit 1
fi
if ! opencode run --help 2>&1 | grep -q -- '--agent'; then
  echo "'opencode run' has no --agent option in this version; check 'opencode run --help'" >&2
  exit 1
fi

if $RUN_MODO && $IS_MAC; then
  "$SCRIPT_DIR/modo-llm.sh" || echo "modo-llm failed; going on"
fi

# --- Fixture: an upstream repo with a bug and a missing function ------
WORK="$(mktemp -d "${TMPDIR:-/tmp}/test-llm.XXXXXX")"
cleanup() {
  if $KEEP || ((FAILED > 0)); then
    echo "Work directory kept: $WORK"
  else
    rm -rf "$WORK"
  fi
}
trap cleanup EXIT

UPSTREAM="$WORK/upstream"
REPO="$WORK/repo"
mkdir -p "$UPSTREAM"

cat >"$UPSTREAM/calc.py" <<'PY'
"""Small statistics helpers."""


def soma(valores):
    total = 0
    for v in valores:
        total += v
    return total


def media(valores):
    return soma(valores) / 2
PY

cat >"$UPSTREAM/test_calc.py" <<'PY'
import unittest

import calc


class TestCalc(unittest.TestCase):
    def test_soma(self):
        self.assertEqual(calc.soma([1, 2, 3]), 6)

    def test_media(self):
        self.assertEqual(calc.media([2, 4, 6]), 4)

    def test_mediana_impar(self):
        self.assertEqual(calc.mediana([3, 1, 2]), 2)

    def test_mediana_par(self):
        self.assertEqual(calc.mediana([4, 1, 3, 2]), 2.5)


if __name__ == "__main__":
    unittest.main()
PY

cat >"$UPSTREAM/PLANO.md" <<'MD'
# Plano

Não altere test_calc.py.

- [ ] Em calc.py, corrigir a função media para dividir pela quantidade de itens (len(valores)) em vez de 2
- [ ] Em calc.py, adicionar a função mediana(valores), que ordena a lista e devolve o elemento do meio (ou a média dos dois do meio quando a quantidade é par)
MD

git_q init -q "$UPSTREAM"
git_q -C "$UPSTREAM" add -A
git_q -C "$UPSTREAM" commit -q -m "fixture"
git_q clone -q "$UPSTREAM" "$REPO"
echo "== Fixture cloned to $REPO"

export PYTHONDONTWRITEBYTECODE=1
if (cd "$REPO" && python3 -m unittest -q >/dev/null 2>&1); then
  check fail "fixture fails before the edits" "tests already pass: the fixture is broken"
else
  check ok "fixture fails before the edits"
fi

# --- Steps -------------------------------------------------------------
swap_start="$(swap_used_mb)"
total_steps=$(grep -c '^- \[ \]' "$REPO/PLANO.md")

for ((i = 1; i <= total_steps; i++)); do
  log="$WORK/step$i.log"
  echo "== Step $i of $total_steps (agent $AGENT, limit ${STEP_TIMEOUT}s)"
  start=$(date +%s)
  (cd "$REPO" && exec opencode run --agent "$AGENT" "próximo passo") >"$log" 2>&1 &
  pid=$!

  seen=""
  off_gpu=""
  timed_out=false
  while kill -0 "$pid" 2>/dev/null; do
    if (($(date +%s) - start >= STEP_TIMEOUT)); then
      kill "$pid" 2>/dev/null
      timed_out=true
      break
    fi
    line="$(ollama ps 2>/dev/null | grep -F "$MODEL" | head -1)"
    if [[ -n "$line" ]]; then
      seen="$line"
      [[ "$line" == *"100% GPU"* ]] || off_gpu="$line"
    fi
    sleep 5
  done
  wait "$pid"
  rc=$?
  elapsed=$(($(date +%s) - start))

  if $timed_out; then
    check fail "step $i finished" "killed after ${elapsed}s"
  elif ((rc != 0)); then
    check fail "step $i finished" "opencode exited with $rc after ${elapsed}s"
  elif grep -qiE 'timed out|TimeoutError' "$log"; then
    check fail "step $i finished" "timeout in the log after ${elapsed}s"
  else
    check ok "step $i finished" "${elapsed}s"
  fi

  marked=$(grep -c '^- \[x\]' "$REPO/PLANO.md")
  if ((marked >= i)); then
    check ok "step $i marked in PLANO.md"
  else
    check fail "step $i marked in PLANO.md" "$marked of $i items marked"
  fi

  if [[ -n "$off_gpu" ]]; then
    check fail "step $i ran 100% on the GPU" "$(echo "$off_gpu" | tr -s ' ')"
  elif [[ -z "$seen" ]]; then
    check skip "step $i ran 100% on the GPU" "$MODEL never showed up in 'ollama ps'"
  else
    check ok "step $i ran 100% on the GPU"
  fi

  if $timed_out || ((rc != 0)); then
    echo "-- last lines of $log"
    tail -20 "$log"
    break
  fi
done

# --- Result ------------------------------------------------------------
if (cd "$REPO" && python3 -m unittest -q >"$WORK/tests.log" 2>&1); then
  check ok "unit tests pass after the edits"
else
  check fail "unit tests pass after the edits" "see $WORK/tests.log"
fi

changed="$(git -C "$REPO" status --porcelain --untracked-files=all | awk '{print $NF}' |
  grep -vE '^(\.opencode/|__pycache__/)' | sort | tr '\n' ' ')"
unexpected="$(echo "$changed" | tr ' ' '\n' | grep -vxE 'calc\.py|PLANO\.md|' | tr '\n' ' ')"
if [[ -z "${unexpected// /}" ]]; then
  check ok "only calc.py and PLANO.md changed" "${changed:-nothing}"
else
  check fail "only calc.py and PLANO.md changed" "also: $unexpected"
fi

if $IS_MAC && [[ -n "$swap_start" ]]; then
  swap_end="$(swap_used_mb)"
  growth=$((swap_end - swap_start))
  if ((growth <= SWAP_LIMIT_MB)); then
    check ok "swap did not grow" "${growth} MB"
  else
    check fail "swap did not grow" "+${growth} MB"
  fi
else
  check skip "swap did not grow" "only measured on macOS"
fi

echo
echo "== Result"
printf '%s\n' "${RESULTS[@]}"
if ((FAILED > 0)); then
  echo "$FAILED check(s) failed. Step logs: $WORK/step*.log"
  exit 1
fi
echo "All checks passed."
