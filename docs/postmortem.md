# Postmortem

## Symptoms

- `openai-codex/gpt-5.4` failed in OpenClaw with `fetch failed`
- Feishu / gateway main session later returned repeated Codex upstream:
  - `server_error`
  - new session often worked
  - existing main session continuation often failed

## Root Causes

### 1. Codex base URL drift

Some installed OpenClaw runtime files still defaulted Codex transport to:

- `https://chatgpt.com/backend-api`

But the working Codex responses path is:

- `https://chatgpt.com/backend-api/codex`

### 2. Proxy env existed, but Undici still direct-connected

OpenClaw's runtime timeout helper only preserved proxy behavior if the global dispatcher was already an `EnvHttpProxyAgent`.

In practice this meant:

- proxy env could be present
- runtime still used plain `Agent`
- Codex fetches direct-connected
- requests failed with `TypeError: fetch failed`

### 3. Gateway/main-session continuation was fragile

After the transport was made reachable, long-lived gateway/main-session Codex turns could still produce upstream `server_error` while fresh/local turns succeeded.

The working mitigation was to prefer `sse` over `auto` for Codex, avoiding the websocket-first continuation path.

## Durable Fix

Patch the installed runtime so that:

1. Codex base URL points at `/backend-api/codex`
2. Proxy env forces `EnvHttpProxyAgent`
3. Codex default transport becomes `sse`

