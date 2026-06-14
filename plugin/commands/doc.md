---
description: Generate developer docs for local changes with AGY (isolated worktree)
argument-hint: '[--background] [what to document]'
allowed-tools: Read, Bash(bash:*)
---

Use AGY to draft developer-facing documentation for the current code/changes.
AGY runs in an **isolated worktree** (discarded afterward); your live tree is
untouched and the docs come back as text for you to place.

Run this (generous timeout — up to 600000 ms):

```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/agy-run.sh" doc "$ARGUMENTS"
```

Then `Read` the printed `result.md` and present the drafted documentation to the
user. AGY does not write docs into the repo — you place approved content. If
status is `capture_failed`, show `stderr.log`.

Note: the repo content is sent to AGY's backend.

**Background:** if the user passes `--background` (or `-b`), the run starts
detached and returns a `job_id` immediately. Tell the user to check it with
`/agy:status` and stop it with `/agy:cancel`; do not wait for `result.md`.
