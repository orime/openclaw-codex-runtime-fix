#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RESTART=0

for arg in "$@"; do
  case "$arg" in
    --restart) RESTART=1 ;;
    *)
      echo "Unknown argument: $arg" >&2
      exit 1
      ;;
  esac
done

LATEST_BACKUP="$(find "$ROOT_DIR/backups" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | sort | tail -n 1 || true)"

if [[ -z "$LATEST_BACKUP" || ! -d "$LATEST_BACKUP" ]]; then
  echo "No backup directory found." >&2
  exit 1
fi

resolve_realpath() {
  node -e 'const fs=require("fs"); console.log(fs.realpathSync(process.argv[1]));' "$1"
}

guess_dist_dir() {
  if [[ -n "${OPENCLAW_DIST_DIR:-}" ]]; then
    echo "$OPENCLAW_DIST_DIR"
    return 0
  fi

  local bin
  if bin="$(command -v openclaw 2>/dev/null)"; then
    local real_bin
    real_bin="$(resolve_realpath "$bin")"
    local candidate
    candidate="$(cd "$(dirname "$real_bin")/dist" 2>/dev/null && pwd || true)"
    if [[ -n "$candidate" && -d "$candidate" ]]; then
      echo "$candidate"
      return 0
    fi
    candidate="$(cd "$(dirname "$real_bin")/../lib/node_modules/openclaw/dist" 2>/dev/null && pwd || true)"
    if [[ -n "$candidate" && -d "$candidate" ]]; then
      echo "$candidate"
      return 0
    fi
  fi

  if [[ -d "/Applications/QClaw.app/Contents/Resources/openclaw/node_modules/openclaw/dist" ]]; then
    echo "/Applications/QClaw.app/Contents/Resources/openclaw/node_modules/openclaw/dist"
    return 0
  fi

  echo "Unable to locate OpenClaw dist directory." >&2
  exit 1
}

DIST_DIR="$(guess_dist_dir)"

for file in "$LATEST_BACKUP"/*; do
  [[ -f "$file" ]] || continue
  cp "$file" "$DIST_DIR/$(basename "$file")"
done

echo "Restored backup from: $LATEST_BACKUP"

if [[ "$RESTART" -eq 1 ]]; then
  openclaw gateway restart
fi
