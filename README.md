# Ravi — Agent Skills

Teaches AI agents how to use the Ravi CLI for identity, email, phone, and encrypted credentials.

## Prerequisites

Install the [Ravi CLI](https://github.com/ravi-hq/cli) first — these skills teach agents how to use it, but don't include the CLI itself.

```bash
brew install ravi-hq/tap/ravi
ravi auth login
```

## Install

### Any agent (skills.sh)

```bash
# All skills
npx skills add ravi-hq/ravi-skills

# Individual skill
npx skills add ravi-hq/ravi-skills --skill ravi-identity
```

### Claude Code

```
/plugin marketplace add ravi-hq/ravi-skills
/plugin install ravi
```

### OpenClaw (ClawdHub)

Skills are installed individually on ClawdHub:

```bash
# Install all Ravi skills
for s in ravi ravi-identity ravi-inbox ravi-email-send ravi-login ravi-passwords ravi-vault ravi-feedback; do
  clawdhub install "$s"
done
```

## Skills

| Skill | Description | Example |
|-------|-------------|---------|
| **ravi** | Overview — what Ravi is and when to use each skill | — |
| **ravi-identity** | Check auth status, get identity details, switch identities | `ravi auth status --json` |
| **ravi-inbox** | Read SMS and email — OTPs, verification links, incoming mail | `ravi inbox sms --unread --json` |
| **ravi-email-send** | Compose, reply, reply-all with HTML and attachments | `ravi email compose --to "u@x.com" --subject "Hi" --body "<p>Hello</p>" --json` |
| **ravi-login** | Signup/login workflows with 2FA and credential storage | `ravi passwords create example.com --json` |
| **ravi-passwords** | Website credentials (domain + username + password) | `ravi passwords get <uuid> --json` |
| **ravi-vault** | Key-value secrets (API keys, env vars) | `ravi vault set OPENAI_API_KEY "sk-..." --json` |
| **ravi-feedback** | Send feedback, bugs, or feature requests to the Ravi team | `ravi feedback "Great product!" --json` |

## What is Ravi?

Ravi is an identity provider for AI agents. One CLI gives your agent:

- **Email inbox** — a real email address that receives mail
- **Phone number** — a real phone number that receives SMS
- **Password manager** — E2E-encrypted website credentials
- **Secret vault** — E2E-encrypted key-value secrets (API keys, env vars)
- **Multiple identities** — separate personas for different projects

## License

MIT
