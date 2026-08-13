#!/usr/bin/env bash
# Cursor plugin sessionStart: prefer the remote MCP connector. Do not install the CLI.
set -euo pipefail

# Consume hook stdin (JSON event payload).
cat >/dev/null || true

context="Ravi on Cursor is a remote MCP connector at https://api.ravi.app/mcp. Auth is the plugin Connect card (same as GitHub/Linear): it binds a fenced ravi_id_ key to this agent. Use MCP tools for identity, inbox, vault, send email, and send SMS. Do not install a ravi binary or use CLI login on this path. If tools are missing, ask the human to tap Connect on the Ravi plugin. CLI login is only for non-Cursor agents and CI."

if command -v python3 >/dev/null 2>&1; then
  CONTEXT_VALUE="$context" python3 - <<'PY'
import json, os
print(json.dumps({"additional_context": os.environ["CONTEXT_VALUE"]}))
PY
  exit 0
fi

escape() { printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'; }
printf '{"additional_context":"%s"}\n' "$(escape "$context")"
