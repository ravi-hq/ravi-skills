---
name: ravi-inbox
description: Read incoming SMS or email messages — OTPs, verification codes, verification links, incoming mail. Do NOT use for sending email (use ravi-email-send) or managing credentials (use ravi-passwords or ravi-secrets).
---

# Ravi Inbox

Read SMS and email messages received at your Ravi identity. Use this after triggering verifications, 2FA, or when expecting incoming messages.

## Prerequisites

Load your API keys before making requests:

```bash
# Read identity key (for most operations)
RAVI_ID_KEY=$(cat .ravi/config.json 2>/dev/null | jq -r '.identity_key // empty')
[ -z "$RAVI_ID_KEY" ] && RAVI_ID_KEY=$(cat ~/.ravi/auth.json 2>/dev/null | jq -r '.identity_key // empty')
[ -z "$RAVI_ID_KEY" ] && echo "No identity key found. Run the ravi-login skill to onboard."
```

If keys are missing, use the **ravi-login** skill to onboard.

All inbox endpoints use the identity key:
```bash
-H "Authorization: Bearer $RAVI_ID_KEY"
```

## SMS (OTPs, verification codes)

```bash
# List SMS conversations (grouped by sender)
curl -s -H "Authorization: Bearer $RAVI_ID_KEY" \
  https://ravi.id/api/sms-inbox/ | jq

# Only conversations with unread messages
curl -s -H "Authorization: Bearer $RAVI_ID_KEY" \
  "https://ravi.id/api/sms-inbox/?unread=true" | jq

# View a specific conversation (all messages)
# conversation_id format: {phone_id}_{from_number}, e.g. "1_+15559876543"
curl -s -H "Authorization: Bearer $RAVI_ID_KEY" \
  "https://ravi.id/api/sms-inbox/1_+15559876543/" | jq
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
curl -s -H "Authorization: Bearer $RAVI_ID_KEY" \
  https://ravi.id/api/email-inbox/ | jq

# Only threads with unread messages
curl -s -H "Authorization: Bearer $RAVI_ID_KEY" \
  "https://ravi.id/api/email-inbox/?unread=true" | jq

# View a specific thread (all messages with full content)
curl -s -H "Authorization: Bearer $RAVI_ID_KEY" \
  https://ravi.id/api/email-inbox/<thread_id>/ | jq
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

## Individual Messages (flat, not grouped)

Use these when you need messages by ID rather than by conversation:

```bash
# All SMS messages
curl -s -H "Authorization: Bearer $RAVI_ID_KEY" \
  https://ravi.id/api/messages/sms/ | jq

# Unread SMS only
curl -s -H "Authorization: Bearer $RAVI_ID_KEY" \
  "https://ravi.id/api/messages/sms/?unread=true" | jq

# Specific SMS message
curl -s -H "Authorization: Bearer $RAVI_ID_KEY" \
  https://ravi.id/api/messages/sms/<message_id>/ | jq

# All email messages
curl -s -H "Authorization: Bearer $RAVI_ID_KEY" \
  https://ravi.id/api/messages/email/ | jq

# Unread email only
curl -s -H "Authorization: Bearer $RAVI_ID_KEY" \
  "https://ravi.id/api/messages/email/?unread=true" | jq

# Specific email message
curl -s -H "Authorization: Bearer $RAVI_ID_KEY" \
  https://ravi.id/api/messages/email/<message_id>/ | jq
```

## Quick Recipes

### Extract an OTP code from SMS

```bash
curl -s -H "Authorization: Bearer $RAVI_ID_KEY" \
  "https://ravi.id/api/sms-inbox/?unread=true" | \
  jq -r '.[].preview' | grep -oE '[0-9]{4,8}'
```

### Extract a verification link from email

```bash
THREAD_ID=$(curl -s -H "Authorization: Bearer $RAVI_ID_KEY" \
  "https://ravi.id/api/email-inbox/?unread=true" | jq -r '.[0].thread_id')

curl -s -H "Authorization: Bearer $RAVI_ID_KEY" \
  "https://ravi.id/api/email-inbox/$THREAD_ID/" | \
  jq -r '.messages[].text_content' | grep -oE 'https?://[^ ]+'
```

## Important Notes

- **Poll, don't rush** — SMS/email delivery takes 2-10 seconds. Use `sleep 5` before checking.
- **Auto-contacts** — Ravi automatically creates or updates contacts when you send or receive email/SMS. Use the contacts search endpoint to look up people you've interacted with.

## Related Skills

- **ravi-email-send** — Reply or forward emails you've read
- **ravi-email-writing** — Write professional replies with proper formatting and tone
- **ravi-contacts** — Look up a sender's name or details from their email/phone
- **ravi-login** — End-to-end signup/login workflows that use inbox for OTP extraction
- **ravi-feedback** — Report inbox delivery issues or suggest improvements
