#!/usr/bin/env bash
# Cursor plugin sessionStart: skills are live; Connect is not. Working auth is the CLI.
set -euo pipefail

# Consume hook stdin (JSON event payload).
cat >/dev/null || true

context="Ravi on Cursor is a skills plugin. Skills are the live surface (identity, inbox, vault, send email, send SMS). A Connect card is shipping and is not live yet — do not tap Connect as if it authenticates, and do not treat https://api.ravi.app/mcp as a working connector. Working auth is the CLI: run scripts/install-cli.sh if ravi is missing, then ravi auth login (human visits https://ravi.id/device). CLI is one identity per machine. Extra agents use the HTTP API with per-identity ravi_id_ keys."

if command -v python3 >/dev/null 2>&1; then
  CONTEXT_VALUE="$context" python3 - <<'PY'
import json, os
print(json.dumps({"additional_context": os.environ["CONTEXT_VALUE"]}))
PY
  exit 0
fi

escape() { printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'; }
printf '{"additional_context":"%s"}\n' "$(escape "$context")"
