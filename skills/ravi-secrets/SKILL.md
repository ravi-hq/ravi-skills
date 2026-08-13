---
name: ravi-secrets
description: Store and retrieve key-value secrets — encrypted secret store for API keys and env vars. Do NOT use for website passwords (use ravi-passwords) or reading messages (use ravi-inbox).
---

# Ravi Secrets

Store and retrieve key-value secrets (API keys, environment variables, tokens). All values are encrypted. Use descriptive key names for lookup and filtering.

> **Cursor:** If Ravi MCP tools are connected, use them (identity, inbox, vault, send email, send SMS). Auth is the plugin **Connect** card — per-agent credentials, same as GitHub/Linear. Do **not** run `ravi auth login` or write `~/.ravi/config.json`. **CLI fallback** (one identity per machine — single agent / CI): if `ravi` is missing, `curl -fsSL https://raw.githubusercontent.com/ravi-hq/ravi-skills/main/scripts/install-cli.sh | bash` then `export PATH="$HOME/.ravi/bin:$PATH"`. Then `ravi auth login` (human visits https://ravi.id/device).

## Commands

```bash
# Store a secret
ravi secrets set OPENAI_API_KEY "sk-abc123..."

# List all secrets
ravi secrets list

# Retrieve a secret by key name
ravi secrets get OPENAI_API_KEY

# Delete a secret by UUID
ravi secrets delete <uuid>
```

## JSON Shapes

**`ravi secrets list`:**

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

**`ravi secrets get OPENAI_API_KEY`:**

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
ravi secrets set OPENAI_API_KEY "sk-abc123..."

# Retrieve the key value
API_KEY=$(ravi secrets get OPENAI_API_KEY | jq -r '.value')

# List all available key names
ravi secrets list | jq -r '.[].key'
```

### Store multiple service keys

```bash
ravi secrets set ANTHROPIC_API_KEY "sk-ant-..."
ravi secrets set GITHUB_TOKEN "ghp_..."
```

## Important Notes

- **Encryption** — values and notes are encrypted.
- **Keys must be unique per identity** — if you need to update an existing key, use `ravi secrets set` again (it will upsert). Creating a duplicate key name will return a validation error.
- **Keys are auto-uppercased** — keys are automatically uppercased (e.g. `test_key` becomes `TEST_KEY`). Keys must match `^[A-Z][A-Z0-9_]*$` after uppercasing.
- **Keys are for lookup** — values and notes are encrypted. Use descriptive key names like `OPENAI_API_KEY`, `STRIPE_SECRET_KEY`.

## Docs

[Docs](https://docs.ravi.app)

## Related Skills

- **ravi-passwords** — Store website credentials (domain + username + password, not key-value secrets)
- **ravi-login** — Signup workflows that may need API keys stored after registration
- **ravi-feedback** — Report secrets issues or suggest improvements
