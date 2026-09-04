#!/usr/bin/env bash
# Static checks: remote Cursor MCP, CLI fallback, canonical device-login URL.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
fail=0

ok() { printf 'ok  %s\n' "$1"; }
bad() { printf 'FAIL %s\n' "$1" >&2; fail=1; }

[ -x scripts/install-cli.sh ] || bad "scripts/install-cli.sh must be executable"
[ -x scripts/ensure-cli.sh ] || bad "scripts/ensure-cli.sh must be executable"
[ -x scripts/cursor-session-start.sh ] || bad "scripts/cursor-session-start.sh must be executable"
[ -x bin/ravi ] || bad "bin/ravi must be executable"
[ -f hooks/hooks.json ] || bad "hooks/hooks.json missing"
[ -f hooks/cursor.json ] || bad "hooks/cursor.json missing"
[ -f .cursor-plugin/plugin.json ] || bad ".cursor-plugin/plugin.json missing"
[ -f .cursor-plugin/marketplace.json ] || bad ".cursor-plugin/marketplace.json missing"
[ -f plugin.json ] || bad "root plugin.json (Agent Plugins manifest) missing"

if [ -x scripts/install-cli.sh ]; then
  ok "scripts/install-cli.sh is executable"
fi
if [ -x bin/ravi ]; then
  ok "bin/ravi is executable"
fi

for copy in skills/ravi/scripts/install-cli.sh skills/ravi-login/scripts/install-cli.sh; do
  if [ ! -f "$copy" ]; then
    bad "$copy missing (skills.sh only copies the skill directory)"
    continue
  fi
  if ! cmp -s scripts/install-cli.sh "$copy"; then
    bad "$copy does not match scripts/install-cli.sh"
  else
    ok "$copy matches scripts/install-cli.sh"
  fi
  [ -x "$copy" ] || bad "$copy must be executable"
done

if grep -q 'install-cli.sh' README.md; then
  ok "README documents install-cli.sh"
else
  bad "README must document scripts/install-cli.sh as part of the install path"
fi

if grep -q 'bin/ravi' README.md PUBLISHING.md; then
  ok "docs mention bin/ravi"
else
  bad "docs should mention bin/ravi"
fi

# Presenting the apex API host is wrong. Lines that only forbid that host are allowed.
stale_api_host=$(grep -RInE --exclude-dir=.git --exclude-dir=tests --include='*.md' --include='*.sh' --include='*.json' \
     'https://ravi\.app/api/' . 2>/dev/null | grep -viE 'never |wrong host' || true)
if [ -n "$stale_api_host" ]; then
  echo "$stale_api_host"
  bad "wrong API host (apex /api) — use api.ravi.app or https://ravi.id/device"
else
  ok "no apex /api hosts presented as canonical"
fi

if grep -R -nE 'ravi\.app/docs/' \
    --exclude-dir=.git --exclude-dir=tests --include='*.md' --include='*.sh' --include='*.json' .; then
  bad "dead docs host (use https://docs.ravi.app/...)"
else
  ok "no ravi.app/docs/ URLs"
fi

if grep -q 'https://docs.ravi.app' skills/ravi-login/SKILL.md; then
  ok "ravi-login links https://docs.ravi.app"
else
  bad "ravi-login must link https://docs.ravi.app (no page path)"
fi

page_paths=$(grep -RInE --exclude-dir=.git --include='*.md' --include='*.json' \
     'docs\.ravi\.app/(getting-started|core-concepts)' \
     README.md skills .cursor-plugin 2>/dev/null || true)
if [ -n "$page_paths" ]; then
  echo "$page_paths"
  bad "docs links must be https://docs.ravi.app with no getting-started / core-concepts page names"
else
  ok "no getting-started / core-concepts docs page names"
fi

if grep -q 'https://ravi.id/device' skills/ravi-login/SKILL.md; then
  ok "ravi-login (CLI path) uses https://ravi.id/device"
else
  bad "ravi-login skill must mention https://ravi.id/device"
fi

if awk '/^## Other agents/,/^## Skills/' README.md | grep -q 'https://ravi.id/device'; then
  ok "README CLI fallback uses https://ravi.id/device"
else
  bad "README other-agents section must mention https://ravi.id/device"
fi

# Shipped auth is login/logout/status + ravi_mgmt_/ravi_id_ keys.
# Lines that only forbid JWT / auth.json / refresh / etc. are allowed.
stale_auth=$(grep -RInE --exclude-dir=.git --include='*.md' \
     'auth\.json|RAVI_ACCESS_TOKEN|X-Ravi-Identity|ravi auth refresh|\bJWT\b' \
     skills plugins README.md 2>/dev/null \
     | grep -viE 'do not|do \*\*not\*\*|never |there is no|not look' || true)
if [ -n "$stale_auth" ]; then
  echo "$stale_auth"
  bad "stale auth model (no JWT, auth.json, RAVI_ACCESS_TOKEN, ravi auth refresh, X-Ravi-Identity)"
else
  ok "skills do not document JWT/auth.json/RAVI_ACCESS_TOKEN/refresh/X-Ravi-Identity as shipped auth"
fi

if grep -q 'ravi_mgmt_' skills/ravi-login/SKILL.md && grep -q 'ravi_id_' skills/ravi-login/SKILL.md \
   && grep -q '~/.ravi/config.json' skills/ravi-login/SKILL.md; then
  ok "ravi-login documents ravi_mgmt_ / ravi_id_ keys in config.json"
else
  bad "ravi-login must document ravi_mgmt_ / ravi_id_ keys in ~/.ravi/config.json"
fi

if grep -q 'ravi auth login' skills/ravi-login/SKILL.md \
   && grep -q 'logout' skills/ravi-login/SKILL.md \
   && grep -q 'status' skills/ravi-login/SKILL.md; then
  ok "ravi-login documents login / logout / status"
else
  bad "ravi-login must document ravi auth login / logout / status only"
fi

for f in skills/ravi/SKILL.md skills/ravi-identity/SKILL.md skills/ravi-login/SKILL.md README.md; do
  if grep -qi 'one identity per machine' "$f"; then
    ok "$f states CLI is one identity per machine"
  else
    bad "$f must state the CLI is one identity per machine"
  fi
done

if grep -q 'HTTP API' skills/ravi/SKILL.md skills/ravi-identity/SKILL.md skills/ravi-login/SKILL.md README.md \
   && grep -q 'ravi_id_' skills/ravi/SKILL.md skills/ravi-identity/SKILL.md skills/ravi-login/SKILL.md README.md; then
  ok "multi-agent path is HTTP API with per-identity ravi_id_ keys"
else
  bad "overview, identity, login, and README must point multi-agent at HTTP API ravi_id_ keys"
fi

# Do not instruct identity switching via shared CLI config (prohibition lines are allowed).
switch_instr=$(grep -RInE --exclude-dir=.git --include='*.md' \
     'ravi identity use|--identity' skills README.md PUBLISHING.md 2>/dev/null \
     | grep -viE 'do not|do \*\*not\*\*|never |not flip|not multiplex|not a multi-agent' || true)
if [ -n "$switch_instr" ]; then
  echo "$switch_instr"
  bad "skills must not tell agents to flip CLI identity / --identity to run side by side"
else
  ok "skills do not instruct ravi identity use / --identity as a multi-agent switch"
fi

# Skills that invoke the CLI must tell agents how to install it.
for skill in skills/ravi/SKILL.md skills/ravi-login/SKILL.md skills/ravi-identity/SKILL.md \
             skills/ravi-inbox/SKILL.md skills/ravi-email-send/SKILL.md skills/ravi-passwords/SKILL.md \
             skills/ravi-secrets/SKILL.md skills/ravi-sso/SKILL.md skills/ravi-contacts/SKILL.md \
             skills/ravi-feedback/SKILL.md; do
  if grep -q 'install-cli.sh' "$skill"; then
    ok "$skill mentions install-cli.sh"
  else
    bad "$skill must mention install-cli.sh"
  fi
  if grep -qiE 'mcp' "$skill"; then
    ok "$skill mentions MCP"
  else
    bad "$skill must mention MCP (shipping / not live)"
  fi
  if grep -q 'Connect' "$skill"; then
    ok "$skill mentions Connect"
  else
    bad "$skill must mention Connect (as shipping / not live)"
  fi
done

# No skill may instruct tap-Connect as live auth.
live_tap=$(grep -RIn --include='SKILL.md' -E 'tap \*\*Connect\*\*|tap Connect|Auth is the plugin \*\*Connect\*\*|That is auth' skills \
  | grep -viE 'do not tap|not live|shipping' || true)
if [ -n "$live_tap" ]; then
  echo "$live_tap"
  bad "no skill may tell an agent to tap Connect as live auth"
else
  ok "no skill tells an agent to tap Connect as live auth"
fi

if grep -q 'ensure-cli.sh' hooks/hooks.json; then
  ok "Claude SessionStart hook runs ensure-cli.sh"
else
  bad "hooks/hooks.json must run ensure-cli.sh"
fi

if grep -q 'cursor-session-start.sh' hooks/cursor.json; then
  ok "Cursor sessionStart hook runs cursor-session-start.sh"
else
  bad "hooks/cursor.json must run cursor-session-start.sh"
fi

if grep -q 'hooks/cursor.json' .cursor-plugin/plugin.json; then
  ok "Cursor plugin.json points at Cursor hooks"
else
  bad ".cursor-plugin/plugin.json must set hooks to ./hooks/cursor.json"
fi

if grep -q 'install-cli.sh' scripts/cursor-session-start.sh \
   && grep -q 'ravi auth login' scripts/cursor-session-start.sh \
   && grep -q 'https://ravi.id/device' scripts/cursor-session-start.sh \
   && grep -qiE 'not live' scripts/cursor-session-start.sh \
   && grep -q 'do not tap Connect' scripts/cursor-session-start.sh; then
  ok "Cursor sessionStart: skills live; CLI working auth; Connect not live"
else
  bad "cursor-session-start.sh must use CLI auth and must not treat Connect as live"
fi

if [ -f mcp.json ]; then
  ok "plugin root has mcp.json"
else
  bad "mcp.json must sit at the plugin root (https://api.ravi.app/mcp answers)"
fi
[ -f shipping/mcp.json ] || bad "shipping/mcp.json missing (keep a duplicate of root mcp.json)"
if [ -f mcp.json ] && [ -f shipping/mcp.json ]; then
  if cmp -s mcp.json shipping/mcp.json; then
    ok "shipping/mcp.json matches root mcp.json"
  else
    bad "shipping/mcp.json must match root mcp.json"
  fi
fi
[ -f assets/logo.svg ] || [ -f assets/logo.png ] || bad "assets/logo.svg or assets/logo.png missing"
[ -f .cursor-plugin/assets/logo.svg ] || [ -f .cursor-plugin/assets/logo.png ] || bad ".cursor-plugin/assets/logo.svg missing (crawler resolving from .cursor-plugin/)"

if python3 - <<'PY'
import json, sys
from pathlib import Path
p = json.loads(Path(".cursor-plugin/plugin.json").read_text())
ok = True
def need(key, pred):
    global ok
    if not pred(p.get(key)):
        print(f"plugin.json missing or invalid: {key}")
        ok = False
need("name", lambda v: v == "ravi")
need("description", lambda v: isinstance(v, str) and "Ravi gives AI agents their own identity" in v)
need("version", lambda v: isinstance(v, str) and len(v) > 0)
need("author", lambda v: isinstance(v, dict) and v.get("name"))
need("homepage", lambda v: v == "https://ravi.id")
need("repository", lambda v: v == "https://github.com/ravi-hq/ravi-skills")
need("license", lambda v: v == "MIT")
need("keywords", lambda v: isinstance(v, list) and len(v) > 0)
need("logo", lambda v: isinstance(v, str) and v.startswith("assets/logo."))
logo = p.get("logo")
if isinstance(logo, str) and not Path(logo).is_file():
    print(f"plugin.json logo file missing: {logo}")
    ok = False
if "ravix" in (p.get("description") or "").lower():
    print("plugin.json description must not mention ravix")
    ok = False
sys.exit(0 if ok else 1)
PY
then
  ok "plugin.json is marketplace-submittable (name ravi, logo, listing fields)"
else
  bad "plugin.json is not ready for cursor.com/marketplace/publish"
fi

if python3 - <<'PY'
import json, sys
from pathlib import Path
p = json.loads(Path("plugin.json").read_text())
cursor = json.loads(Path(".cursor-plugin/plugin.json").read_text())
ok = True
if p.get("$schema") != "https://agent-plugins.org/schemas/1.0.0/plugin.schema.json":
    print("root plugin.json $schema must be the Agent Plugins 1.0.0 schema")
    ok = False
if p.get("name") != "ravi":
    print("root plugin.json name must be ravi")
    ok = False
if p.get("description") != cursor.get("description"):
    print("root plugin.json description must match .cursor-plugin/plugin.json")
    ok = False
if p.get("version") != cursor.get("version"):
    print("root plugin.json version must match .cursor-plugin/plugin.json")
    ok = False
if not isinstance(p.get("author"), dict) or p["author"].get("name") != "Ravi":
    print("root plugin.json author.name must be Ravi")
    ok = False
if "mcpServers" in p:
    print("root plugin.json must not include mcpServers")
    ok = False
if "mcp" in json.dumps(p).lower() and "mcpServers" in p:
    print("root plugin.json must not mention MCP servers")
    ok = False
extra = set(p) - {"$schema", "name", "description", "version", "author"}
# Agent Plugins schema is closed; extra keys fail crawler validation.
if extra:
    print(f"root plugin.json has disallowed keys: {sorted(extra)}")
    ok = False
sys.exit(0 if ok else 1)
PY
then
  ok "root plugin.json is a skills-only Agent Plugins manifest"
else
  bad "root plugin.json is not a valid skills-only Agent Plugins manifest"
fi

if grep -q 'https://api.ravi.app/mcp' mcp.json shipping/mcp.json; then
  ok "mcp.json and shipping/mcp.json keep URL https://api.ravi.app/mcp"
else
  bad "mcp.json and shipping/mcp.json must keep https://api.ravi.app/mcp"
fi

if python3 - <<'PY'
import json, sys
from pathlib import Path
data = json.loads(Path("shipping/mcp.json").read_text())
servers = data.get("mcpServers") or {}
ravi = servers.get("ravi") or {}
ok = True
if "command" in ravi or "args" in ravi:
    print("shipping/mcp.json must be remote URL, not stdio/command")
    ok = False
if "headers" in ravi:
    print("shipping/mcp.json must not use static headers")
    ok = False
if ravi.get("url") != "https://api.ravi.app/mcp":
    print("shipping/mcp.json ravi.url must be https://api.ravi.app/mcp")
    ok = False
if "npx" in json.dumps(data):
    print("shipping/mcp.json must not use npx")
    ok = False
sys.exit(0 if ok else 1)
PY
then
  ok "shipping/mcp.json is a remote URL (no stdio, no npx)"
else
  bad "shipping/mcp.json is not a remote-only MCP config"
fi

if python3 - <<'PY'
import json, sys
from pathlib import Path
market = json.loads(Path(".cursor-plugin/marketplace.json").read_text())
names = [p.get("name") for p in (market.get("plugins") or [])]
ok = True
if names != ["ravi"]:
    print(f".cursor-plugin/marketplace.json plugins must be ravi only, got {names}")
    ok = False
if "ravix" in json.dumps(market):
    print(".cursor-plugin/marketplace.json must not list ravix")
    ok = False
sys.exit(0 if ok else 1)
PY
then
  ok "Cursor marketplace index lists ravi only"
else
  bad "Cursor marketplace index must list ravi only (no ravix)"
fi

if cmp -s assets/logo.svg .cursor-plugin/assets/logo.svg; then
  ok "logo.svg is identical at repo-root and .cursor-plugin/assets/"
else
  bad "assets/logo.svg and .cursor-plugin/assets/logo.svg must match"
fi

if awk '/^## Cursor/,/^## Other agents/' README.md | grep -q 'install-cli.sh'; then
  ok "README Cursor section documents working CLI auth"
else
  bad "README Cursor section must document install-cli.sh as working auth"
fi

listing_desc='Ravi gives AI agents their own identity (email inbox, real phone, encrypted vault) so they can sign up for services, receive verification codes, and keep the passwords they create. For teams whose agents have to act on the web, not just talk.'
if grep -qF "$listing_desc" README.md plugin.json .cursor-plugin/plugin.json .cursor-plugin/marketplace.json; then
  ok "listing copy uses the Growth description exactly"
else
  bad "README, plugin.json, and marketplace.json must use the Growth listing description"
fi

if python3 - <<'PY'
import json, sys
from pathlib import Path
want = "Ravi gives AI agents their own identity (email inbox, real phone, encrypted vault) so they can sign up for services, receive verification codes, and keep the passwords they create. For teams whose agents have to act on the web, not just talk."
plugin = json.loads(Path(".cursor-plugin/plugin.json").read_text())
market = json.loads(Path(".cursor-plugin/marketplace.json").read_text())
ok = True
if plugin.get("displayName") != "Ravi — identity for AI agents":
    print("plugin.json displayName must be: Ravi — identity for AI agents")
    ok = False
if plugin.get("description") != want:
    print("plugin.json description must match Growth copy exactly")
    ok = False
ravi = next((p for p in market.get("plugins") or [] if p.get("name") == "ravi"), None)
if not ravi or ravi.get("description") != want:
    print("marketplace.json ravi plugin description must match Growth copy exactly")
    ok = False
sys.exit(0 if ok else 1)
PY
then
  ok "plugin.json and marketplace.json ravi descriptions match Growth copy exactly"
else
  bad "plugin.json / marketplace.json listing copy is not exact"
fi

if grep -nE 'like any other plugin|like any other Cursor plugin' \
     README.md .cursor-plugin/plugin.json .cursor-plugin/marketplace.json; then
  bad "listing copy must not say like any other plugin"
else
  ok "listing copy does not say like any other plugin"
fi

if awk '/^## Cursor/,/^## Other agents/' README.md | grep -qiE 'not live yet'; then
  ok "README Cursor section does not claim Connect is live"
else
  bad "README Cursor section must say the Connect card is shipping / not live yet"
fi

live_claim=$(grep -nE 'That is auth|tap Connect for auth|Auth is the Connect card|live auth path' \
  README.md .cursor-plugin/plugin.json .cursor-plugin/marketplace.json 2>/dev/null \
  | grep -v 'not the live auth path' | grep -v 'Do not treat' || true)
if [ -n "$live_claim" ]; then
  echo "$live_claim"
  bad "listing copy must not claim the Connect card already authenticates"
else
  ok "listing copy does not claim Connect already authenticates"
fi

if awk '/^## Cursor/,/^## Other agents/' README.md | grep -q 'Skills are the live surface'; then
  ok "README Cursor section leads with skills as the live surface"
else
  bad "README Cursor section must say skills are the live surface"
fi

if awk '/^## Cursor/,/^## Other agents/' README.md | grep -q 'https://api.ravi.app/mcp' \
   && awk '/^## Cursor/,/^## Other agents/' README.md | grep 'https://api.ravi.app/mcp' | grep -viE 'not live|not a working|404' >/dev/null; then
  bad "README Cursor section must not lead with https://api.ravi.app/mcp as a working connector"
else
  ok "README Cursor section does not lead with the MCP URL as working"
fi

if grep -qE 'integrations/|production-patterns' README.md .cursor-plugin/plugin.json .cursor-plugin/marketplace.json; then
  bad "listing copy must not add integrations/ or production-patterns pages"
else
  ok "listing copy has no integrations/ or production-patterns pages"
fi

if grep -q 'https://docs.ravi.app' README.md .cursor-plugin/plugin.json .cursor-plugin/marketplace.json; then
  ok "listing copy links https://docs.ravi.app"
else
  bad "README and plugin listing must link https://docs.ravi.app (no page names)"
fi

if grep -q 'terminals and CI\|terminals, CI' README.md; then
  ok "README says CLI is for terminals and CI"
else
  bad "README must say the CLI is for terminals and CI"
fi

if awk '/^## Cursor/,/^## Other agents/' README.md | grep -q 'https://ravi.id/device' \
   && awk '/^## Cursor/,/^## Other agents/' README.md | grep -q 'ravi auth login'; then
  ok "README Cursor section documents CLI auth (ravi.id/device)"
else
  bad "README Cursor section must document working CLI auth at https://ravi.id/device"
fi

if grep -q 'https://cursor.com/marketplace/publish' PUBLISHING.md; then
  ok "PUBLISHING.md documents Cursor Marketplace submit"
else
  bad "PUBLISHING.md must add Cursor Marketplace submit at https://cursor.com/marketplace/publish"
fi

if grep -q 'plugin.json' PUBLISHING.md && grep -q 'agent-plugins.org' PUBLISHING.md \
   && grep -q 'shipping/mcp.json' PUBLISHING.md \
   && grep -q 'npx skills add ravi-hq/ravi-skills' PUBLISHING.md \
   && grep -qiE 'not live' PUBLISHING.md; then
  ok "PUBLISHING.md notes root Agent Plugin manifest, shipping MCP path, and listing not live"
else
  bad "PUBLISHING.md must note the root Agent Plugin manifest, shipping/mcp.json, first hop, and that the listing is not live"
fi

if grep -q 'https://api.ravi.app/mcp' plugin.json .cursor-plugin/plugin.json .cursor-plugin/marketplace.json; then
  bad "crawler manifests must stay skills-only; MCP URL belongs in mcp.json"
else
  ok "crawler manifests do not include the MCP URL"
fi

if python3 - <<'PY'
import json, sys
from pathlib import Path
p = json.loads(Path(".cursor-plugin/plugin.json").read_text())
sys.exit(1 if "mcpServers" in p else 0)
PY
then
  ok ".cursor-plugin/plugin.json has no mcpServers (listing is skills-only)"
else
  bad ".cursor-plugin/plugin.json must not declare mcpServers (skills-only; MCP is in mcp.json)"
fi


if [ "$fail" -ne 0 ]; then
  echo "install-path checks failed" >&2
  exit 1
fi
echo "all install-path checks passed"
