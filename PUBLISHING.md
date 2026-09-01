# Publishing

This repo distributes skills to skills.sh, Claude Code, the Cursor Marketplace, and ClawdHub. Two skill channels are automatic, ClawdHub requires a version bump, and the public Cursor Marketplace listing is a manual submit.

## Distribution Channels

### 1. skills.sh (automatic)

Users install via `npx skills add ravi-hq/ravi-skills`. No publishing step — skills.sh reads directly from the GitHub repo's `skills/` directory.

### 2. Claude Code Plugin (automatic)

Users install via `/plugin marketplace add ravi-hq/ravi-skills`. No publishing step — Claude Code reads `.claude-plugin/plugin.json` and `skills/` directly from the repo.

### 3. Cursor Marketplace (manual review)

This repo is fetchable as an **Agent Plugin** (`plugin.json` at repo root, agent-plugins.org schema, skills only — no `mcpServers`) and as a **Cursor Plugin** (`.cursor-plugin/plugin.json`). The public listing is a **skills plugin** (not live on cursor.com/marketplace/ravi yet). Skills are the live surface. First hop remains `npx skills add ravi-hq/ravi-skills`. A Connect card is shipping; it is not live. Do not instruct agents to tap Connect as if it authenticates. Working auth is `scripts/install-cli.sh` + `ravi auth login` (human at https://ravi.id/device). The MCP product lives at `shipping/mcp.json` (not at the plugin root, so a crawler does not auto-discover a 404). First-class MCP does not go in the listing until the endpoint answers.

The listing is already filed. Submit URL for humans: [cursor.com/marketplace/publish](https://cursor.com/marketplace/publish). This file does not publish or re-submit the listing.

skills.sh and Claude Code stay as they are (channels 1 and 2). They do not go through Cursor Marketplace review.

### 4. ClawdHub / OpenClaw (requires version bump)

Users install via `clawdhub install <slug>`. Publishing happens automatically on push to `main` via GitHub Actions (`.github/workflows/publish.yml`).

**Setup (one-time):**

1. Create a ClawdHub account at [clawhub.ai](https://clawhub.ai)
2. Generate an API token
3. Add the token as a GitHub Actions secret: `CLAWDHUB_TOKEN`

**To publish a new version:**

1. Bump the patch version in `.claude-plugin/plugin.json`
2. Push to `main`
3. The workflow publishes all skills at the new version

**Manual publishing:**

```bash
npm i -g clawdhub
clawdhub login
VERSION=$(jq -r .version .claude-plugin/plugin.json)
for dir in skills/*/; do
  slug=$(basename "$dir")
  clawdhub publish "$dir" --slug "$slug" --name "Ravi ${slug#ravi-}" --version "$VERSION"
  sleep 2
done
```

**Rate limits:** ClawdHub allows 5 new skill publishes per hour. If you have more than 5 skills, the workflow spaces them out with `sleep 2` between publishes.

## Version Strategy

- `.claude-plugin/plugin.json` is the single source of truth for version
- Bump version before pushing changes that should be published to ClawdHub
- skills.sh and Claude Code always serve the latest commit (no versioning needed)

## Repository Layout: When to Add a Skill vs a New Plugin

This repo ships **two Claude Code plugins** from one marketplace:

```
plugin.json                   # Agent Plugins manifest (skills only; no mcpServers)
.claude-plugin/
├── marketplace.json          # lists both Claude Code plugins (ravi + ravix)
└── plugin.json               # plugin manifest for the `ravi` plugin
.cursor-plugin/
├── marketplace.json          # Cursor marketplace index (ravi only)
├── plugin.json               # Cursor plugin manifest (skills plugin + hooks + logo)
└── assets/
    └── logo.svg              # copy of repo-root assets/logo.svg (crawler 200 from either base)
shipping/
└── mcp.json                  # MCP product (kept off the plugin-root crawl path; endpoint is not live)
bin/
└── ravi                      # Claude Code plugin PATH wrapper (installs CLI on first use)
hooks/
├── hooks.json                # Claude Code SessionStart → install CLI
└── cursor.json               # Cursor sessionStart → skills live surface (Connect not live)
scripts/
├── install-cli.sh            # downloads official ravi-hq/cli release into ~/.ravi/bin
├── ensure-cli.sh             # SessionStart helper (install + CLAUDE_ENV_FILE PATH)
└── cursor-session-start.sh   # Cursor hook helper
skills/                       # skills for the `ravi` plugin (all of them)
├── ravi/                     # includes scripts/install-cli.sh for skills.sh installs
├── ravi-identity/
├── ravi-inbox/
├── ravi-email-send/
├── ...
plugins/
└── ravix/                    # source root for the `ravix` plugin
    ├── .claude-plugin/
    │   └── plugin.json
    └── skills/
        └── ravix-reply/
```

### Why two plugins?

Claude Code's install granularity is **plugin**, not skill. A plugin loads every skill under `<source>/skills/` — there's no way to subset. So if you want users to be able to install a single skill in isolation, it has to live in its own plugin directory with its own `source`.

The `ravix` plugin exists because the [ravix daemon](https://github.com/ravi-hq/ravix) only needs the reply skill. Installing the full `ravi` plugin there would drag in 10 unused skills.

### Decision guide

| Situation | Where it goes |
|---|---|
| New general-purpose skill for the `ravi` CLI (identity, inbox, passwords, etc.) | `skills/<name>/` — it's loaded by the `ravi` plugin automatically. |
| Skill tightly scoped to a sibling product (like `ravix`) that users install separately | New plugin under `plugins/<product>/`, add to `.claude-plugin/marketplace.json` only. Do not add it to the Cursor marketplace index. |
| "Alternate bundle" of existing skills (e.g. a lightweight subset of `ravi`) | New plugin under `plugins/<bundle-name>/` with symlinks or copies of the desired skills. |

### Adding a new sub-plugin

1. Create `plugins/<name>/.claude-plugin/plugin.json` with `name`, `description`, `version`, etc.
2. Create `plugins/<name>/skills/<skill>/SKILL.md` with the standard frontmatter (`name`, `description`).
3. Add an entry to `.claude-plugin/marketplace.json`:
   ```json
   {
     "name": "<name>",
     "source": "./plugins/<name>",
     "description": "..."
   }
   ```
**CLI installer:** edit `scripts/install-cli.sh`, then copy it to `skills/ravi/scripts/install-cli.sh` and `skills/ravi-login/scripts/install-cli.sh` so skills.sh / ClawdHub installs include it. `tests/check.sh` fails if those copies drift.
