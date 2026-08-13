---
name: ravi-inbox
description: Read incoming SMS or email messages — verification codes, verification links, incoming mail. Do NOT use for sending email (use ravi-email-send) or managing credentials (use ravi-passwords or ravi-secrets).
---

# Ravi Inbox

Read SMS and email messages received at your Ravi identity. Use this after triggering a verification, or when expecting incoming messages — including the login/verification codes a service sends you.

> **Cursor:** If Ravi MCP tools are connected, use them (identity, inbox, vault, send email, send SMS). Auth is the plugin **Connect** card — per-agent credentials, same as GitHub/Linear. Do **not** run `ravi auth login` or write `~/.ravi/config.json`. **CLI fallback** (one identity per machine — single agent / CI): if `ravi` is missing, `curl -fsSL https://raw.githubusercontent.com/ravi-hq/ravi-skills/main/scripts/install-cli.sh | bash` then `export PATH="$HOME/.ravi/bin:$PATH"`. Then `ravi auth login` (human visits https://ravi.id/device).

## SMS (verification codes)

```bash
# List SMS conversations (grouped by sender)
ravi inbox sms

# View a specific conversation (all messages)
# conversation_id format: {phone_id}_{from_number}, e.g. "1_+15559876543"
ravi inbox sms "1_+15559876543"
```

**JSON shape — conversation list:**

```json
[{
  "conversation_id": "1_+15559876543",
  "from_number": "+15559876543",
  "phone_number": "+15551234567",
  "preview": "Your code is 847291",
  "message_count": 3,
  "unread_count": 1,
  "latest_message_dt": "2026-02-25T10:30:00Z"
}]
```

**JSON shape — conversation detail:**

```json
{
  "conversation_id": "1_+15559876543",
  "from_number": "+15559876543",
  "messages": [
    {"id": 42, "body": "Your code is 847291", "direction": "incoming", "is_read": false, "created_dt": "..."}
  ]
}
```

## Email (verification links, confirmations)

```bash
# List email threads
ravi inbox email

# View a specific thread (all messages with full content)
ravi inbox email <thread_id>
```

**JSON shape — thread detail:**

```json
{
  "thread_id": "abc123",
  "subject": "Verify your email",
  "messages": [
    {
      "id": 10,
      "from_email": "noreply@example.com",
      "to_email": "janedoe@example.com",
      "subject": "Verify your email",
      "text_content": "Click here to verify: https://example.com/verify?token=xyz",
      "direction": "incoming",
      "is_read": false,
      "created_dt": "..."
    }
  ]
}
```

## Quick Recipes

### Extract a verification code from SMS

```bash
ravi inbox sms | jq -r '.[].preview' | grep -oE '[0-9]{4,8}'
```

### Extract a verification link from email

```bash
THREAD_ID=$(ravi inbox email | jq -r '.[0].thread_id')

ravi inbox email "$THREAD_ID" | jq -r '.messages[].text_content' | grep -oE 'https?://[^ ]+'
```

## Important Notes

- **Poll, don't rush** — SMS/email delivery takes 2-10 seconds. Use `sleep 5` before checking.
- **Auto-contacts** — Ravi automatically creates or updates contacts when you send or receive email/SMS. Use `ravi contacts search` to look up people you've interacted with.

## Docs

[Docs](https://docs.ravi.app)

## Related Skills

- **ravi-email-send** — Reply or forward emails you've read
- **ravi-email-writing** — Write professional replies with proper formatting and tone
- **ravi-contacts** — Look up a sender's name or details from their email/phone
- **ravi-login** — End-to-end signup/login workflows that read verification codes from the inbox
- **ravi-feedback** — Report inbox delivery issues or suggest improvements
