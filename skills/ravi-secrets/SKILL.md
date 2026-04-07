---
name: ravi-secrets
description: Store and retrieve key-value secrets — encrypted secret store for API keys and env vars. Do NOT use for website passwords (use ravi-passwords) or reading messages (use ravi-inbox).
---

# Ravi Secrets

Store and retrieve key-value secrets (API keys, environment variables, tokens). All values are server-side encrypted — you send and receive plaintext. Keys are stored in plaintext for lookup/filtering.

## Prerequisites

Load your API keys before making requests:

```bash
# Read identity key (for most operations)
RAVI_ID_KEY=$(cat .ravi/config.json 2>/dev/null | jq -r '.identity_key // empty')
[ -z "$RAVI_ID_KEY" ] && RAVI_ID_KEY=$(cat ~/.ravi/config.json 2>/dev/null | jq -r '.identity_key // empty')
[ -z "$RAVI_ID_KEY" ] && echo "No identity key found. Run the ravi-login skill to onboard."
```

If keys are missing, use the **ravi-login** skill to onboard.

All secrets endpoints use the identity key:
```bash
-H "Authorization: Bearer $RAVI_ID_KEY"
```

## Commands

```bash
# Store a secret (creates new entry)
curl -s -X POST -H "Authorization: Bearer $RAVI_ID_KEY" \
  -H "Content-Type: application/json" \
  -d '{"key": "OPENAI_API_KEY", "value": "sk-abc123..."}' \
  https://ravi.id/api/secrets/ | jq

# With optional notes
curl -s -X POST -H "Authorization: Bearer $RAVI_ID_KEY" \
  -H "Content-Type: application/json" \
  -d '{"key": "STRIPE_SECRET_KEY", "value": "sk_live_...", "notes": "Production key"}' \
  https://ravi.id/api/secrets/ | jq

# List all secrets
curl -s -H "Authorization: Bearer $RAVI_ID_KEY" \
  https://ravi.id/api/secrets/ | jq

# Retrieve a secret by UUID
curl -s -H "Authorization: Bearer $RAVI_ID_KEY" \
  https://ravi.id/api/secrets/<uuid>/ | jq

# Update a secret
curl -s -X PATCH -H "Authorization: Bearer $RAVI_ID_KEY" \
  -H "Content-Type: application/json" \
  -d '{"value": "sk-new-value..."}' \
  https://ravi.id/api/secrets/<uuid>/ | jq

# Delete a secret by UUID
curl -s -X DELETE -H "Authorization: Bearer $RAVI_ID_KEY" \
  https://ravi.id/api/secrets/<uuid>/
```

## JSON Shapes

**`GET /api/secrets/`:**
```json
[
  {
    "uuid": "...",
    "identity": 1,
    "key": "OPENAI_API_KEY",
    "value": "sk-abc123...",
    "notes": "",
    "created_dt": "2026-02-25T10:30:00Z",
    "updated_dt": "2026-02-25T10:30:00Z"
  }
]
```

**`GET /api/secrets/<uuid>/`:**
```json
{
  "uuid": "...",
  "identity": 1,
  "key": "OPENAI_API_KEY",
  "value": "sk-abc123...",
  "notes": "",
  "created_dt": "2026-02-25T10:30:00Z",
  "updated_dt": "2026-02-25T10:30:00Z"
}
```

## Common Patterns

### Store and retrieve API keys at runtime

```bash
# Store a key
curl -s -X POST -H "Authorization: Bearer $RAVI_ID_KEY" \
  -H "Content-Type: application/json" \
  -d '{"key": "OPENAI_API_KEY", "value": "sk-abc123..."}' \
  https://ravi.id/api/secrets/ | jq

# Retrieve the key by searching the list
API_KEY=$(curl -s -H "Authorization: Bearer $RAVI_ID_KEY" \
  https://ravi.id/api/secrets/ | \
  jq -r '.[] | select(.key == "OPENAI_API_KEY") | .value')

curl -H "Authorization: Bearer $API_KEY" https://api.openai.com/v1/...

# List all available key names
curl -s -H "Authorization: Bearer $RAVI_ID_KEY" \
  https://ravi.id/api/secrets/ | jq -r '.[].key'
```

### Store multiple service keys

```bash
for item in \
  '{"key": "ANTHROPIC_API_KEY", "value": "sk-ant-..."}' \
  '{"key": "GITHUB_TOKEN", "value": "ghp_..."}'; do
  curl -s -X POST -H "Authorization: Bearer $RAVI_ID_KEY" \
    -H "Content-Type: application/json" \
    -d "$item" \
    https://ravi.id/api/secrets/ | jq -r '.key'
done
```

## Important Notes

- **Server-side encryption is transparent** — you always see plaintext values.
- **Keys must be unique per identity** — if you need to update an existing key, use PATCH on the UUID. Creating a duplicate key name will return a validation error.
- **Keys are auto-uppercased** — keys are automatically uppercased by the server (e.g. `test_key` becomes `TEST_KEY`). Keys must match `^[A-Z][A-Z0-9_]*$` after uppercasing.
- **Keys are plaintext** — only values and notes are encrypted. Use descriptive key names like `OPENAI_API_KEY`, `STRIPE_SECRET_KEY`.


## Full API Reference

For complete endpoint details, request/response schemas, and parameters: [Secrets](https://ravi.id/docs/schema/secrets.json)

## Related Skills

- **ravi-passwords** — Store website credentials (domain + username + password, not key-value secrets)
- **ravi-login** — Signup workflows that may need API keys stored after registration
- **ravi-feedback** — Report secrets issues or suggest improvements
