---
name: ravi-identity
description: >
  Use when you need to check Ravi authentication status, get your agent's email
  address or phone number, list or switch between identities, or create a new
  identity. Do NOT use for reading messages, sending email, or vault operations.
---

# Ravi Identity

You have access to `ravi`, a CLI that gives you your own phone number, email address, and credential vault.

## Prerequisites

### Install the CLI

If `ravi` is not installed, tell the user to install it:

```bash
brew install ravi-hq/tap/ravi
```

### Check authentication

Verify you're authenticated before using any command:

```bash
ravi auth status --json
```

If `"authenticated": false`, tell the user to run `ravi auth login` (requires browser interaction — you cannot do this yourself).

## Your Identity

```bash
# Your email address (use this for signups)
ravi get email --json
# → {"id": 1, "email": "janedoe@ravi.app", "created_dt": "..."}

# Your phone number (use this for SMS verification)
ravi get phone --json
# → {"id": 1, "phone_number": "+15551234567", "provider": "twilio", "created_dt": "..."}

# The human who owns this account
ravi get owner --json
# → {"first_name": "Jane", "last_name": "Doe"}
```

## Switching Identities

Ravi supports multiple identities. Each identity has its own email, phone, and vault.

### Listing identities

```bash
ravi identity list --json
```

### Setting an identity for this project

Use this when the user wants a different identity for a specific project:

1. List identities: `ravi identity list --json`
2. Set for this project (per-directory override):
   - `mkdir -p .ravi && echo '{"identity_uuid":"<uuid>","identity_name":"<name>"}' > .ravi/config.json`
   - Add `.ravi/` to `.gitignore`

All `ravi` commands in this directory will use the specified identity.

### Switching identity globally

```bash
ravi identity use "<name-or-uuid>"
```

### Creating a new identity

Only create a new identity when the user explicitly asks for one (e.g., for a
separate project that needs its own email/phone). New identities require a paid
plan and take a moment to provision.

```bash
ravi identity create --name "Project Name" --json
```

## Important Notes

- **Always use `--json`** — all commands support it. Human-readable output is not designed for parsing.
- **Auth is automatic** — token refresh happens transparently. If you get auth errors, ask the user to re-login.
- **Identity resolution** — `.ravi/config.json` in CWD takes priority over `~/.ravi/config.json`.
- **Identities are permanent** — each identity has its own email, phone, and vault. Don't create new identities unless the user asks for it.
