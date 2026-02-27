---
name: ravi
description: Overview of Ravi and when to use each skill. Ravi gives AI agents real email inboxes, phone numbers, and an encrypted credential vault via a CLI. Do NOT use for tasks unrelated to agent identity, email, phone, or credentials.
---

# Ravi — Identity Provider for AI Agents

Ravi gives you (the agent) your own email address, phone number, and encrypted credential vault via the `ravi` CLI. One identity bundles all three into a coherent persona.

## When to Use Each Skill

| I need to... | Use skill |
|--------------|-----------|
| Check if I'm authenticated or get my email/phone | **ravi-identity** |
| Read incoming SMS or email (OTPs, verification links) | **ravi-inbox** |
| Send an email, reply, or forward | **ravi-email-send** |
| Sign up for a service, log in, or complete 2FA | **ravi-login** |
| Store, retrieve, or generate website passwords | **ravi-passwords** |
| Store or retrieve API keys and secrets | **ravi-vault** |
| Send feedback, report bugs, or request features | **ravi-feedback** |

## Quick Start

```bash
# Check auth
ravi auth status --json

# Get your email and phone
ravi get email --json
ravi get phone --json

# Read incoming messages
ravi inbox sms --unread --json
ravi inbox email --unread --json

# Send an email
ravi email compose --to "user@example.com" --subject "Hello" --body "<p>Hi there</p>" --json

# Store a website password
ravi passwords create example.com --json

# Store an API key
ravi vault set OPENAI_API_KEY "sk-..." --json
```

## Key Rules

- **Always use `--json`** — all commands support it. Human-readable output is not for parsing.
- **Auth is automatic** — token refresh is transparent. On auth errors, ask the user to run `ravi auth login`.
- **E2E encryption is transparent** — the CLI handles encrypt/decrypt. You see plaintext.
- **Install:** `brew install ravi-hq/tap/ravi`
