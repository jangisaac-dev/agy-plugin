#!/usr/bin/env bash
# agy-run.sh — call the local `agy` CLI as a Claude Code helper.
#
#   agy-run.sh review     [task...]
#   agy-run.sh doc        [task...]
#   agy-run.sh fast-impl  <task...>
#
# IMPORTANT: agy has no hard read-only mode in headless `-p` — it can write
# anywhere on disk regardless of flags (verified). So EVERY agy command runs in
# an isolated git worktree (or rsync copy) that is thrown away afterward; the
# live working tree is never the target. `review`/`doc` discard the workspace and
# keep only the text output. `fast-impl` additionally captures the diff for the
# user to review and apply. Residual risk: agy could touch absolute paths outside
# the workspace — acceptable only on a trusted local machine (see SKILL.md).
#
# agy emits no JSON; stdout interleaves narration with the answer. We save raw
# stdout verbatim and treat an empty stdout + exit 0 as a capture failure.
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "$HERE/lib/common.sh"

COMMAND="${1:-review}"; shift || true

# Slash commands pass their whole argument string as one quoted "$ARGUMENTS".
# Re-split it in-process (data only, set -f disables globbing, never eval'd) so
# flags + task text parse normally without risking command injection.
if [ "$#" -le 1 ]; then set -f; set -- ${1-}; set +f; fi

# status / cancel / setup work on existing jobs (or report a missing CLI), so
# they run before the `command -v agy` guard and before any job dir is made.
case "$COMMAND" in
  status) cmd_status agy "${1:-}"; exit 0 ;;
  cancel) cmd_cancel agy "${1:-}"; exit 0 ;;
  setup)  cmd_setup  agy agy "$HOME/.gemini/antigravity-cli/antigravity-oauth-token"; exit 0 ;;
esac

BACKGROUND=0
TASK_ARGS=()
while [ $# -gt 0 ]; do
  case "$1" in
    --background|-b) BACKGROUND=1; shift ;;
    *) TASK_ARGS+=("$1"); shift ;;
  esac
done
TASK_TEXT="${TASK_ARGS[*]:-}"

if ! command -v agy >/dev/null 2>&1; then
  echo "ERROR: 'agy' CLI not found on PATH. Install it and authenticate first." >&2
  exit 127
fi

case "$COMMAND" in
  review|doc|adversarial-review) WRITE_INTENT=0 ;;
  fast-impl)  WRITE_INTENT=1 ;;
  *) echo "Unknown command: $COMMAND" >&2; exit 2 ;;
esac
if [ "$COMMAND" = "fast-impl" ] && [ -z "$TASK_TEXT" ]; then
  echo "ERROR: fast-impl needs a task description." >&2; exit 2
fi

JOB_DIR="$(new_job_dir agy)"
collect_context "$JOB_DIR/context.txt"

# --- prompt (argv only; agy has no --prompt-file/stdin) --------------------
# agy reads the repo itself via --add-dir, so we keep the argv prompt compact:
# role + task + a short context summary (full diff lives in context.txt and the
# workspace). Cap the summary to stay well under ARG_MAX.
context_summary() {
  if is_git_repo; then
    echo "Branch: $(git rev-parse --abbrev-ref HEAD 2>/dev/null)"
    echo "Changed files:"
    git status --short 2>/dev/null | head -50
  fi
  echo "(Full diff and files are in the workspace provided to you.)"
}

role_block() {
  case "$COMMAND" in
    review) cat <<'EOF'
You are AGY running as a fast local reviewer for this repository's current changes.
Focus: obvious bugs, missing tests, confusing code, simple refactors, doc gaps.
Be concise. Do not over-engineer. Output: 1) Problems 2) Suggested fixes
3) Tests to add 4) Documentation notes 5) Final verdict.
This is review-only: do not modify files.
EOF
    ;;
    adversarial-review) cat <<'EOF'
You are AGY running as an adversarial reviewer. Attack the current change: assume
it may be subtly wrong. Find the weakest assumptions, hidden coupling, bad
abstractions, and cases where it fails in production.
Be concrete: cite exact files / functions / diff sections. Do not be polite, do
not invent issues, and separate real blockers from preferences.
Output: 1) Blockers 2) High-risk assumptions 3) Failure scenarios
4) Simpler alternatives 5) Final verdict.
This is review-only: do not modify files.
EOF
    ;;
    doc) cat <<'EOF'
You are AGY running as a documentation assistant for this repository.
Create or improve developer-facing docs for the current code/changes.
Write for future maintainers, avoid marketing language, be concrete, mark
uncertain details as uncertain. Output: 1) Summary 2) Setup 3) Usage
4) Important files 5) Known limitations 6) Troubleshooting.
Produce the documentation as text; do not modify files.
EOF
    ;;
    fast-impl) cat <<'EOF'
You are AGY running as a fast implementation worker in an ISOLATED throwaway
workspace. Edit the files in the workspace to implement the requested task.
Keep the solution simple and the changes small and isolated. Add or update
tests when relevant. Do not touch auth/tokens/secrets/deploy config. Do not run
destructive commands. After editing, briefly summarize what you changed.
EOF
    ;;
  esac
}

PROMPT="$(role_block)

Requested task: ${TASK_TEXT:-(none — use the current repository changes)}

$(context_summary)"
printf '%s\n' "$PROMPT" >"$JOB_DIR/prompt.md"

# execute_job : isolated workspace + agy run + status. Run inline (foreground)
# or inside a disowned subshell for --background.
execute_job() {
  IFS=$'\t' read -r WS WS_KIND < <(make_workspace "$JOB_DIR/workspace.path")
  [ "$WS_KIND" = "copy" ] && touch "$WS/.aibridge-start"

  ( cd "$WS" && agy -p "$PROMPT" --add-dir "$WS" ) \
    >"$JOB_DIR/stdout.log" 2>"$JOB_DIR/stderr.log"
  CODE=$?

  # result.md is a verbatim copy of stdout (no reliable clean extraction for agy).
  cp "$JOB_DIR/stdout.log" "$JOB_DIR/result.md" 2>/dev/null

  DIFF=""
  if [ "$CODE" -ne 0 ]; then
    # agy itself failed — never mask as ok, regardless of any partial stdout.
    STATUS="error"
  elif [ ! -s "$JOB_DIR/stdout.log" ]; then
    STATUS="capture_failed"
  elif [ "$WRITE_INTENT" -eq 1 ]; then
    DIFF="$JOB_DIR/changes.diff"
    if capture_diff "$WS" "$WS_KIND" "$DIFF"; then STATUS="ok"; else STATUS="no_changes"; fi
  else
    STATUS="ok"
  fi

  remove_workspace "$WS" "$WS_KIND"
  rm -f "$JOB_DIR/workspace.path"
  write_status "$JOB_DIR" "$COMMAND" "$([ "$WRITE_INTENT" -eq 1 ] && echo write || echo read-only)" "$CODE" "$STATUS" "$DIFF"
  [ "$STATUS" != "ok" ] && [ "$STATUS" != "no_changes" ] && echo "WARNING: agy status=$STATUS (exit $CODE; see stderr.log)." >&2
  emit_result_pointer "$JOB_DIR" "$DIFF"
  final_exit "$STATUS"
}

if [ "$BACKGROUND" -eq 1 ]; then
  write_running_status "$JOB_DIR" "$COMMAND" "$([ "$WRITE_INTENT" -eq 1 ] && echo write || echo read-only)"
  ( execute_job ) >"$JOB_DIR/worker.log" 2>&1 &
  echo $! >"$JOB_DIR/job.pid"
  disown 2>/dev/null || true
  emit_background_pointer "$JOB_DIR" agy
  exit 0
fi

execute_job
