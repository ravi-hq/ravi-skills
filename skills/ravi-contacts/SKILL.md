---
name: ravi-contacts
description: Manage contacts associated with your identity — list, search, create,
  update, and delete. Use ravi-contacts to resolve a person's name to their email or phone
  before sending (e.g. "email Alice" or "text Bob" → search contacts first).
  Do NOT use for website credentials (use ravi-passwords) or API keys (use ravi-secrets).
---

# Ravi Contacts

Manage contacts associated with your identity. Contacts store people you interact with — their email, phone, display name, and nickname.

## Prerequisites

Load your API keys before making requests:

```bash
# Read identity key (for most operations)
RAVI_ID_KEY=$(cat .ravi/config.json 2>/dev/null | jq -r '.identity_key // empty')
[ -z "$RAVI_ID_KEY" ] && RAVI_ID_KEY=$(cat ~/.ravi/auth.json 2>/dev/null | jq -r '.identity_key // empty')
[ -z "$RAVI_ID_KEY" ] && echo "No identity key found. Run the ravi-login skill to onboard."
```

If keys are missing, use the **ravi-login** skill to onboard.

All contacts endpoints use the identity key:
```bash
-H "Authorization: Bearer $RAVI_ID_KEY"
```

## Commands

```bash
# List all contacts
curl -s -H "Authorization: Bearer $RAVI_ID_KEY" \
  https://ravi.id/api/contacts/ | jq

# Fuzzy search contacts by name or email (phone is not fuzzy-searched)
curl -s -H "Authorization: Bearer $RAVI_ID_KEY" \
  "https://ravi.id/api/contacts/search/?q=alice" | jq

# Find contact by exact email
curl -s -H "Authorization: Bearer $RAVI_ID_KEY" \
  "https://ravi.id/api/contacts/find/?email=alice@example.com" | jq

# Get a single contact
curl -s -H "Authorization: Bearer $RAVI_ID_KEY" \
  https://ravi.id/api/contacts/<uuid>/ | jq

# Create a contact
curl -s -X POST -H "Authorization: Bearer $RAVI_ID_KEY" \
  -H "Content-Type: application/json" \
  -d '{"email": "alice@example.com", "display_name": "Alice Smith"}' \
  https://ravi.id/api/contacts/ | jq

# Create with phone and nickname
curl -s -X POST -H "Authorization: Bearer $RAVI_ID_KEY" \
  -H "Content-Type: application/json" \
  -d '{"phone_number": "+15551234567", "nickname": "alice"}' \
  https://ravi.id/api/contacts/ | jq

# Create a full contact
curl -s -X POST -H "Authorization: Bearer $RAVI_ID_KEY" \
  -H "Content-Type: application/json" \
  -d '{"email": "bob@corp.com", "phone_number": "+15559876543", "display_name": "Bob Jones", "nickname": "bob"}' \
  https://ravi.id/api/contacts/ | jq

# Create a trusted contact
curl -s -X POST -H "Authorization: Bearer $RAVI_ID_KEY" \
  -H "Content-Type: application/json" \
  -d '{"email": "alice@example.com", "display_name": "Alice", "is_trusted": true}' \
  https://ravi.id/api/contacts/ | jq

# Mark existing contact as trusted
curl -s -X PATCH -H "Authorization: Bearer $RAVI_ID_KEY" \
  -H "Content-Type: application/json" \
  -d '{"is_trusted": true}' \
  https://ravi.id/api/contacts/<uuid>/ | jq

# Update a contact
curl -s -X PATCH -H "Authorization: Bearer $RAVI_ID_KEY" \
  -H "Content-Type: application/json" \
  -d '{"nickname": "ally"}' \
  https://ravi.id/api/contacts/<uuid>/ | jq

# Delete a contact
curl -s -X DELETE -H "Authorization: Bearer $RAVI_ID_KEY" \
  https://ravi.id/api/contacts/<uuid>/
```

**Create/update body fields:** `email`, `phone_number`, `display_name`, `nickname`, `is_trusted`

## JSON Shapes

**`GET /api/contacts/`:**
```json
[
  {
    "uuid": "...",
    "email": "alice@example.com",
    "phone_number": "+15551234567",
    "display_name": "Alice Smith",
    "nickname": "alice",
    "is_trusted": false,
    "source": "auto",
    "interaction_count": 5,
    "last_interaction_dt": "2026-03-01T14:00:00Z",
    "created_dt": "2026-02-20T10:30:00Z"
  }
]
```

**`GET /api/contacts/<uuid>/`:**
```json
{
  "uuid": "...",
  "email": "alice@example.com",
  "phone_number": "+15551234567",
  "display_name": "Alice Smith",
  "nickname": "alice",
  "is_trusted": false,
  "source": "auto",
  "interaction_count": 5,
  "last_interaction_dt": "2026-03-01T14:00:00Z",
  "created_dt": "2026-02-20T10:30:00Z",
  "updated_dt": "2026-02-28T09:15:00Z"
}
```

## Resolving Recipients

When the user asks to email or text someone by name (e.g. "email Alice" or "text Bob"), **always search contacts first** to resolve their name to an email address or phone number:

```bash
# Step 1: Search by name
curl -s -H "Authorization: Bearer $RAVI_ID_KEY" \
  "https://ravi.id/api/contacts/search/?q=Alice" | jq

# Step 2: If one match → use the email/phone from the result
# Step 3: If multiple matches → confirm with the user which one they mean
# Step 4: If no matches → ask the user for the email/phone directly
```

This is the primary integration point with **ravi-email-send** and SMS workflows.

## Key Concepts

- **Auto-contacts** — Ravi automatically creates contacts from email and SMS interactions. When you send or receive a message, a contact is created or updated for the other party.
- **Manual contacts** — You can also create contacts manually via the API.
- **Trusted contacts** — Contacts marked with `"is_trusted": true` are classified as trusted senders. Emails from trusted contacts are routed to the `email_trusted` SSE channel, distinct from `email_owner` (your own emails) and `email_untrusted` (unknown senders). By default, contacts are not trusted.
- **`interaction_count`** — Tracks how many email/SMS interactions you have had with this contact. Auto-incremented by the system.
- **`last_interaction_dt`** — Timestamp of the most recent email or SMS interaction with this contact. Updated automatically.

## Important Notes

- **Contacts are stored in plaintext** — do not store sensitive information in contact fields. Use **ravi-passwords** for credentials and **ravi-secrets** for API keys.
- **Auto-contacts from interactions** — sending or receiving email/SMS automatically creates or updates contacts. You do not need to manually create contacts for people you interact with.
- **Phone numbers in E.164 format** — always include the country code (e.g., `+15551234567`).

## Related Skills

- **ravi-identity** — Get your own email address and phone number
- **ravi-passwords** — Store website credentials (not contact info)
- **ravi-secrets** — Store API keys and env vars (not contact info)
- **ravi-inbox** — Read incoming email and SMS messages
- **ravi-email-send** — Send emails to your contacts
