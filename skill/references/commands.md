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

### `adversarial-review`  (read intent)
```bash
bash …/agy-run.sh adversarial-review [focus notes]
```
Same read-intent worktree run; agy attacks the change for weak assumptions,
hidden coupling, and production failure modes. Output structured as blockers /
high-risk assumptions / failure scenarios / simpler alternatives / verdict. For a
hard read-only guarantee use `grok-bridge` instead — agy cannot enforce one.

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

### `setup`  (read-only, local)
```bash
bash …/agy-run.sh setup
```
Reports whether `agy` is on PATH, its version, and whether the
`~/.gemini/antigravity-cli/antigravity-oauth-token` exists (authenticated). No
network call. Use it to diagnose a "CLI not found" or auth error.

## Background jobs

Add `--background` (or `-b`) to any run command (`review`, `adversarial-review`,
`doc`, `fast-impl`) to start it detached and return a `job_id` immediately
instead of blocking. The job runs the same pipeline in a disowned subshell and
writes its final `status.json` when done.

### `status [job-id]`
```bash
bash …/agy-run.sh status            # table of recent jobs in this repo
bash …/agy-run.sh status <job-id>   # full status for one job
```
A `running?` status means the job's process is gone before it finalized (likely
crashed) — check that job's `worker.log`.

### `cancel [job-id]`
```bash
bash …/agy-run.sh cancel            # cancel the most recent running job
bash …/agy-run.sh cancel <job-id>
```
Kills the job's process tree, removes its isolated worktree (even if `agy` was
killed mid-`worktree add`), and marks the job `cancelled`.

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
| `worker.log` | (background) the detached run's stdout/stderr |
| `job.pid` | (background) PID of the running job, for `status`/`cancel` |

## `status.json` status values

| status | meaning | action |
|---|---|---|
| `running` | background job still in progress | check later with `status` |
| `ok` | success | present `result.md` (and `changes.diff` for fast-impl) |
| `no_changes` | fast-impl produced no edits | tell the user; show `result.md` |
| `error` | agy exited non-zero | show `result.md` + `stderr.log` |
| `capture_failed` | exit 0 but empty stdout | rerun interactively to debug |
| `cancelled` | stopped via `cancel` | run was killed; worktree cleaned up |
| `timed_out` | killed by timeout | rerun / narrow the task |

The runner exits non-zero unless status is `ok` or `no_changes`.

## The worktree

Mirrors the user's current working state (tracked uncommitted changes + untracked
non-ignored files), commits a baseline, so `changes.diff` shows ONLY agy's edits.
`.gitignore`d files are not visible. Residual risk: agy can write absolute paths
outside the worktree (no flag prevents this) — acceptable only on a trusted local
machine.
