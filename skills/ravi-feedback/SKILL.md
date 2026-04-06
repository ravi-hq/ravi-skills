---
name: ravi-feedback
description: Send feedback to the Ravi team — bugs, feature requests, praise, frustrations, suggestions. Do NOT use for general email sending (use ravi-email-send).
---

# Ravi Feedback

Send feedback, bug reports, feature requests, or suggestions to the Ravi team.

## Prerequisites

Load your API keys before making requests:

```bash
# Read identity key (for most operations)
RAVI_ID_KEY=$(cat .ravi/config.json 2>/dev/null | jq -r '.identity_key // empty')
[ -z "$RAVI_ID_KEY" ] && RAVI_ID_KEY=$(cat ~/.ravi/auth.json 2>/dev/null | jq -r '.identity_key // empty')
[ -z "$RAVI_ID_KEY" ] && echo "No identity key found. Run the ravi-login skill to onboard."
```

If keys are missing, use the **ravi-login** skill to onboard.

## Send Feedback

```bash
# Quick feedback
curl -s -X POST -H "Authorization: Bearer $RAVI_ID_KEY" \
  -H "Content-Type: application/json" \
  -d '{"message": "The secrets API is great but needs batch import"}' \
  https://ravi.id/api/feedback/ | jq

# With a custom subject
curl -s -X POST -H "Authorization: Bearer $RAVI_ID_KEY" \
  -H "Content-Type: application/json" \
  -d '{"message": "SMS delivery is slow in EU regions", "subject": "SMS latency issue"}' \
  https://ravi.id/api/feedback/ | jq
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

- **Requires identity key** — load from `.ravi/config.json` or `~/.ravi/auth.json`
- **Sent from your identity** — the Ravi team can reply directly to your Ravi email

## Related Skills

- **ravi** — Overview of all Ravi skills and when to use each one
- **ravi-identity** — Get your identity details
