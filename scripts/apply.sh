#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BACKUP_STAMP="$(date +%Y%m%d-%H%M%S)"
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
BACKUP_DIR="$ROOT_DIR/backups/$BACKUP_STAMP"
mkdir -p "$BACKUP_DIR"

copy_backup() {
  local file="$1"
  cp "$file" "$BACKUP_DIR/$(basename "$file")"
}

replace_in_file() {
  local file="$1"
  local search="$2"
  local replace="$3"
  perl -0pi -e "s/\Q$search\E/$replace/g" "$file"
}

patch_proxy_logic() {
  local file="$1"
  local search='const kind = resolveDispatcherKind(dispatcher);
	if (kind === "unsupported") return;'
  local replace='const hasProxyEnv = ["HTTP_PROXY", "HTTPS_PROXY", "ALL_PROXY", "http_proxy", "https_proxy", "all_proxy"].some((key) => typeof process.env[key] === "string" && process.env[key].trim().length > 0);
	const kind = hasProxyEnv ? "env-proxy" : resolveDispatcherKind(dispatcher);
	if (kind === "unsupported") return;'
  replace_in_file "$file" "$search" "$replace"
}

patch_transport_logic() {
  local file="$1"
  replace_in_file "$file" 'transport: options?.transport ?? "auto"' 'transport: options?.transport ?? "sse"'
}

patch_codex_baseurl() {
  local file="$1"
  replace_in_file "$file" 'https://chatgpt.com/backend-api"' 'https://chatgpt.com/backend-api/codex"'
  replace_in_file "$file" '^https?:\/\/chatgpt\.com\/backend-api\/?$' '^https?:\/\/chatgpt\.com\/backend-api(?:\/codex)?\/?$'
}

gather_files() {
  find "$DIST_DIR" -maxdepth 1 -type f \( \
    -name 'compact-*.js' -o \
    -name 'reply-*.js' -o \
    -name 'pi-embedded-*.js' -o \
    -name 'auth-profiles-*.js' -o \
    -name 'config-*.js' -o \
    -name 'model-selection-*.js' -o \
    -name 'daemon-cli.js' \
  \) | sort
}

mapfile -t FILES < <(gather_files)

if [[ "${#FILES[@]}" -eq 0 ]]; then
  echo "No matching dist files found under: $DIST_DIR" >&2
  exit 1
fi

for file in "${FILES[@]}"; do
  copy_backup "$file"
done

for file in "${FILES[@]}"; do
  patch_codex_baseurl "$file"
done

for file in "$DIST_DIR"/compact-*.js "$DIST_DIR"/reply-*.js "$DIST_DIR"/pi-embedded-*.js; do
  [[ -f "$file" ]] || continue
  patch_proxy_logic "$file"
  patch_transport_logic "$file"
done

echo "Patched OpenClaw runtime:"
echo "  dist:   $DIST_DIR"
echo "  backup: $BACKUP_DIR"

if [[ "$RESTART" -eq 1 ]]; then
  openclaw gateway restart
fi
