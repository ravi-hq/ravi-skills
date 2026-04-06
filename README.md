# Ravi — Agent Skills

Teaches AI agents how to use Ravi for identity, email, phone, and encrypted credentials via curl and API keys.

## Prerequisites

Get your API keys by completing the device code onboarding flow (see the `ravi-login` skill for details). You'll need:

- `RAVI_MGMT_KEY` — management API key (`ravi_mgmt_...`) for account operations
- `RAVI_ID_KEY` — identity API key (`ravi_id_...`) for resource operations

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
for s in ravi ravi-identity ravi-inbox ravi-email-send ravi-email-writing ravi-login ravi-passwords ravi-secrets ravi-contacts ravi-feedback; do
  clawdhub install "$s"
done
```

## Skills

| Skill | Description | Example |
|-------|-------------|---------|
| **ravi** | Overview — what Ravi is and when to use each skill | — |
| **ravi-identity** | Get identity details, create identities, list domains | `curl -H "Authorization: Bearer $RAVI_MGMT_KEY" https://ravi.id/api/identities/` |
| **ravi-inbox** | Read SMS and email — OTPs, verification links, incoming mail | `curl -H "Authorization: Bearer $RAVI_ID_KEY" https://ravi.id/api/email-inbox/` |
| **ravi-email-send** | Compose, reply, forward with HTML and attachments | `curl -X POST ... https://ravi.id/api/email-messages/compose/` |
| **ravi-email-writing** | Email content quality — subject lines, HTML formatting, anti-spam | — |
| **ravi-login** | Device code onboarding, signup/login workflows, 2FA, credential storage | `curl -X POST https://ravi.id/api/auth/device/` |
| **ravi-passwords** | Website credentials (domain + username + password) | `curl -H "Authorization: Bearer $RAVI_ID_KEY" https://ravi.id/api/passwords/` |
| **ravi-secrets** | Key-value secrets (API keys, env vars) | `curl -H "Authorization: Bearer $RAVI_ID_KEY" https://ravi.id/api/secrets/` |
| **ravi-contacts** | Search and manage contacts | `curl -H "Authorization: Bearer $RAVI_ID_KEY" https://ravi.id/api/contacts/` |
| **ravi-feedback** | Send feedback, bugs, or feature requests to the Ravi team | `curl -X POST ... https://ravi.id/api/feedback/` |

## What is Ravi?

Ravi is an identity provider for AI agents. One API gives your agent:

- **Email inbox** — a real email address that receives mail
- **Phone number** — a real phone number that receives SMS
- **Password manager** — encrypted website credentials
- **Secret store** — encrypted key-value secrets (API keys, env vars)
- **Multiple identities** — separate personas for different projects

## License

MIT
