---
description: Run a fast AGY review of local changes (in an isolated worktree)
argument-hint: '[--background] [focus notes]'
allowed-tools: Read, Bash(bash:*)
---

Run a fast AGY review of the current local changes. AGY runs in an **isolated
worktree** (thrown away afterward), so it cannot affect your live working tree.

Run this (use a generous timeout — up to 600000 ms; AGY's own print timeout is
5 min):

```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/agy-run.sh" review "$ARGUMENTS"
```

Then `Read` the printed `result.md` (raw AGY output — narration and the review
are interleaved; present the substantive findings) and show it to the user.
Review-only: do not apply changes unless asked. If status is `capture_failed`,
say AGY produced no output and show `stderr.log`.

Note: the repo content is sent to AGY's backend. For a hard read-only guarantee,
prefer `/grok:review` — AGY has no enforced read-only mode.

**Background:** if the user passes `--background` (or `-b`), the run starts
detached and returns a `job_id` immediately. Tell the user to check it with
`/agy:status` and stop it with `/agy:cancel`; do not wait for `result.md`.
