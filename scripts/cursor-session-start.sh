#!/usr/bin/env bash
# Cursor plugin sessionStart hook: install the Ravi CLI and inject PATH.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
INSTALL="${ROOT}/install-cli.sh"

# Consume hook stdin (JSON event payload).
cat >/dev/null || true

if [ -f "$INSTALL" ]; then
  bash "$INSTALL" >/dev/null
fi

bin_dir="${RAVI_INSTALL_DIR:-${HOME}/.ravi/bin}"
path="${bin_dir}:${PATH}"
context="The Ravi CLI belongs on PATH after this plugin install. If ravi is missing, run scripts/install-cli.sh, then ravi auth login. Send the human to https://ravi.id/device to approve."

if command -v python3 >/dev/null 2>&1; then
  PATH_VALUE="$path" CONTEXT_VALUE="$context" python3 - <<'PY'
import json, os
print(json.dumps({
    "env": {"PATH": os.environ["PATH_VALUE"]},
    "additional_context": os.environ["CONTEXT_VALUE"],
}))
PY
  exit 0
fi

# Minimal JSON fallback if python3 is unavailable.
escape() { printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'; }
printf '{"env":{"PATH":"%s"},"additional_context":"%s"}\n' "$(escape "$path")" "$(escape "$context")"
