# agy-plugin — local AGY (Antigravity) bridge for Claude Code

Call the local `agy` CLI from Claude Code as a fast draft / review / docs / test
worker. No server, no token sharing — uses your own `agy` auth.

## Install

```bash
./install.sh --dry-run   # preview
./install.sh --apply     # register local marketplace + enable plugin
```

Then start a new Claude Code session. `install` snapshot-copies the plugin into
`~/.claude/plugins/cache/`, so **after editing the source, re-install** to refresh
it: `claude plugin uninstall agy@agy-local && claude plugin install agy@agy-local`.

## Commands

| Command | Mode | What it does |
|---|---|---|
| `/agy:review` | read intent | Fast review of local changes (isolated worktree, discarded). |
| `/agy:doc` | read intent | Draft developer docs for the current code/changes. |
| `/agy:fast-impl <task>` | write | Fast implementation draft in an isolated worktree; returns a diff to review. |
| `/agy:result [job-id]` | — | Show the latest (or given) saved run. |

## Safety — read this

AGY has **no enforced read-only mode** in headless `-p`: it can write anywhere on
disk regardless of flags (verified). To contain it, **every** command runs in an
isolated git worktree (or rsync copy) that is discarded afterward, so the live
working tree is never the target.

- `review` / `doc` keep only the text output and throw the workspace away.
- `fast-impl` captures a `changes.diff`; you apply it only after review.
- **Residual risk**: AGY could touch absolute paths outside the workspace —
  acceptable only on a trusted local machine. For a hard read-only review, use
  `/grok:review` instead.
- AGY emits no JSON; `result.md` is the raw stdout (narration + answer mixed).
- Repo content is sent to AGY's backend. No local secret scanner.
- Artifacts: `<repo>/.ai-runs/agy/<job-id>/`. Add `.ai-runs/` to your `.gitignore`.
- Commands work on a copy of your current working state (tracked changes +
  untracked non-ignored files); `.gitignore`d files are not visible.

## Use as a Codex / agents skill

This repo also ships the same bridge as a self-contained skill under [`skill/`](skill/)
(SKILL.md + `agents/openai.yaml` + `references/` + `assets/` + bundled scripts), in
the format used by Codex and the `~/.agents/skills` hub.

To install it for Codex: copy `skill/` to `~/.agents/skills/agy-bridge`, then create
an absolute symlink `~/.codex/skills/agy-bridge -> ~/.agents/skills/agy-bridge`
(and `~/.claude/skills/agy-bridge` for Claude), and restart Codex.

> Note: the skill currently references its runner by an absolute
> `~/.agents/skills/agy-bridge/...` path. A portable `install-skill.sh` that
> rewrites this on install is tracked in [TODO.md](TODO.md).

Inside Codex, the skill asks before running outside the sandbox (agy needs network
+ `~/.gemini` access); under Claude Code it runs directly. Same commands either way.

## Repo layout

- `plugin/` — Claude Code plugin (commands, internal skill, runner scripts).
- `.claude-plugin/marketplace.json`, `install.sh` — local-marketplace install.
- `skill/` — Codex/agents skill version of the same bridge.
- `AGY_BRIDGE_PROJECT.md` — original design spec. `TODO.md` — roadmap.

The runner logic (`agy-run.sh` + `lib/common.sh`) is currently duplicated in
`plugin/scripts/` and `skill/scripts/`; unifying it is a TODO.

## Requirements

`agy` (authenticated), `git`, `rsync`, `bash`. `claude` CLI for `install.sh`.
