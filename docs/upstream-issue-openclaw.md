# Proposed Upstream Issue

Title:

`openai-codex runtime can fail due to proxy dispatcher fallback and websocket-first main-session transport`

Body:

```md
## Summary

We hit a recurring set of runtime issues when using `openai-codex/gpt-5.4` through OpenClaw gateway sessions.

The problems appeared in three layers:

1. Some runtime paths still defaulted Codex to `https://chatgpt.com/backend-api` instead of `https://chatgpt.com/backend-api/codex`
2. When proxy env existed, the runtime could still keep Undici on a plain `Agent` instead of `EnvHttpProxyAgent`, leading to `TypeError: fetch failed`
3. Even after connectivity was restored, long-lived gateway/main-session Codex turns were less stable with `transport=auto`, while forcing `sse` was more reliable

## Symptoms

- `openai-codex/gpt-5.4` returned `fetch failed`
- direct/local tests worked after proxy fixes
- long-lived main session turns could still return upstream Codex `server_error`
- fresh/new session could work while the shared gateway main session kept failing

## Findings

### A. Base URL drift

Codex responses should use:

`https://chatgpt.com/backend-api/codex`

but some runtime definitions still behaved as if the old base was the default.

### B. Proxy env was present, but runtime still direct-connected

The runtime timeout helper only preserved proxy behavior if the global dispatcher was already recognized as `EnvHttpProxyAgent`.

In our case:

- proxy env existed
- runtime still used plain `Agent`
- Codex requests direct-connected
- requests failed with `TypeError: fetch failed`

### C. Gateway/main-session transport path was fragile

After fixing connectivity, Codex could still fail with upstream `server_error` specifically on long-lived gateway/main-session turns, while local or fresh turns succeeded.

Forcing Codex default transport to `sse` was more stable than `auto`.

## Repro Shape

- OpenClaw gateway mode
- `openai-codex/gpt-5.4`
- local HTTP proxy configured through env
- long-lived main session (`agent:<id>:main`)

## Suggested Fixes

1. Normalize all Codex runtime paths to `https://chatgpt.com/backend-api/codex`
2. If proxy env is present, prefer `EnvHttpProxyAgent` instead of only preserving it when already active
3. Re-evaluate whether Codex should default to `transport=auto` for gateway/main-session continuations

## Local Mitigation That Worked

- patch Codex base URL to `/backend-api/codex`
- force proxy-env detection to select `EnvHttpProxyAgent`
- change Codex default transport from `auto` to `sse`
```

