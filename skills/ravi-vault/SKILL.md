---
name: ravi-vault
description: Store and retrieve key-value secrets — E2E encrypted vault for API keys and env vars. Do NOT use for website passwords (use ravi-passwords) or reading messages (use ravi-inbox).
---

# Ravi Vault

Store and retrieve key-value secrets (API keys, environment variables, tokens). All values are E2E encrypted — the CLI handles encryption/decryption transparently. Keys are stored in plaintext for lookup/filtering.

## Commands

```bash
# Store a secret (creates or updates)
ravi vault set OPENAI_API_KEY "sk-abc123..." --json

# With optional notes
ravi vault set STRIPE_SECRET_KEY "sk_live_..." --notes "Production key" --json

# Retrieve a secret by key
ravi vault get OPENAI_API_KEY --json
# -> {"key": "OPENAI_API_KEY", "value": "sk-abc123...", "notes": "", ...}

# List all secrets (values redacted in list view)
ravi vault list --json

# Delete a secret by key
ravi vault delete OPENAI_API_KEY --json
```

## JSON Shapes

**`ravi vault list --json`:**
```json
[
  {
    "id": "uuid",
    "key": "OPENAI_API_KEY",
    "notes": "",
    "created_dt": "2026-02-25T10:30:00Z",
    "updated_dt": "2026-02-25T10:30:00Z"
  }
]
```

**`ravi vault get KEY --json`:**
```json
{
  "id": "uuid",
  "key": "OPENAI_API_KEY",
  "value": "sk-abc123...",
  "notes": "",
  "created_dt": "2026-02-25T10:30:00Z",
  "updated_dt": "2026-02-25T10:30:00Z"
}
```

## OpenClaw Integration

When an agent needs API keys or secrets at runtime, use Ravi Vault as the backing store:

```bash
# Store a key for the agent to use later
ravi vault set OPENAI_API_KEY "sk-abc123..." --json

# At runtime, retrieve the key
API_KEY=$(ravi vault get OPENAI_API_KEY --json | jq -r '.value')
curl -H "Authorization: Bearer $API_KEY" https://api.openai.com/v1/...

# Store multiple service keys
ravi vault set ANTHROPIC_API_KEY "sk-ant-..." --json
ravi vault set GITHUB_TOKEN "ghp_..." --json

# List all available keys
ravi vault list --json | jq -r '.[].key'
```

## Important Notes

- **E2E encryption is transparent** — the CLI encrypts values before sending and decrypts on retrieval. You see plaintext.
- **Keys are unique per identity** — setting a key that already exists updates it.
- **Keys are plaintext** — only values and notes are E2E encrypted. Use descriptive key names like `OPENAI_API_KEY`, `STRIPE_SECRET_KEY`.
- **Always use `--json`** — human-readable output is not designed for parsing.
- **For website credentials** (domain + username + password), use `ravi passwords` instead — see the `ravi-passwords` skill.
