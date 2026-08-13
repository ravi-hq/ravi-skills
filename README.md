# Ravi — identity, email, and phone for AI agents

Ravi gives agents a real email inbox, phone number, and encrypted credentials.

**On Cursor, install the plugin and tap Connect.** That is auth (same as GitHub or Linear). The agent gets identity, inbox, and vault tools with schemas. No CLI.

## Cursor (plugin + Connect)

1. Install the **Ravi** plugin from the Cursor marketplace, or add this repo as a plugin marketplace (`.cursor-plugin/marketplace.json`).
2. Tap **Connect** when Cursor shows the Ravi card. That binds a fenced `ravi_id_` key to this agent.
3. Use the connected MCP tools — identity, inbox, vault, send email, send SMS.

Do **not** run `ravi auth login`. Do **not** write `~/.ravi/config.json`. Do **not** install a `ravi` binary on this path.

The plugin points at a remote MCP server:

```text
https://api.ravi.app/mcp
```

That is a remote HTTP/SSE MCP URL. It is not `npx`, not stdio, and not the `ravi` CLI. Auth is the Connect card, not a device-code flow.

## Other agents (skills + CLI fallback)

Claude Code, skills.sh, OpenClaw, CI, and other runtimes that are **not** on Cursor MCP still use skills plus the Ravi CLI.

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

The CLI stores `ravi_mgmt_` / `ravi_id_` keys in `~/.ravi/config.json` and reads them automatically — no manual API key management needed.

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

Skills teach CLI fallback workflows. On Cursor, prefer the connected MCP tools instead — do not follow CLI login steps while MCP is connected.

| Skill | Description | Example |
|-------|-------------|---------|
| **ravi** | Overview — Connect on Cursor; CLI fallback elsewhere | — |
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
