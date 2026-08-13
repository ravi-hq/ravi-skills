#!/usr/bin/env bash
# Run the bundled installer into a temp HOME and confirm `ravi` is executable.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WORKDIR="$(mktemp -d)"
cleanup() { rm -rf "$WORKDIR"; }
trap cleanup EXIT

export HOME="${WORKDIR}/home"
mkdir -p "$HOME"
export RAVI_SKIP_BREW=1
export PATH="/usr/bin:/bin"

echo "Installing CLI into ${HOME}/.ravi/bin ..."
bash "${ROOT}/scripts/install-cli.sh"

bin="${HOME}/.ravi/bin/ravi"
if [ ! -x "$bin" ]; then
  echo "expected executable at ${bin}" >&2
  exit 1
fi

echo "Installed binary: $bin"
"$bin" version

# Idempotent second run should not fail.
bash "${ROOT}/scripts/install-cli.sh"

# Wrapper should exec the installed binary (not recurse).
export HOME
PATH="${ROOT}/bin:${HOME}/.ravi/bin:/usr/bin:/bin" "${ROOT}/bin/ravi" version

# skills.sh copies the skill directory only — the bundled copy must install too.
skill_copy="${WORKDIR}/ravi-skill"
mkdir -p "$skill_copy"
cp -a "${ROOT}/skills/ravi/." "$skill_copy/"
export HOME="${WORKDIR}/home-skill"
mkdir -p "$HOME"
rm -f "${HOME}/.ravi/bin/ravi"
bash "${skill_copy}/scripts/install-cli.sh"
[ -x "${HOME}/.ravi/bin/ravi" ] || { echo "skills.sh-bundled installer did not produce ravi" >&2; exit 1; }

echo "install-cli.sh test passed"
