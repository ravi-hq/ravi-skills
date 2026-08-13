#!/usr/bin/env bash
# Cursor plugin sessionStart: prefer the remote MCP connector. Do not install the CLI.
set -euo pipefail

# Consume hook stdin (JSON event payload).
cat >/dev/null || true

context="Ravi on Cursor is a remote MCP connector at https://api.ravi.app/mcp. After the plugin is connected, use MCP tools for auth, identity, inbox, send email, and send SMS. Do not brew-install or download a ravi binary for this path. If Cursor prompts the human to approve access, send them to https://ravi.id/device. CLI install is only a fallback for agents that are not on Cursor MCP."

if command -v python3 >/dev/null 2>&1; then
  CONTEXT_VALUE="$context" python3 - <<'PY'
import json, os
print(json.dumps({"additional_context": os.environ["CONTEXT_VALUE"]}))
PY
  exit 0
fi

escape() { printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'; }
printf '{"additional_context":"%s"}\n' "$(escape "$context")"
