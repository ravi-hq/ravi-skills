---
name: ravi-login
description: Sign up for and log into services using your Ravi identity — handles onboarding, forms, verification codes read from SMS/email, and credential storage. Do NOT use for standalone inbox reading (use ravi-inbox) or email sending (use ravi-email-send).
---

# Ravi Login

End-to-end workflows for onboarding to Ravi, signing up for services, logging in, and completing verification by reading the code the service sends to your identity's SMS or email.

## Step 0: Cursor Connect, else install the CLI

On Cursor, tap **Connect** on the Ravi plugin (same as GitHub/Linear). That is auth — per-agent credentials, a fenced `ravi_id_` bound to this agent. Use MCP tools for identity, inbox, and vault. Do **not** install a CLI, run `ravi auth login`, or write `~/.ravi/config.json`.

If MCP is not available (single agent / CI on Claude Code, skills.sh, or similar), install the CLI before `ravi auth login`:

```bash
if ! command -v ravi >/dev/null 2>&1; then
  if [ -f scripts/install-cli.sh ]; then
    bash scripts/install-cli.sh
  else
    curl -fsSL https://raw.githubusercontent.com/ravi-hq/ravi-skills/main/scripts/install-cli.sh | bash
  fi
  export PATH="$HOME/.ravi/bin:$PATH"
fi
```

The bundled copy lives next to this skill at `scripts/install-cli.sh`. Homebrew users can instead run `brew install ravi-hq/tap/ravi`.

---

## Step 1: Check Auth Status

Before doing anything else, check whether you're already authenticated:

```bash
ravi auth status
```

If authenticated, skip to [Sign up for a service](#sign-up-for-a-service).

---

## Step 2: Onboard to Ravi

If you're not authenticated, run the login flow. This is a one-time setup — the CLI handles the device code flow, polls for authorization, and stores keys automatically.

```bash
ravi auth login
```

Auth commands are **`login`**, **`logout`**, and **`status` only**. There is no `ravi auth refresh`.

The CLI will:

1. Initiate a device code flow against `https://api.ravi.app`
2. Display a URL and code for the human to visit
3. Poll until the human approves
4. Store long-lived `ravi_mgmt_...` / `ravi_id_...` keys in `~/.ravi/config.json`

Present the **public front door** and code clearly to the human (use this even if the CLI prints a different URL):

```
Please visit https://ravi.id/device and enter the code: ABCD-1234
```

The CLI may print `https://api.ravi.app/api/auth/device/verify/` — that is the shipped API verify URL. Still send the human to **https://ravi.id/device**. Never `https://ravi.app/api/auth/device/verify/` (wrong host).

The human visits https://ravi.id/device, signs in with Google, and approves the request.

Do **not** look for JWTs, `~/.ravi/auth.json`, `RAVI_ACCESS_TOKEN`, or an `X-Ravi-Identity` header. The CLI reads `~/.ravi/config.json` automatically.

---

## Step 3: One identity per machine

The CLI is **one identity per machine**. Shared `~/.ravi/config.json` is not a multi-agent runtime. Do **not** run `ravi identity use`, pass `--identity`, or edit that file so agents can run side by side.

```bash
ravi identity list
ravi auth status
```

If you need another agent on this host, use the HTTP API with a per-identity `ravi_id_` key (`Authorization: Bearer ravi_id_...`), or the Cursor Connect plugin (per-agent credentials).

---

## Step 4: Create an Identity (if needed)

If you have no identities, create one:

```bash
ravi identity create
```

The server auto-generates a realistic human name (e.g. "Sarah Johnson") and matching email.

---

## Sign up for a service

```bash
# 1. Get your identity details
EMAIL=$(ravi get email)
PHONE=$(ravi get phone)
NAME=$(ravi auth status | jq -r '.name')
FIRST_NAME=$(echo "$NAME" | awk '{print $1}')
LAST_NAME=$(echo "$NAME" | awk '{print $2}')

# 2. Fill the signup form with $EMAIL, $PHONE, $FIRST_NAME, $LAST_NAME

# 3. Generate and store a password during signup
CREDS=$(ravi passwords create example.com --username "$EMAIL")
PASSWORD=$(echo "$CREDS" | jq -r '.password')
# Use $PASSWORD in the signup form

# 4. Wait for verification
sleep 5
ravi inbox sms    # Check for an SMS verification code
ravi inbox email  # Check for email verification
```

## Your Name

When a form asks for your name, use your **identity name** — not the account owner's name. Identity names look like real human names (e.g. "Sarah Johnson").

```bash
ravi auth status
# → Returns identity name, email, phone
```

> **Note:** The first/last split works for auto-generated names (e.g. "Sarah Johnson"). For custom names (e.g. "Shopping Agent"), use the full name as-is or adapt the split to the form's requirements.

**Never** use the account owner's name for form fields. The identity name is *your* name.

## Log into a service

```bash
# Find stored credentials by domain
CREDS=$(ravi passwords list | jq -r '.[] | select(.domain == "example.com")')
UUID=$(echo "$CREDS" | jq -r '.uuid')

# Get full credentials including password
CREDS=$(ravi passwords get "$UUID")
USERNAME=$(echo "$CREDS" | jq -r '.username')
PASSWORD=$(echo "$CREDS" | jq -r '.password')
# Use $USERNAME and $PASSWORD to log in
```

## Complete a verification-code challenge

When a service texts or emails you a login/verification code, read it from your
identity's inbox and submit it. Ravi does not generate codes — it receives the
one the service sends.

```bash
# After the service says it sent a code to your number:
sleep 5
CODE=$(ravi inbox sms | jq -r '.[].preview' | grep -oE '[0-9]{4,8}' | head -1)
# Use $CODE to complete the login
```

## Extract a verification link from email

```bash
THREAD_ID=$(ravi inbox email | jq -r '.[0].thread_id')

ravi inbox email "$THREAD_ID" | jq -r '.messages[].text_content' | grep -oE 'https?://[^ ]+'
```

## Tips

- **Poll, don't rush** — SMS/email delivery takes 2-10 seconds. Use `sleep 5` before checking.
- **Store credentials immediately** — create a passwords entry during signup so you don't lose the password.
- **Identity name for forms** — always use the identity name, not the owner name.
- **Rate limits apply to sending** — per inbox, per day: 100/day (free) or 500/day (paid); no hourly cap. See `ravi-email-send` skill for details.
- **Email quality matters** — if you need to send an email during a workflow, see **ravi-email-writing** for formatting and anti-spam tips.

## Docs

CLI auth is `ravi auth login` / `logout` / `status`. Keys land in `~/.ravi/config.json` as `ravi_mgmt_` / `ravi_id_`. The CLI is one identity per machine — extra agents use the HTTP API with per-identity `ravi_id_` keys, or Cursor Connect. Docs: https://docs.ravi.app

## Related Skills

- **ravi-identity** — Get your email, phone, and identity name for form fields
- **ravi-inbox** — Read verification codes and confirmation emails
- **ravi-email-send** — Send emails during workflows (support requests, confirmations)
- **ravi-email-writing** — Write professional emails that avoid spam filters
- **ravi-passwords** — Store and retrieve website credentials after signup
- **ravi-secrets** — Store API keys obtained during service registration
- **ravi-sso** — Prove your Ravi identity to third-party services via short-lived tokens
- **ravi-feedback** — Report login flow issues or suggest workflow improvements
