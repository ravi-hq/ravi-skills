---
name: ravix-reply
description: Reply to the email you were just dispatched to handle. Use this skill whenever you are running under the ravix daemon (you'll see email headers `From:`, `To:`, `Subject:`, `Message-ID:` in your initial input) and the user has asked you to respond to that email. Do NOT use for composing new outbound emails — this is reply-only.
---

# ravix — Reply

You are running inside the `ravix` daemon. The daemon matched an incoming email and invoked you with the email contents as stdin. Your job is to do what the email asks, then send a reply to the sender summarizing what you did.

## Input shape

The prompt you receive starts with instructions followed by the email, formatted like this:

```
Read this email, do what it asks, and then reply to the sender with details.

From: sender@example.com
To: agent@ravi.id
Subject: Please pull the latest revenue numbers
Date: Mon, 20 Apr 2026 03:45:03 -0400
Message-ID: <CABx+y@mail.example.com>

<email body here>
```

**Capture the `Message-ID` verbatim (including angle brackets and anything in between) — you need it to send the reply.**

## Send a reply

Use the `ravix email reply` command. HTML body, sender-only reply, subject auto-derived from the original:

```bash
ravix email reply '<CABx+y@mail.example.com>' --body '<p>Done — here are the revenue numbers you asked for:</p><ul><li>Q1: $1.2M</li><li>Q2: $1.5M</li></ul>'
```

**Flag reference:**
- `<message_id>` (positional, required): the exact `Message-ID` header value from the email you received, including `<` and `>`. Quote it so the shell doesn't interpret the angle brackets.
- `--body` (required): HTML email body. Use `<p>`, `<h2>`, `<ul>`, `<li>`, `<a href="...">` for formatting. No `<html>` or `<body>` wrapper.
- `--cc` (optional, repeatable): add CC recipients.
- `--bcc` (optional, repeatable): add BCC recipients.

## Workflow

1. Read the email from stdin. Pay attention to `Message-ID` (you'll need it) and the body (tells you what to do).
2. Do the work requested — run commands, fetch data, create files in the workspace, whatever it asks.
3. Send exactly one reply with `ravix email reply` summarizing what you did and including any results the sender needs.

## Writing a good reply

- **Be concrete.** Include actual results, not just "I did it." If the ask was "pull revenue numbers," paste the numbers.
- **HTML formatting.** Use `<p>` for paragraphs, `<ul>/<li>` for lists, `<h2>` for section headers, `<pre>` for code/output blocks. No raw Markdown — it won't render.
- **Keep it short.** A few sentences plus the data. The sender wanted an answer, not a dissertation.
- **Acknowledge failures.** If you couldn't do what was asked, say so clearly and explain why — don't pretend it worked.

## Example: full workflow

Email received:
```
From: jake@ravi.id
To: leonard.elmquist8599@raviapp.com
Subject: current time?
Message-ID: <CAJPXh3e_mFs@mail.example.com>

What time is it?
```

Steps:
1. Run `date` to get the current time
2. Reply with the output:

```bash
ravix email reply '<CAJPXh3e_mFs@mail.example.com>' --body '<p>It is currently Mon Apr 20 05:45:00 UTC 2026.</p>'
```

## When NOT to use this skill

- You are not running under ravix (no email headers in your initial input) → use other tools instead.
- The user asks you to compose a new email to someone not in the incoming thread → this skill is reply-only; use a different tool.
- The user asks you to reply to a different email than the one dispatched → stick to the thread you were invoked for.

## Verifying you have `ravix` available

```bash
ravix --version
```

If this fails, the ravix binary isn't on your PATH in this Claude session. Report that back in your reply (the daemon's log will also surface the issue).
