---
name: ravi-identity
description: Get your agent identity (email, phone, owner name) and manage identities. Do NOT use for reading messages (use ravi-inbox), sending email (use ravi-email-send), or credentials (use ravi-passwords or ravi-secrets).
---

# Ravi Identity

You have access to Ravi, an identity provider that gives you your own phone number, email address, and secret store via its REST API.

## Prerequisites

Load your API keys before making requests:

```bash
# Read identity key (for most operations)
RAVI_ID_KEY=$(cat .ravi/config.json 2>/dev/null | jq -r '.identity_key // empty')
[ -z "$RAVI_ID_KEY" ] && RAVI_ID_KEY=$(cat ~/.ravi/config.json 2>/dev/null | jq -r '.identity_key // empty')
[ -z "$RAVI_ID_KEY" ] && echo "No identity key found. Run the ravi-login skill to onboard."

# Read management key (for account operations — only needed by ravi-identity)
RAVI_MGMT_KEY=$(cat ~/.ravi/config.json 2>/dev/null | jq -r '.management_key // empty')
```

If keys are missing, use the **ravi-login** skill to onboard.

## Your Identity

```bash
# List your identities (includes email, phone, name)
curl -s -H "Authorization: Bearer $RAVI_MGMT_KEY" \
  https://ravi.id/api/identities/ | jq

# Get a specific identity by UUID
curl -s -H "Authorization: Bearer $RAVI_MGMT_KEY" \
  https://ravi.id/api/identities/<uuid>/ | jq
```

**Response shape:**
```json
[{
  "uuid": "...",
  "name": "Sarah Johnson",
  "email": "sarah.johnson472@ravi.id",
  "phone_number": "+15551234567",
  "created_dt": "2026-02-25T10:30:00Z"
}]
```

Extract specific fields:
```bash
# Your email address (use this for signups)
curl -s -H "Authorization: Bearer $RAVI_MGMT_KEY" \
  https://ravi.id/api/identities/ | jq -r '.[0].email'

# Your phone number (use this for SMS verification)
curl -s -H "Authorization: Bearer $RAVI_MGMT_KEY" \
  https://ravi.id/api/identities/ | jq -r '.[0].phone_number'

# Your identity name (use this for form fields, email signatures)
curl -s -H "Authorization: Bearer $RAVI_MGMT_KEY" \
  https://ravi.id/api/identities/ | jq -r '.[0].name'
```

## Creating a New Identity

Only create a new identity when the user explicitly asks for one (e.g., for a separate project that needs its own email/phone). New identities require a paid plan.

```bash
# Auto-generated name and email (recommended — looks like a real person)
curl -s -X POST -H "Authorization: Bearer $RAVI_MGMT_KEY" \
  -H "Content-Type: application/json" \
  -d '{}' \
  https://ravi.id/api/identities/ | jq
# → name: "Sarah Johnson", email: "sarah.johnson472@ravi.id"

# Custom name, auto-generated email
curl -s -X POST -H "Authorization: Bearer $RAVI_MGMT_KEY" \
  -H "Content-Type: application/json" \
  -d '{"name": "Shopping Agent"}' \
  https://ravi.id/api/identities/ | jq

# Custom email local part
curl -s -X POST -H "Authorization: Bearer $RAVI_MGMT_KEY" \
  -H "Content-Type: application/json" \
  -d '{"name": "Work Agent", "email_local": "shopping"}' \
  https://ravi.id/api/identities/ | jq

# List available domains
curl -s -H "Authorization: Bearer $RAVI_MGMT_KEY" \
  https://ravi.id/api/domains/ | jq
```

When name is omitted, the server generates a realistic human name like "Sarah Johnson". The auto-generated email uses the same name: `sarah.johnson472@ravi.id`.

**Custom email rules:** 3-30 chars, lowercase alphanumeric + dots + hyphens, must start/end with letter or number, no consecutive dots (`..`) or hyphens (`--`). Returns HTTP 409 if the email address is already taken.

The response includes `api_key` — a `ravi_id_...` key for this new identity. Save it to `.ravi/config.json`.

## Identity Keys

Each identity has its own identity key. To list and manage identity keys:

```bash
# List identity keys
curl -s -H "Authorization: Bearer $RAVI_ID_KEY" \
  https://ravi.id/api/auth/keys/identity/ | jq

# Create a new identity key
curl -s -X POST -H "Authorization: Bearer $RAVI_ID_KEY" \
  -H "Content-Type: application/json" \
  -d '{"name": "my-agent-key"}' \
  https://ravi.id/api/auth/keys/identity/ | jq
```

## Important Notes

- **Identity name for forms** — use the identity name (`.[0].name`) for signup forms, not the account owner's name.
- **Identities are permanent** — each identity has its own email, phone, and secrets. Don't create new identities unless the user asks.
- **Identity key is identity-scoped** — it gives access to one specific identity's inbox, vault, and contacts.


## Full API Reference

For complete endpoint details, request/response schemas, and parameters: [Identities](https://ravi.id/docs/schema/identities.json)

## Related Skills

- **ravi-inbox** — Read SMS and email messages
- **ravi-email-send** — Compose, reply, forward emails
- **ravi-email-writing** — Write professional emails with proper formatting and tone
- **ravi-contacts** — Look up or manage contacts associated with this identity
- **ravi-passwords** — Store and retrieve website credentials
- **ravi-secrets** — Store and retrieve key-value secrets
- **ravi-login** — Device code onboarding, sign up for and log into services, handle 2FA/OTPs
- **ravi-feedback** — Send feedback, report bugs, request features
