#!/usr/bin/env bash
# Install the official Ravi CLI (https://github.com/ravi-hq/cli) into ~/.ravi/bin.
# Skills and marketplace plugins ship this installer, not the binary itself.
set -euo pipefail

REPO="${RAVI_CLI_REPO:-ravi-hq/cli}"
DEST_DIR="${RAVI_INSTALL_DIR:-${HOME}/.ravi/bin}"
DEST="${DEST_DIR}/ravi"

usage() {
  cat <<'EOF'
Install the Ravi CLI into ~/.ravi/bin (override with RAVI_INSTALL_DIR).

Usage: install-cli.sh [--help]

Environment:
  RAVI_INSTALL_DIR  Install directory (default: ~/.ravi/bin)
  RAVI_CLI_VERSION  Pin a release tag or version (e.g. v0.7.3 or 0.7.3)
  RAVI_CLI_REPO     GitHub repo that publishes releases (default: ravi-hq/cli)
  RAVI_SKIP_BREW    Set to 1 to skip Homebrew and download a release archive
EOF
}

is_real_ravi() {
  local bin="$1"
  [ -x "$bin" ] || return 1
  local magic
  magic="$(head -c 2 "$bin" 2>/dev/null || true)"
  [ "$magic" != "#!" ]
}

if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ]; then
  usage
  exit 0
fi

if is_real_ravi "$DEST"; then
  echo "ravi already installed at $DEST"
  exit 0
fi

if [ "${RAVI_SKIP_BREW:-}" != "1" ] && command -v brew >/dev/null 2>&1; then
  if brew list --formula ravi >/dev/null 2>&1 || brew list --formula ravi-hq/tap/ravi >/dev/null 2>&1; then
    echo "ravi already installed via Homebrew"
    exit 0
  fi
  echo "Installing ravi via Homebrew (ravi-hq/tap/ravi)..."
  if brew install ravi-hq/tap/ravi; then
    echo "Installed ravi via Homebrew."
    if command -v ravi >/dev/null 2>&1; then
      echo "ravi is on PATH at $(command -v ravi)"
    else
      echo "Add Homebrew's bin directory to PATH if 'ravi' is not found."
    fi
    exit 0
  fi
  echo "Homebrew install failed; falling back to GitHub release..." >&2
fi

os="$(uname -s | tr '[:upper:]' '[:lower:]')"
arch="$(uname -m)"
case "$os" in
  linux|darwin) ;;
  mingw*|msys*|cygwin*) os="windows" ;;
  *)
    echo "Unsupported OS: $(uname -s). Download a release from https://github.com/${REPO}/releases" >&2
    exit 1
    ;;
esac
case "$arch" in
  x86_64|amd64) arch="amd64" ;;
  arm64|aarch64) arch="arm64" ;;
  *)
    echo "Unsupported architecture: $(uname -m). Download a release from https://github.com/${REPO}/releases" >&2
    exit 1
    ;;
esac

if [ "$os" = "windows" ] && [ "$arch" != "amd64" ]; then
  echo "Windows builds are published for amd64 only. See https://github.com/${REPO}/releases" >&2
  exit 1
fi

need_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "install-cli.sh requires '$1' on PATH" >&2
    exit 1
  fi
}
need_cmd curl
need_cmd tar
if [ "$os" = "windows" ]; then
  need_cmd unzip
fi

tag="${RAVI_CLI_VERSION:-}"
if [ -z "$tag" ]; then
  latest_url="$(curl -fsSL -o /dev/null -w '%{url_effective}' "https://github.com/${REPO}/releases/latest")"
  tag="${latest_url##*/}"
fi
case "$tag" in
  v*) ;;
  *) tag="v${tag}" ;;
esac
version="${tag#v}"

if [ "$os" = "windows" ]; then
  archive="ravi-${version}-${os}-${arch}.zip"
else
  archive="ravi-${version}-${os}-${arch}.tar.gz"
fi
base="https://github.com/${REPO}/releases/download/${tag}"

tmpdir="$(mktemp -d)"
cleanup() { rm -rf "$tmpdir"; }
trap cleanup EXIT

echo "Downloading ${archive} from ${REPO} ${tag}..."
curl -fsSL -o "${tmpdir}/${archive}" "${base}/${archive}"

if command -v sha256sum >/dev/null 2>&1; then
  if curl -fsSL -o "${tmpdir}/checksums.txt" "${base}/checksums.txt"; then
    expected="$(awk -v name="$archive" '$2 == name { print $1 }' "${tmpdir}/checksums.txt")"
    if [ -n "$expected" ]; then
      actual="$(sha256sum "${tmpdir}/${archive}" | awk '{ print $1 }')"
      if [ "$actual" != "$expected" ]; then
        echo "Checksum mismatch for ${archive}" >&2
        echo "expected: ${expected}" >&2
        echo "actual:   ${actual}" >&2
        exit 1
      fi
    fi
  fi
fi

mkdir -p "$DEST_DIR"
if [ "$os" = "windows" ]; then
  unzip -o -q "${tmpdir}/${archive}" -d "$tmpdir"
  src="$(find "$tmpdir" -name 'ravi.exe' -print -quit)"
  [ -n "$src" ] || { echo "Archive did not contain ravi.exe" >&2; exit 1; }
  DEST="${DEST}.exe"
  mv "$src" "$DEST"
else
  tar -xzf "${tmpdir}/${archive}" -C "$tmpdir"
  src="$(find "$tmpdir" -type f -name ravi -print -quit)"
  [ -n "$src" ] || { echo "Archive did not contain ravi" >&2; exit 1; }
  mv "$src" "$DEST"
fi
chmod +x "$DEST"

if [ -d "${HOME}/.local/bin" ] && [ -w "${HOME}/.local/bin" ]; then
  ln -sfn "$DEST" "${HOME}/.local/bin/ravi"
fi

echo "Installed ravi to ${DEST}"
echo "Add it to PATH for this shell:"
echo "  export PATH=\"${DEST_DIR}:\$PATH\""
echo "Then authenticate with: ravi auth login"
echo "Device login URL: https://ravi.id/device"
