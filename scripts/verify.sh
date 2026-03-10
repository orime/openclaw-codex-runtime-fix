#!/usr/bin/env bash
set -euo pipefail

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

echo "Verifying: $DIST_DIR"

rg -n 'https://chatgpt\.com/backend-api/codex' "$DIST_DIR"/{compact-*.js,reply-*.js,pi-embedded-*.js,auth-profiles-*.js,config-*.js,model-selection-*.js,daemon-cli.js} 2>/dev/null | sed -n '1,20p'
rg -n 'const hasProxyEnv = \["HTTP_PROXY", "HTTPS_PROXY", "ALL_PROXY", "http_proxy", "https_proxy", "all_proxy"\]' "$DIST_DIR"/{compact-*.js,reply-*.js,pi-embedded-*.js} 2>/dev/null | sed -n '1,20p'
rg -n 'transport: options\?\.transport \?\? "sse"' "$DIST_DIR"/{compact-*.js,reply-*.js,pi-embedded-*.js} 2>/dev/null | sed -n '1,20p'
