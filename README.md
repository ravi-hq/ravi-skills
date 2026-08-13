# Ravi — identity for AI agents

Ravi gives AI agents their own identity (email inbox, real phone, encrypted vault) so they can sign up for services, receive verification codes, and keep the passwords they create. For teams whose agents have to act on the web, not just talk.

Docs: https://docs.ravi.app

## Cursor (plugin)

Install the **Ravi** plugin from the Cursor marketplace (not live as a public listing yet), or add this repo as a plugin marketplace (`.cursor-plugin/marketplace.json`). **Skills are the live surface.**

A Connect card is shipping; it is **not live yet**. Do not tap Connect as if it authenticates. Do not treat `https://api.ravi.app/mcp` as a working connector (`mcp.json` is shipping / not live).

Working auth today is the CLI (one identity per machine):

```bash
if ! command -v ravi >/dev/null 2>&1; then
  bash scripts/install-cli.sh
  export PATH="$HOME/.ravi/bin:$PATH"
fi
ravi auth login
```

The human approves at **https://ravi.id/device**.

## Other agents (skills + CLI — terminals / CI)

The CLI is the working auth path today for terminals, CI, Claude Code, skills.sh, OpenClaw, and Cursor (Connect is not live). The CLI is **one identity per machine** — not a shared config for agents running side by side.

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

Skills teach CLI workflows. Working auth is the CLI (terminals, CI, and Cursor until Connect is live).

| Skill | Description | Example |
|-------|-------------|---------|
| **ravi** | Overview — skills on Cursor; CLI for working auth | — |
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
