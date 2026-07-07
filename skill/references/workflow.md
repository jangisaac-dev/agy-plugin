# agy-bridge — workflow & decision guide

## Which command?

- Quick second-opinion review of local changes → `review`.
- Draft README / docstrings / dev docs for the change → `doc`.
- Want a fast implementation draft → `fast-impl "<task>"`.

## Consent and prompts

- If the user explicitly asks for `agy`, `agy-bridge`, or `/agy:*`, proceed with
  the runner and request any required host/tool escalation directly.
- Do not ask a second natural-language "may I send this externally?" question
  after explicit invocation; the host approval prompt is the execution gate.
- If you are choosing agy without an explicit user request, explain that repo
  context is sent to agy's backend and ask first.

## agy vs grok (the sibling skill)

- **agy** = fast. Good for drafts, docs, tests, bulk/repetitive edits, quick takes.
  No enforced read-only mode (contained via worktree-and-discard).
- **grok** = stronger reasoning + a *hard* read-only mode. Prefer grok for
  trustworthy read-only review, adversarial critique, and security-sensitive reads.
- Rule of thumb: drafting/speed → agy; careful review/critique → grok.

## Reading agy output

`result.md` is raw stdout — agy interleaves "I will run …" narration with the
actual answer. Present the substantive part (review findings / doc / summary),
not the narration.

## Applying a `fast-impl` diff

agy never touches the live tree. To integrate:

1. Read `changes.diff` and `result.md`; show the proposed change.
2. **Verify it first** — agy is a fast drafter, more error-prone than a careful
   implementer. Sanity-check the logic before trusting it.
3. With user approval, apply from the repo root:
   ```bash
   git apply <repo>/.ai-runs/agy/<job-id>/changes.diff
   ```
   If it fails, re-create the edits manually from the diff.
4. Build/test before considering it done. Consider a `grok-bridge` review of the
   applied change for a second opinion.
