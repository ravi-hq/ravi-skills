---
name: ravi-email-send
description: Send, compose, reply, or reply-all to emails with HTML formatting and attachments. Do NOT use for reading incoming email (use ravi-inbox) or for credentials (use ravi-passwords or ravi-vault).
---

# Ravi Email — Send

Compose new emails or reply to existing ones from your Ravi email address, with optional file attachments.

## Compose a new email

```bash
ravi email compose --to "recipient@example.com" --subject "Subject" --body "<p>HTML content</p>" --json
```

**Flags:**
- `--to` (required): Recipient email address
- `--subject` (required): Email subject line
- `--body` (required): Email body (HTML supported — use tags like `<p>`, `<h2>`, `<ul>` for formatting)
- `--cc`: CC recipients (comma-separated)
- `--bcc`: BCC recipients (comma-separated)
- `--attach`: File path to attach (can be repeated for multiple files)

**Example with HTML formatting and attachment:**
```bash
ravi email compose --to "user@example.com" --subject "Monthly Report" \
  --body "<h2>Monthly Report</h2><p>Key findings:</p><ul><li>Revenue up 15%</li><li>Churn down 3%</li></ul>" \
  --attach report.pdf --json
```

## Reply to an email

```bash
# Reply to sender only
ravi email reply <message_id> --subject "Re: Original Subject" --body "<p>Reply content</p>" --json

# Reply to all recipients
ravi email reply-all <message_id> --subject "Re: Original Subject" --body "<p>Reply content</p>" --json
```

**Flags:** `--subject` (required), `--body` (required), `--attach` (optional)

**Note:** The subject must be provided because the original is E2E encrypted on the server.

## Attachments

Attachments are uploaded automatically when you use `--attach`. The CLI:
1. Validates the file (blocked extensions like `.exe` rejected instantly)
2. Requests a presigned upload URL from the server
3. Uploads the file directly to cloud storage
4. Includes the attachment UUID in the email

**Blocked extensions:** `.exe`, `.dll`, `.bat`, `.cmd`, `.msi`, `.iso`, `.dmg`, `.apk`, and other dangerous file types. Developer files (`.py`, `.sh`, `.js`, `.rb`) are allowed.

**Max size:** 10 MB per attachment.

## Rate Limits

Email sending is rate-limited per user account:
- **60 emails/hour** and **500 emails/day**
- **200 attachment uploads/hour**

On hitting a rate limit, you'll get a 429 error with a `retry_after_seconds` value. Wait that many seconds before retrying.

**Best practices for agents:**
- Avoid tight loops of email sends — batch work where possible
- On 429: parse `retry_after_seconds` from the error, wait, then retry
- For bulk operations, add a 1-2 second delay between sends

## Important Notes

- **HTML email bodies** — The `--body` flag accepts HTML. Use tags for formatting: `<p>`, `<h2>`, `<ul>`, `<a href="...">`. No `<html>` or `<body>` wrapper needed.
- **Always use `--json`** — human-readable output is not designed for parsing.
