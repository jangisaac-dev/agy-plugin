---
name: agy-bridge
description: Use when the user explicitly asks to run agy, agy-bridge, or wants a fast Antigravity/Gemini second-opinion review, docs draft, or implementation diff for local repo changes.
metadata:
  author: Isaac-dev
---

# agy-bridge

Run the local `agy` CLI as a fast helper from inside the user's project, on their
own `agy` auth. Good for quick drafts, docs, and reviews. For a trustworthy
*hard* read-only review, prefer the sibling `grok-bridge`.

## Execution environment

**Claude Code (and any runtime that does not sandbox shell commands):** run the
runner directly — no sandbox prompt, nothing extra. Skip to "Runner".

**Codex only:** Codex sandboxes shell commands by default, and `agy` needs
outbound network + write access to `~/.gemini/antigravity-cli` (outside the
workspace), so a sandboxed run fails (`FS_PERMISSION_DENIED`, log-write errors,
`127.0.0.1:0` bind). So, **when running under Codex**:
1. If the user explicitly requested `agy` / `agy-bridge` / `/agy:*`, treat that
   as per-run consent to send the repo context and task to agy's backend. Do not
   ask a second natural-language permission question.
2. Immediately request the required tool escalation
   (`sandbox_permissions=require_escalated`) for the runner command. The host
   approval prompt is the execution permission gate.
3. If `agy` was not explicitly requested and you are choosing it yourself,
   explain the external transfer and ask first.

Details / permanent fix: `references/codex-network.md`.

## Safety — no hard read-only mode

`agy` can write anywhere on disk in headless mode; no flag prevents it. To contain
it, **every** command runs in an isolated git worktree (or rsync copy) that is
discarded afterward, so the live working tree is never the target. Residual risk:
agy could touch absolute paths outside the worktree — acceptable only on a trusted
local machine. For a guaranteed read-only review, use `grok-bridge`.

## Runner

```bash
bash $HOME/.agents/skills/agy-bridge/scripts/agy-run.sh <command> [args]
```

Run from the user's repo directory, with a generous timeout (agy's own print
timeout is 5 min). It prints a `result:` path (and `diff:` for `fast-impl`) and
exits non-zero on failure.

| Command | Mode | Use for |
|---|---|---|
| `review` | read intent | Fast review of current local changes. |
| `adversarial-review` | read intent | Attack the change — weak assumptions, failure modes. |
| `doc` | read intent | Draft developer docs for the code/changes. |
| `fast-impl "<task>"` | write (worktree) | Fast implementation draft; returns a diff. |
| `setup` | local check | Verify `agy` is installed + authenticated (no network call). |
| `status [job-id]` | local | List background jobs / show one. |
| `cancel [job-id]` | local | Stop a running background job and clean up its worktree. |

Add `--background` (or `-b`) to a run command to start it detached and get a
`job_id` back immediately; then poll with `status` and stop with `cancel`.

## After a run

- `result.md` is raw agy stdout (narration + answer mixed) — present the
  substantive part. For `review`/`doc`, don't write into the repo; you place
  approved content.
- For `fast-impl`: read `changes.diff`, **verify it** (agy is a fast drafter), show
  it, and apply only with user approval (`git apply …/changes.diff`).
- Check `status.json`: `ok` / `no_changes` / `error` / `capture_failed` / `timed_out`.
  On `error`/`capture_failed`, show `stderr.log`.

See `references/commands.md` for the full command/status/artifact reference, and
`references/workflow.md` for choosing commands, agy-vs-grok, and applying diffs.

## Notes

- Repo content is sent to agy's backend; no local secret scanner.
- Explicit user invocation of `agy` is per-run consent for that transfer; don't add a redundant confirmation prompt.
- Remind the user to add `.ai-runs/` to their repo `.gitignore`.
- Requires `agy` (authenticated), `git`, `rsync`, `jq`, `bash`. (`jq` is used by
  `status`/`cancel` to read job metadata.)
