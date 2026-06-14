# TODO — agy-bridge / agy-plugin

Future work to make this as capable as the official Codex skills. The current
release covers worktree-isolated review / adversarial-review / doc / fast-impl,
plus `setup` / `status` / `cancel` and `--background` jobs, usable both as a
Claude Code plugin and a Codex/agents skill.

## Shipped (Codex-skill parity so far)
- [x] `adversarial-review` — attack-the-change review (parity with grok-bridge).
- [x] `setup` — local install/auth check (no network call).
- [x] Background jobs: `--background`/`-b` + `/agy:status` + `/agy:cancel`
      (detached run in a disowned subshell; cancel kills the process tree and
      cleans the worktree, including the `git worktree add` init-lock race).

## Packaging / portability
- [ ] `install-skill.sh`: copy `skill/` into `~/.agents/skills/agy-bridge`,
      rewrite the hard-coded `~/.agents/skills/...` runner path to the installing
      user's home, and expose symlinks to `~/.codex/skills` and `~/.claude/skills`.
- [ ] Unify the runner source: `plugin/scripts` and `skill/scripts` are duplicate
      copies of `agy-run.sh` + `lib/common.sh`. Make one canonical source.
- [ ] Provide PNG icons in addition to the SVGs.

## Features (Codex-skill parity)
- [ ] Session resume (`agy --continue` / `agy --conversation <id>`).
- [ ] Cleaner output: separate agy's narration from the actual answer instead of
      saving raw interleaved stdout (agy emits no JSON, so this needs heuristics).
- [ ] `test` command: generate test cases for the current change.
- [ ] Model selection passthrough (`agy --model`).
- [ ] Optional hard-read-only containment for `review`/`doc` (e.g. run agy under an
      OS sandbox or a read-only bind mount) so it is not just worktree-and-discard.

## Robustness
- [ ] Distinguish agy not-authenticated vs network failure vs capture failure.
- [ ] Handle the ARG_MAX ceiling for very large prompts (agy has no prompt-file/stdin).
- [ ] CI: shellcheck the runners; smoke-test against a fixture repo.
- [ ] Verify `--add-dir` workspace semantics across agy versions.
