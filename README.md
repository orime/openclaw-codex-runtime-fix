# openclaw-codex-runtime-fix

Patch kit for recurring OpenClaw + OpenAI Codex runtime regressions.

This repo exists for one reason: OpenClaw upgrades can overwrite local runtime fixes, and the same Codex failures can come back.

## What It Fixes

This kit patches three classes of issues seen in installed OpenClaw runtimes:

1. Wrong Codex base URL
   - Fixes Codex transport defaults from `https://chatgpt.com/backend-api`
   - To `https://chatgpt.com/backend-api/codex`

2. Proxy env not actually applied to Undici
   - If `HTTP_PROXY` / `HTTPS_PROXY` / `ALL_PROXY` exist, force Codex HTTP traffic onto `EnvHttpProxyAgent`
   - Prevents the runtime from silently direct-connecting and failing with `fetch failed`

3. Sticky Codex session failures on gateway/main session
   - Changes the default Codex transport from `auto` to `sse`
   - Avoids the more fragile websocket-first continuation path that can repeatedly hit upstream `server_error` on long-lived gateway sessions

## Repo Layout

- `scripts/apply.sh`: apply the runtime patch
- `scripts/verify.sh`: verify patched patterns are present
- `scripts/revert.sh`: restore the latest backup
- `docs/postmortem.md`: concise write-up of the incident and root causes

## Usage

Apply patch:

```bash
./scripts/apply.sh --restart
```

Verify patch:

```bash
./scripts/verify.sh
```

Revert patch:

```bash
./scripts/revert.sh --restart
```

## Target Runtime

By default the scripts try to patch one of:

1. The global `openclaw` install discovered from `command -v openclaw`
2. The bundled QClaw runtime at:
   - `/Applications/QClaw.app/Contents/Resources/openclaw/node_modules/openclaw/dist`

You can override the target:

```bash
OPENCLAW_DIST_DIR=/path/to/openclaw/dist ./scripts/apply.sh --restart
```

## Notes

- This is an operational patch kit, not an official upstream release.
- Future OpenClaw updates may change hashed file names or surrounding code shape.
- The scripts make timestamped backups before editing files.

## Suggested Open Source Flow

If you want to publish this:

```bash
cd /Users/orime/openclaw-codex-runtime-fix
git add .
git commit -m "Add OpenClaw Codex runtime patch kit"
gh repo create openclaw-codex-runtime-fix --public --source=. --push
```

