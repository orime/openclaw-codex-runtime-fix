#!/usr/bin/env bash
set -euo pipefail

REPO_URL="${REPO_URL:-https://github.com/orime/openclaw-codex-runtime-fix.git}"
TMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/openclaw-codex-runtime-fix.XXXXXX")"

cleanup() {
  rm -rf "$TMP_DIR"
}

trap cleanup EXIT

git clone --depth=1 "$REPO_URL" "$TMP_DIR/repo" >/dev/null 2>&1
cd "$TMP_DIR/repo"

./scripts/apply.sh "$@"
./scripts/verify.sh
