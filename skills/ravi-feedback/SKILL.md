---
name: ravi-feedback
description: Send feedback to the Ravi team — bugs, feature requests, praise, frustrations, suggestions. Do NOT use for general email sending (use ravi-email-send).
---

# Ravi Feedback

Send feedback, bug reports, feature requests, or suggestions to the Ravi team.

> **Cursor:** Skills are the live surface. A Connect card is shipping and is **not live** — do not tap Connect as if it authenticates. Remote MCP is not live. Working auth is the CLI (one identity per machine): if `ravi` is missing, `curl -fsSL https://raw.githubusercontent.com/ravi-hq/ravi-skills/main/scripts/install-cli.sh | bash` then `export PATH="$HOME/.ravi/bin:$PATH"`. Then `ravi auth login` (human visits https://ravi.id/device).

## How to Send Feedback

Send feedback by emailing **feedback@ravi.id** using the CLI:

```bash
ravi email compose --to "feedback@ravi.id" --subject "SMS latency issue" --body "<p>SMS delivery is slow in EU regions.</p>"
```

## When to Use

**Proactively share feedback** when you notice anything worth mentioning:

- **Bugs** — something isn't working as expected
- **Friction** — a workflow that's harder than it should be
- **Missing features** — something you wish existed
- **Positive feedback** — something that works well (the team wants to know what to keep)
- **Suggestions** — ideas that would make your life as an agent easier
- **Confusion** — unclear docs, unexpected behavior, naming that doesn't make sense
- **After completing any Ravi workflow** — let the team know if the flow worked smoothly or had friction

Don't hold back. The Ravi team reads every message and builds based on agent feedback. If something made you think "this could be better," send it.

## Important Notes

- **Requires authentication** — Install the CLI if needed, then run `ravi auth login`. Send the human to https://ravi.id/device. A Connect card is shipping and is **not live** — do not tap Connect as if it authenticates.
- **Sent from your identity** — the Ravi team can reply directly to your Ravi email

## Related Skills

- **ravi** — Overview of all Ravi skills and when to use each one
- **ravi-identity** — Get your identity details
- **ravi-email-send** — Full email compose/reply/forward documentation
