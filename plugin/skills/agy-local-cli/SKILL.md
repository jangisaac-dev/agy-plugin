---
name: agy-local-cli
description: Internal contract for calling the local agy CLI runner from the agy bridge commands
user-invocable: false
---

# AGY local CLI runtime

Internal helper notes for the `/agy:*` commands. Not user-invokable.

## Runner

```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/agy-run.sh" <command> [task...]
```

Commands: `review`, `doc` (read intent), `fast-impl` (write). `result` reads
`.ai-runs/agy/` directly.

## Safety model (verified — important)

AGY has **no hard read-only mode** in headless `-p`: it writes anywhere on disk
regardless of `--sandbox` / `--add-dir`, governed only by global
`~/.gemini/antigravity-cli/settings.json`. There is no non-invasive per-run
override (project-local `.gemini/settings.json` is ignored; `HOME` override
breaks auth). Therefore:

- **Every** agy command runs in an isolated git worktree (or rsync copy for
  non-git repos), with `--add-dir` pointed at that workspace, and the workspace
  is discarded afterward. The live working tree is never the target.
- `review` / `doc` keep only the text output and discard the workspace.
- `fast-impl` captures `changes.diff`; integration into the live tree is done by
  Claude/the user after the user approves.
- **Residual risk**: agy could write to absolute paths outside the workspace.
  This is accepted only on a trusted local machine. For a hard read-only review,
  route the user to `/grok:review` instead (grok enforces `--permission-mode
  plan` at the CLI level).

## Output handling

agy emits no JSON; stdout interleaves narration with the answer. We save raw
stdout to `stdout.log` and copy it verbatim to `result.md` (no clean extraction).
`status: capture_failed` = exit 0 with empty stdout (run interactively to debug).

## Artifacts

`<repo>/.ai-runs/agy/<job-id>/`: `prompt.md`, `context.txt`, `stdout.log`,
`result.md`, `stderr.log`, `status.json`, and (fast-impl) `changes.diff`.

## Rules

- Prefer the runner over hand-rolled `agy` invocations.
- Never apply a `fast-impl` diff without explicit user approval; verify it first
  (AGY is a fast drafter, not a final authority).
- Repo content is sent to AGY's backend; surface this. No local secret scanner.
- Remind users to add `.ai-runs/` to their repo `.gitignore`.
