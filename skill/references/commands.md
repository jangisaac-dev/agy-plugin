# agy-bridge — command reference

Runner: `bash $HOME/.agents/skills/agy-bridge/scripts/agy-run.sh <command> [args]`
Run from the user's repo dir, with escalated permissions (see `codex-network.md`).

Every command runs in an isolated git worktree (or rsync copy for non-git repos)
because agy has no enforced read-only mode — see the safety note in SKILL.md.

## Commands

### `review`  (read intent)
```bash
bash …/agy-run.sh review [focus notes]
```
Fast review of current local changes. Worktree is discarded after; only the text
output is kept.

### `doc`  (read intent)
```bash
bash …/agy-run.sh doc [what to document]
```
Drafts developer-facing documentation for the current code/changes. Text output
only; agy does not write docs into the repo.

### `fast-impl "<task>"`  (write)
```bash
bash …/agy-run.sh fast-impl "add an empty-list guard to average()"
```
Fast implementation draft. Edits the worktree; the change is captured as
`changes.diff` (live tree untouched).

## Artifacts — `<repo>/.ai-runs/agy/<job-id>/`

| file | meaning |
|---|---|
| `prompt.md` | the argv prompt sent to agy |
| `context.txt` | branch + git diff summary |
| `stdout.log` | raw agy stdout (narration + answer interleaved) |
| `result.md` | verbatim copy of `stdout.log` (no clean extraction for agy) |
| `changes.diff` | (fast-impl) the proposed edit — NOT applied |
| `stderr.log` | agy stderr |
| `status.json` | run metadata (below) |

## `status.json` status values

| status | meaning | action |
|---|---|---|
| `ok` | success | present `result.md` (and `changes.diff` for fast-impl) |
| `no_changes` | fast-impl produced no edits | tell the user; show `result.md` |
| `error` | agy exited non-zero | show `result.md` + `stderr.log` |
| `capture_failed` | exit 0 but empty stdout | rerun interactively to debug |
| `timed_out` | killed by timeout | rerun / narrow the task |

The runner exits non-zero unless status is `ok` or `no_changes`.

## The worktree

Mirrors the user's current working state (tracked uncommitted changes + untracked
non-ignored files), commits a baseline, so `changes.diff` shows ONLY agy's edits.
`.gitignore`d files are not visible. Residual risk: agy can write absolute paths
outside the worktree (no flag prevents this) — acceptable only on a trusted local
machine.
