# Ravi — Agent Skills

[Agent Skills](https://skills.sh/) for the [Ravi CLI](https://github.com/ravi-hq/cli). Teaches AI agents how to use `ravi` to manage identities, receive SMS/email, send emails, and store credentials.

## Prerequisites

Install the [Ravi CLI](https://github.com/ravi-hq/cli) first — these skills teach agents how to use it, but don't include the CLI itself.

```bash
brew install ravi-hq/tap/ravi
ravi auth login
```

## Install

```bash
# All skills
npx skills add ravi-hq/ravi-skills

# Individual skill
npx skills add ravi-hq/ravi-skills --skill ravi-identity
```

## Skills

| Skill | Description |
|-------|-------------|
| **ravi** | Overview — what Ravi is and when to use each skill |
| **ravi-identity** | Check auth status, get identity details, switch identities |
| **ravi-inbox** | Read SMS and email messages — OTPs, verification links, incoming mail |
| **ravi-email-send** | Compose, reply, reply-all with HTML formatting and attachments |
| **ravi-signup** | End-to-end signup/login workflows with 2FA and credential storage |
| **ravi-vault** | Store and retrieve E2E-encrypted credentials |

## What is Ravi?

Ravi is an identity provider for AI agents. One CLI gives your agent:

- **Email inbox** — a real email address that receives mail
- **Phone number** — a real phone number that receives SMS
- **Credential vault** — E2E-encrypted password storage
- **Multiple identities** — separate personas for different projects

## License

MIT
