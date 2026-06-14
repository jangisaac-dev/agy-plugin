---
description: Delegate a fast implementation draft to AGY in an isolated worktree, then review its diff
argument-hint: '<task description>'
allowed-tools: Read, Bash(bash:*), Bash(git:*)
---

Delegate a quick implementation task to AGY. AGY edits files in an **isolated
worktree** (a throwaway checkout); the changes are captured as a diff and your
live working tree is never modified directly.

Run this (generous timeout — up to 600000 ms):

```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/agy-run.sh" fast-impl "$ARGUMENTS"
```

The command prints a `diff:` path and a `result:` path. Then:
1. `Read` the `changes.diff` and `result.md`.
2. Present AGY's proposed changes and summary to the user.
3. Integration into the live tree is **your** job — apply the diff only after the
   user approves (e.g. `git apply <changes.diff>`). Do not apply blindly; AGY is
   a fast drafter, so verify correctness first.

If status is `no_changes`, tell the user AGY proposed no edits. If
`capture_failed`, show `stderr.log`. Note: task text + repo content go to AGY's
backend.
