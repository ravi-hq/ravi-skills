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

if grep -R -nE 'api\.ravi\.app/api/auth/device|ravi\.app/api/auth/device' \
    --exclude-dir=.git --include='*.md' --include='*.sh' --include='*.json' .; then
  bad "stale device-login URL found (use https://ravi.id/device)"
else
  ok "no stale device-login API URLs"
fi

if grep -q 'https://ravi.id/device' skills/ravi-login/SKILL.md README.md; then
  ok "device login docs use https://ravi.id/device"
else
  bad "ravi-login skill and README must mention https://ravi.id/device"
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

if grep -q 'remote MCP' README.md; then
  ok "README documents Cursor remote MCP"
else
  bad "README must document Cursor remote MCP as the primary Cursor path"
fi


if [ "$fail" -ne 0 ]; then
  echo "install-path checks failed" >&2
  exit 1
fi
echo "all install-path checks passed"
