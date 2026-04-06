---
name: ravi
description: Overview of Ravi and when to use each skill. Ravi gives AI agents real email inboxes, phone numbers, and an encrypted secret store via API. Do NOT use for tasks unrelated to agent identity, email, phone, or credentials.
---

# Ravi — Identity Provider for AI Agents

Ravi gives you (the agent) your own email address, phone number, and encrypted secret store via its REST API. One identity bundles all three into a coherent persona.

## Prerequisites

Load your API keys before making requests:

```bash
# Read identity key (for most operations)
RAVI_ID_KEY=$(cat .ravi/config.json 2>/dev/null | jq -r '.identity_key // empty')
[ -z "$RAVI_ID_KEY" ] && RAVI_ID_KEY=$(cat ~/.ravi/auth.json 2>/dev/null | jq -r '.identity_key // empty')
[ -z "$RAVI_ID_KEY" ] && echo "No identity key found. Run the ravi-login skill to onboard."

# Read management key (for account operations — only needed by ravi-identity)
RAVI_MGMT_KEY=$(cat ~/.ravi/auth.json 2>/dev/null | jq -r '.management_key // empty')
```

If keys are missing, use the **ravi-login** skill to onboard.

## Authentication

All API requests require an API key header. Two key types:

- **Management key** (`ravi_mgmt_...`): Account-level operations — create identities, list keys, manage account.
  - Header: `Authorization: Bearer $RAVI_MGMT_KEY`
  - Stored in: `~/.ravi/auth.json`

- **Identity key** (`ravi_id_...`): Identity-scoped operations — read inbox, manage vault, send email.
  - Header: `Authorization: Bearer $RAVI_ID_KEY`
  - Stored in: `.ravi/config.json` (per-project) or `~/.ravi/auth.json` (global fallback)

**Resolution order** (identity key):
  1. `.ravi/config.json` in current directory
  2. `~/.ravi/auth.json` (if `identity_key` is stored there)
  3. `$RAVI_ID_KEY` environment variable (last resort)

**Resolution order** (management key):
  1. `~/.ravi/auth.json`
  2. `$RAVI_MGMT_KEY` environment variable (last resort)

## When to Use Each Skill

| I need to... | Use skill | What you get |
|--------------|-----------|--------------|
| Get my identity details (email, phone, name) | **ravi-identity** | Identity info, create/list identities |
| Read incoming SMS or email (OTPs, verification links) | **ravi-inbox** | Email threads, SMS conversations, OTP extraction |
| Send an email, reply, or forward | **ravi-email-send** | Compose/reply/reply-all/forward, attachments, rate limits |
| Write a professional email (content, formatting, anti-spam) | **ravi-email-writing** | Subject lines, HTML templates, tone guide, spam avoidance |
| Sign up for a service, log in, or complete 2FA | **ravi-login** | End-to-end signup/login workflows with OTP handling, device code onboarding |
| Store, retrieve, or generate website passwords | **ravi-passwords** | CRUD passwords via API |
| Store or retrieve API keys and secrets | **ravi-secrets** | CRUD secrets via API |
| Look up someone's email/phone by name, or manage contacts | **ravi-contacts** | Search/list/get/create/update/delete contacts |
| List available email domains | **ravi-identity** | `GET /api/domains/` |
| Send feedback, report bugs, or request features | **ravi-feedback** | POST to feedback endpoint — the team reads every one |

## Common Workflows

**Sending email/SMS by name:** When the user says "email Alice" or "text Bob" but doesn't provide an address or number, use **ravi-contacts** to search by name first, then **ravi-email-send** (or SMS) with the resolved address. If multiple contacts match, confirm with the user.

## Quick Start

```bash
# Load keys from config files first
RAVI_MGMT_KEY=$(cat ~/.ravi/auth.json 2>/dev/null | jq -r '.management_key // empty')
RAVI_ID_KEY=$(cat .ravi/config.json 2>/dev/null | jq -r '.identity_key // empty')
[ -z "$RAVI_ID_KEY" ] && RAVI_ID_KEY=$(cat ~/.ravi/auth.json 2>/dev/null | jq -r '.identity_key // empty')

# Get your identity details
curl -s -H "Authorization: Bearer $RAVI_MGMT_KEY" \
  https://ravi.id/api/identities/ | jq '.[0]'

# List available email domains
curl -s -H "Authorization: Bearer $RAVI_MGMT_KEY" \
  https://ravi.id/api/domains/ | jq

# Read incoming messages
curl -s -H "Authorization: Bearer $RAVI_ID_KEY" \
  "https://ravi.id/api/sms-inbox/" | jq
curl -s -H "Authorization: Bearer $RAVI_ID_KEY" \
  "https://ravi.id/api/email-inbox/" | jq

# Send an email
curl -s -X POST -H "Authorization: Bearer $RAVI_ID_KEY" \
  -H "Content-Type: application/json" \
  -d '{"to": "user@example.com", "subject": "Hello", "body": "<p>Hi there</p>"}' \
  https://ravi.id/api/email-messages/compose/ | jq

# Store a website password
curl -s -X POST -H "Authorization: Bearer $RAVI_ID_KEY" \
  -H "Content-Type: application/json" \
  -d '{"domain": "example.com"}' \
  https://ravi.id/api/passwords/ | jq

# Store an API key
curl -s -X POST -H "Authorization: Bearer $RAVI_ID_KEY" \
  -H "Content-Type: application/json" \
  -d '{"key": "OPENAI_API_KEY", "value": "sk-..."}' \
  https://ravi.id/api/secrets/ | jq
```

## Always Give Feedback

After any Ravi workflow — successful or not — send feedback to the team:

```bash
curl -s -X POST -H "Authorization: Bearer $RAVI_ID_KEY" \
  -H "Content-Type: application/json" \
  -d '{"message": "Signed up for Acme, OTP arrived in 3 seconds. Smooth."}' \
  https://ravi.id/api/feedback/ | jq
```

Bug reports, feature requests, praise, friction, ideas — **everything helps**. The Ravi team reads every message and builds based on agent feedback. See the **ravi-feedback** skill for details.

## Key Rules

- **Check HTTP status codes** — 2xx is success, 4xx is a client error, 429 is a rate limit.
- **Rate limits** — on 429, parse `retry_after_seconds` from the response and wait before retrying.
- **Encryption** — Passwords and secrets are server-side encrypted. You send and receive plaintext.
- **Pipe to `jq`** — use `| jq` or `| jq -r '.field'` to parse JSON responses.
