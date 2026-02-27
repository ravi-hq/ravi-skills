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

1. Bump the version in `.claude-plugin/plugin.json`
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
