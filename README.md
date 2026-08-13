# Ravi

Ravi gives AI agents their own identity (email inbox, real phone, encrypted vault) so they can sign up for services, receive verification codes, and keep the passwords they create. For teams whose agents have to act on the web, not just talk. Connect Ravi like any other Cursor plugin.

Docs: https://docs.ravi.app

The CLI is for terminals and CI — not the Cursor front door.

## Cursor (plugin)

Install the **Ravi** plugin from the Cursor marketplace, or add this repo as a plugin marketplace (`.cursor-plugin/marketplace.json`). Connect Ravi like any other Cursor plugin.

**Skills are the live surface** — identity, inbox, vault, send email, send SMS. A Connect card is shipping with this plugin; it is **not live yet**. Do not treat remote MCP or the Connect card as the live auth path.

The CLI is for terminals and CI, not this front door. Do **not** run `ravi auth login` or write `~/.ravi/config.json` as the Cursor listing path.

## Other agents (skills + CLI — terminals / CI)

Claude Code, skills.sh, OpenClaw, CI, and other runtimes that are **not** on Cursor MCP still use skills plus the Ravi CLI. The CLI is **one identity per machine** — a fallback for a single agent or CI job, not a shared config for agents running side by side.

### Any agent (skills.sh)

```bash
# All skills
npx skills add ravi-hq/ravi-skills

# Individual skill
npx skills add ravi-hq/ravi-skills --skill ravi-identity

# Required on this path: install the Ravi CLI (skills do not include the binary)
curl -fsSL https://raw.githubusercontent.com/ravi-hq/ravi-skills/main/scripts/install-cli.sh | bash
export PATH="$HOME/.ravi/bin:$PATH"

# Authenticate once (human approves at https://ravi.id/device)
ravi auth login
```

If the skill directory is already on disk, run `bash scripts/install-cli.sh` from this repo (or `skills/ravi/scripts/install-cli.sh` after a skills.sh install) instead of curl.

The CLI stores `ravi_mgmt_` / `ravi_id_` keys in `~/.ravi/config.json` and reads them automatically — no manual API key management needed. Do **not** flip that file to multiplex agents. Extra agents on the same host use the HTTP API with per-identity `ravi_id_` keys.

### Claude Code

```
/plugin marketplace add ravi-hq/ravi-skills
/plugin install ravi
```

The plugin puts a `ravi` wrapper on PATH (`bin/ravi`) and installs the real CLI on first use (or at session start). Then run:

```bash
ravi auth login
```

### OpenClaw (ClawdHub)

Skills are installed individually on ClawdHub:

```bash
# Install all Ravi skills
for s in ravi ravi-identity ravi-inbox ravi-email-send ravi-email-writing ravi-login ravi-passwords ravi-secrets ravi-sso ravi-contacts ravi-feedback; do
  clawdhub install "$s"
done

# Required: install the Ravi CLI
curl -fsSL https://raw.githubusercontent.com/ravi-hq/ravi-skills/main/scripts/install-cli.sh | bash
export PATH="$HOME/.ravi/bin:$PATH"
ravi auth login
```

## Skills

Skills teach CLI workflows for terminals and CI. The CLI is not the Cursor plugin listing path.

| Skill | Description | Example |
|-------|-------------|---------|
| **ravi** | Overview — Cursor plugin listing; CLI for terminals/CI | — |
| **ravi-identity** | Get identity details, create identities, list domains | `ravi identity list` |
| **ravi-inbox** | Read SMS and email — verification codes, links, incoming mail | `ravi inbox email` |
| **ravi-email-send** | Compose, reply, forward with HTML and attachments | `ravi email compose --to "..." --subject "..." --body "..."` |
| **ravi-email-writing** | Email content quality — subject lines, HTML formatting, anti-spam | — |
| **ravi-login** | Device code onboarding (CLI), signup/login workflows, verification codes, credential storage | `ravi auth login` |
| **ravi-passwords** | Website credentials (domain + username + password) | `ravi passwords list` |
| **ravi-secrets** | Key-value secrets (API keys, env vars) | `ravi secrets list` |
| **ravi-sso** | Prove identity to third-party services via short-lived tokens | `ravi sso token` |
| **ravi-contacts** | Search and manage contacts | `ravi contacts search "alice"` |
| **ravi-feedback** | Send feedback, bugs, or feature requests to the Ravi team | — |

## What is Ravi?

Ravi is an identity provider for AI agents. One API gives your agent:

- **Email inbox** — a real email address that receives mail
- **Phone number** — a real phone number that receives SMS
- **Password manager** — encrypted website credentials
- **Secret store** — encrypted key-value secrets (API keys, env vars)
- **Multiple identities** — separate personas for different projects

## License

MIT
