#!/usr/bin/env bash
# Plugin SessionStart helper: install the Ravi CLI and persist PATH for this session.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
INSTALL="${ROOT}/install-cli.sh"

if [ ! -f "$INSTALL" ]; then
  echo "ensure-cli.sh: missing ${INSTALL}" >&2
  exit 1
fi

bash "$INSTALL"

bin_dir="${RAVI_INSTALL_DIR:-${HOME}/.ravi/bin}"
if [ -n "${CLAUDE_ENV_FILE:-}" ]; then
  echo "export PATH=\"${bin_dir}:\$PATH\"" >> "$CLAUDE_ENV_FILE"
fi
