# Publishing

This repo distributes skills to three channels. Two are automatic, one requires a version bump.

## Distribution Channels

### 1. skills.sh (automatic)

Users install via `npx skills add ravi-hq/ravi-skills`. No publishing step — skills.sh reads directly from the GitHub repo's `skills/` directory.

### 2. Claude Code Plugin (automatic)

Users install via `/plugin marketplace add ravi-hq/ravi-skills`. No publishing step — Claude Code reads `.claude-plugin/plugin.json` and `skills/` directly from the repo.

### 3. ClawdHub / OpenClaw (requires version bump)

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
.claude-plugin/
├── marketplace.json          # lists both plugins
└── plugin.json               # plugin manifest for the `ravi` plugin
skills/                       # skills for the `ravi` plugin (all of them)
├── ravi/
├── ravi-identity/
├── ravi-inbox/
├── ravi-email-send/
├── ...
plugins/
└── ravi-cc/                  # source root for the `ravi-cc` plugin
    ├── .claude-plugin/
    │   └── plugin.json
    └── skills/
        └── ravi-cc-reply/
```

### Why two plugins?

Claude Code's install granularity is **plugin**, not skill. A plugin loads every skill under `<source>/skills/` — there's no way to subset. So if you want users to be able to install a single skill in isolation, it has to live in its own plugin directory with its own `source`.

The `ravi-cc` plugin exists because the [ravi-cc daemon](https://github.com/ravi-hq/ravi-cc) only needs the reply skill. Installing the full `ravi` plugin there would drag in 10 unused skills.

### Decision guide

| Situation | Where it goes |
|---|---|
| New general-purpose skill for the `ravi` CLI (identity, inbox, passwords, etc.) | `skills/<name>/` — it's loaded by the `ravi` plugin automatically. |
| Skill tightly scoped to a sibling product (like `ravi-cc`) that users install separately | New plugin under `plugins/<product>/`, add to `marketplace.json`. |
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
4. Users install with `/plugin install <name>@ravi-hq`. Existing marketplace installs need a refresh: `/plugin marketplace update ravi-hq`.
