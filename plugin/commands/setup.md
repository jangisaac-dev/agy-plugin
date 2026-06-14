---
description: Check whether the local agy CLI is installed and authenticated
argument-hint: ''
allowed-tools: Bash(bash:*)
---

!`bash "${CLAUDE_PLUGIN_ROOT}/scripts/agy-run.sh" setup`

Present the readiness report to the user. This check is local only — it does not
make a network call. If the CLI is `NOT FOUND`, tell the user to install `agy`
and then authenticate. If `auth` is not detected, tell them to log in with `agy`.
Do not attempt to install or authenticate on the user's behalf.
