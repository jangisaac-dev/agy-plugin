---
description: Run an adversarial AGY review that attacks the current change (isolated worktree)
argument-hint: '[--background] [focus notes]'
allowed-tools: Read, Bash(bash:*)
---

Run an adversarial AGY review — AGY deliberately attacks the current change for
weak assumptions and failure modes. AGY runs in an **isolated worktree** (thrown
away afterward), so it cannot affect your live working tree.

Run this (use a generous timeout — up to 600000 ms; AGY's own print timeout is
5 min):

```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/agy-run.sh" adversarial-review "$ARGUMENTS"
```

Then `Read` the printed `result.md` (raw AGY output — narration and the review
are interleaved; present the substantive findings) and show the blockers /
assumptions / failure-scenarios to the user. Review-only: do not act on the
findings unless asked. If status is `capture_failed`, say AGY produced no output
and show `stderr.log`.

Note: the repo content is sent to AGY's backend. For a hard read-only guarantee,
prefer `/grok:adversarial-review` — AGY has no enforced read-only mode.

**Background:** if the user passes `--background` (or `-b`), the run starts
detached and returns a `job_id` immediately. Tell the user to check it with
`/agy:status` and stop it with `/agy:cancel`; do not wait for `result.md`.
