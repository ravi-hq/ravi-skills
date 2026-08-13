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

if grep -q 'https://docs.ravi.app/getting-started/authentication/' skills/ravi-login/SKILL.md; then
  ok "ravi-login links getting-started authentication docs"
else
  bad "ravi-login must link https://docs.ravi.app/getting-started/authentication/"
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
  ok "multi-agent path is HTTP API with per-identity ravi_id_ keys (or Connect)"
else
  bad "overview, identity, login, and README must point multi-agent at HTTP API ravi_id_ keys or Connect"
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
    bad "$skill must mention MCP as the Cursor path"
  fi
  if grep -q 'Connect' "$skill"; then
    ok "$skill mentions Connect"
  else
    bad "$skill must mention Connect as Cursor auth"
  fi
done

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

if grep -q 'install-cli.sh' scripts/cursor-session-start.sh; then
  bad "Cursor sessionStart must not install the CLI (MCP is the Cursor path)"
else
  ok "Cursor sessionStart does not install the CLI"
fi

[ -f mcp.json ] || bad "mcp.json missing"

if grep -q 'https://api.ravi.app/mcp' mcp.json README.md; then
  ok "Cursor MCP URL is https://api.ravi.app/mcp"
else
  bad "mcp.json and README must use https://api.ravi.app/mcp"
fi

if python3 - <<'PY'
import json, sys
from pathlib import Path
data = json.loads(Path("mcp.json").read_text())
servers = data.get("mcpServers") or {}
ravi = servers.get("ravi") or {}
ok = True
if "command" in ravi or "args" in ravi:
    print("mcp.json must be remote URL, not stdio/command")
    ok = False
if "headers" in ravi:
    print("mcp.json must not use static headers; Connect is auth")
    ok = False
if ravi.get("url") != "https://api.ravi.app/mcp":
    print("mcp.json ravi.url must be https://api.ravi.app/mcp")
    ok = False
if "npx" in json.dumps(data):
    print("mcp.json must not use npx")
    ok = False
sys.exit(0 if ok else 1)
PY
then
  ok "mcp.json is a remote URL (no stdio, no npx)"
else
  bad "mcp.json is not a remote-only MCP config"
fi

if awk '/^## Cursor/,/^## Other agents/' README.md | grep -qE 'brew install|install-cli.sh'; then
  bad "README Cursor section must not tell users to install the CLI first"
else
  ok "README Cursor section does not require a CLI install"
fi

if awk '/^## Cursor/,/^## Other agents/' README.md | grep -qi 'Connect'; then
  ok "README Cursor section uses Connect as auth"
else
  bad "README Cursor section must tell users to tap Connect (same as GitHub/Linear)"
fi

if awk '/^## Cursor/,/^## Other agents/' README.md | grep -q 'ravi.id/device'; then
  bad "README Cursor section must not use device-code auth (Connect is auth)"
else
  ok "README Cursor section does not send users to ravi.id/device"
fi

cursor_login_instr=$(awk '/^## Cursor/,/^## Other agents/' README.md \
  | grep 'ravi auth login' | grep -viE 'do \*\*not\*\*|do not|not run' || true)
if [ -n "$cursor_login_instr" ]; then
  echo "$cursor_login_instr"
  bad "README Cursor section must not instruct ravi auth login"
else
  ok "README Cursor section does not instruct ravi auth login"
fi

if grep -q 'Connect' scripts/cursor-session-start.sh \
   && grep -q 'per-agent' scripts/cursor-session-start.sh \
   && grep -q 'one identity per machine' scripts/cursor-session-start.sh \
   && ! grep -q 'ravi auth login' scripts/cursor-session-start.sh \
   && ! grep -q 'ravi.id/device' scripts/cursor-session-start.sh \
   && ! grep -q 'config.json' scripts/cursor-session-start.sh; then
  ok "Cursor sessionStart uses Connect; no CLI login; one identity per machine"
else
  bad "cursor-session-start.sh must use Connect (per-agent) and must not mention CLI login, config.json, or ravi.id/device"
fi

if grep -qiE 'remote MCP|Connect' README.md && grep -q 'https://api.ravi.app/mcp' README.md; then
  ok "README documents Cursor remote MCP + Connect"
else
  bad "README must document Cursor remote MCP and Connect as the primary Cursor path"
fi


if [ "$fail" -ne 0 ]; then
  echo "install-path checks failed" >&2
  exit 1
fi
echo "all install-path checks passed"
