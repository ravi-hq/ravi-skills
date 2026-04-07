---
name: ravi-email-send
description: Send, compose, reply, reply-all, or forward emails with HTML formatting and attachments. Do NOT use for reading incoming email (use ravi-inbox) or for credentials (use ravi-passwords or ravi-secrets).
---

# Ravi Email — Send

Compose new emails, reply to existing ones, or forward them from your Ravi email address, with optional file attachments.

> **Writing quality matters.** Before drafting email content, see the **ravi-email-writing** skill for subject lines, HTML formatting, tone, and anti-spam best practices.

## Prerequisites

Load your API keys before making requests:

```bash
# Read identity key (for most operations)
RAVI_ID_KEY=$(cat .ravi/config.json 2>/dev/null | jq -r '.identity_key // empty')
[ -z "$RAVI_ID_KEY" ] && RAVI_ID_KEY=$(cat ~/.ravi/config.json 2>/dev/null | jq -r '.identity_key // empty')
[ -z "$RAVI_ID_KEY" ] && echo "No identity key found. Run the ravi-login skill to onboard."
```

If keys are missing, use the **ravi-login** skill to onboard.

All email send endpoints use the identity key:
```bash
-H "Authorization: Bearer $RAVI_ID_KEY"
```

## Resolving Recipients by Name

If you have the recipient's name but not their email address (e.g. "email Alice"), **use ravi-contacts first**:

```bash
# Search contacts by name
curl -s -H "Authorization: Bearer $RAVI_ID_KEY" \
  "https://ravi.id/api/contacts/search/?q=Alice" | jq
# → Returns matches with email, phone, display_name
# If one match → use the email from the result
# If multiple matches → confirm with the user which Alice they mean
# If no matches → ask the user for the email address directly
```

## Compose a new email

The compose endpoint requires an `?inbox=ID` query parameter. Get the inbox ID from `GET /api/identities/` — it's returned in the response as `inbox`. Use the identity's inbox ID.

```bash
# Get your inbox ID first
INBOX_ID=$(curl -s -H "Authorization: Bearer $RAVI_MGMT_KEY" \
  https://ravi.id/api/identities/ | jq -r '.[0].inbox')

curl -s -X POST -H "Authorization: Bearer $RAVI_ID_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "to_email": "recipient@example.com",
    "subject": "Subject",
    "content": "<p>HTML content</p>"
  }' \
  "https://ravi.id/api/email-messages/compose/?inbox=$INBOX_ID" | jq
```

**Body fields:**
- `to_email` (required): Recipient email address
- `subject` (required): Email subject line
- `content` (required): Email body (HTML supported — use tags like `<p>`, `<h2>`, `<ul>` for formatting)
- `cc`: CC recipients (array of email strings)
- `bcc`: BCC recipients (array of email strings)

**Example with HTML formatting:**
```bash
curl -s -X POST -H "Authorization: Bearer $RAVI_ID_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "to_email": "user@example.com",
    "subject": "Monthly Report",
    "content": "<h2>Monthly Report</h2><p>Key findings:</p><ul><li>Revenue up 15%</li><li>Churn down 3%</li></ul>"
  }' \
  "https://ravi.id/api/email-messages/compose/?inbox=$INBOX_ID" | jq
```

## Reply to an email

```bash
# Reply to sender only
curl -s -X POST -H "Authorization: Bearer $RAVI_ID_KEY" \
  -H "Content-Type: application/json" \
  -d '{"content": "<p>Reply content</p>"}' \
  https://ravi.id/api/email-messages/<id>/reply/ | jq

# Reply to all recipients (reply-all)
curl -s -X POST -H "Authorization: Bearer $RAVI_ID_KEY" \
  -H "Content-Type: application/json" \
  -d '{"content": "<p>Reply content</p>"}' \
  https://ravi.id/api/email-messages/<id>/reply-all/ | jq
```

**Optional body fields:**
- `cc`: CC recipients (array of email strings)
- `bcc`: BCC recipients (array of email strings)

**Example with CC:**
```bash
curl -s -X POST -H "Authorization: Bearer $RAVI_ID_KEY" \
  -H "Content-Type: application/json" \
  -d '{"content": "<p>Adding the team.</p>", "cc": ["team@example.com"]}' \
  https://ravi.id/api/email-messages/<id>/reply/ | jq
```

## Forward an email

```bash
curl -s -X POST -H "Authorization: Bearer $RAVI_ID_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "to_email": "recipient@example.com",
    "content": "<p>FYI — see below.</p>"
  }' \
  https://ravi.id/api/email-messages/<id>/forward/ | jq
```

**Body fields:**
- `to_email` (required): Recipient email address
- `content` (required): Email body (HTML supported)
- `cc`: CC recipients (array of email strings)
- `bcc`: BCC recipients (array of email strings)

## Rate Limits

Email sending is rate-limited per user account:
- **60 emails/hour** and **500 emails/day**

On hitting a rate limit, you'll get a 429 response with a `retry_after_seconds` value. Wait that many seconds before retrying.

**Best practices for agents:**
- Avoid tight loops of email sends — batch work where possible
- On 429: parse `retry_after_seconds` from the response body, wait, then retry
- For bulk operations, add a 1-2 second delay between sends

## Important Notes

- **HTML email bodies** — the `content` field accepts HTML. Use tags for formatting: `<p>`, `<h2>`, `<ul>`, `<a href="...">`. No `<html>` or `<body>` wrapper needed. See **ravi-email-writing** for templates and anti-spam rules.
- **Subject for replies/forwards** — reply and forward endpoints auto-derive the subject from the original message (prepending `Re:` or `Fwd:`). No need to pass `subject`.


## Full API Reference

For complete endpoint details, request/response schemas, and parameters: [Messages](https://ravi.id/docs/schema/messages.json) | [Attachments](https://ravi.id/docs/schema/attachments.json)

## Related Skills

- **ravi-contacts** — Look up a person's email address by name before sending
- **ravi-email-writing** — Subject lines, HTML templates, tone, and anti-spam best practices
- **ravi-inbox** — Read incoming email before replying or forwarding
- **ravi-identity** — Get your email address and identity name for signatures
- **ravi-feedback** — Report deliverability issues or suggest email feature improvements
