#!/usr/bin/env bash
# Static checks: installer is wired into skills/plugins, device-login URL is canonical.
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

if [ "$fail" -ne 0 ]; then
  echo "install-path checks failed" >&2
  exit 1
fi
echo "all install-path checks passed"
