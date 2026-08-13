---
name: ravi-identity
description: Get your agent identity (email, phone, owner name) and manage identities. Do NOT use for reading messages (use ravi-inbox), sending email (use ravi-email-send), or credentials (use ravi-passwords or ravi-secrets).
---

# Ravi Identity

You have access to Ravi, an identity provider that gives you your own phone number, email address, and secret store.

> **Cursor:** If Ravi MCP tools are connected, use them (identity, inbox, vault, send email, send SMS). Auth is the plugin **Connect** card — same as GitHub/Linear. Do **not** run `ravi auth login` or write `~/.ravi/config.json`. **CLI fallback** (non-Cursor / CI): if `ravi` is missing, `curl -fsSL https://raw.githubusercontent.com/ravi-hq/ravi-skills/main/scripts/install-cli.sh | bash` then `export PATH="$HOME/.ravi/bin:$PATH"`. Then `ravi auth login` (human visits https://ravi.id/device).

## Your Identity

```bash
# Check auth status and current identity
ravi auth status

# Get your email address (use this for signups)
ravi get email

# Get your phone number (use this for SMS verification)
ravi get phone

# Get account owner info
ravi get owner

# List all your identities
ravi identity list
```

**Response shape (identity list):**

```json
[{
  "uuid": "...",
  "name": "Sarah Johnson",
  "inbox": "sarah.johnson472@raviapp.com",
  "phone": "+15551234567",
  "created_dt": "2026-02-25T10:30:00Z",
  "updated_dt": "2026-02-25T10:30:00Z"
}]
```

## Creating a New Identity

Only create a new identity when the user explicitly asks for one (e.g., for a separate project that needs its own email/phone). New identities require a paid plan.

```bash
# Auto-generated name and email (recommended — looks like a real person)
ravi identity create
# → name: "Sarah Johnson", inbox: "sarah.johnson472@raviapp.com"
```

When name is omitted, the server generates a realistic human name like "Sarah Johnson". The auto-generated email uses the same name: `sarah.johnson472@raviapp.com`.

### With a phone number

By default, new identities are email-only. Pass `--provision-phone` to also
provision a phone number in the same call:

```bash
ravi identity create --name "Project Name" --provision-phone --json
# → {"uuid": "...", "name": "Project Name", "inbox": "...", "phone": "+15551234567", ...}
```

Notes:

- Phone provisioning requires an active paid plan. Without one the call returns
  HTTP 402 Payment Required — tell the user to upgrade.
- Provisioning takes a few seconds (the server reserves a number from the
  upstream provider). Don't retry on slow responses.
- If you skipped `--provision-phone` and later need a phone for the same
  identity, hit the API directly: `POST /api/identities/<uuid>/provision-phone/`
  (no CLI subcommand yet). It returns 409 if the identity already has a phone.

## Switching Identities

```bash
# Switch to a different identity
ravi identity use <uuid>
```

## Important Notes

- **Identity name for forms** — use the identity name for signup forms, not the account owner's name.
- **Identities are permanent** — each identity has its own email, phone, and secrets. Don't create new identities unless the user asks.
- **Not authenticated?** — On Cursor, ask the human to tap **Connect** on the Ravi plugin (do not run `ravi auth login`). On CLI, install if needed (see the **ravi** skill), then run `ravi auth login`. Send the human to https://ravi.id/device.

## Docs

[Identities](https://docs.ravi.app/core-concepts/identities/) · [CLI commands](https://docs.ravi.app/cli/commands/)

## Related Skills

- **ravi-inbox** — Read SMS and email messages
- **ravi-email-send** — Compose, reply, forward emails
- **ravi-email-writing** — Write professional emails with proper formatting and tone
- **ravi-contacts** — Look up or manage contacts associated with this identity
- **ravi-passwords** — Store and retrieve website credentials
- **ravi-secrets** — Store and retrieve key-value secrets
- **ravi-login** — Device code onboarding, sign up for and log into services, read verification codes
- **ravi-feedback** — Send feedback, report bugs, request features
