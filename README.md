# openclaw-codex-runtime-fix

Patch kit for recurring OpenClaw + OpenAI Codex runtime regressions.

Current version: `v0.1.0`

This repo exists for one reason: OpenClaw upgrades can overwrite local runtime fixes, and the same Codex failures can come back.

GitHub: <https://github.com/orime/openclaw-codex-runtime-fix>
Raw bootstrap: <https://raw.githubusercontent.com/orime/openclaw-codex-runtime-fix/main/scripts/bootstrap-from-github.sh>

## English

### What It Fixes

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

### Repo Layout

- `scripts/apply.sh`: apply the runtime patch
- `scripts/verify.sh`: verify patched patterns are present
- `scripts/revert.sh`: restore the latest backup
- `docs/postmortem.md`: concise write-up of the incident and root causes
- `docs/upstream-issue-openclaw.md`: ready-to-file upstream issue text
- `docs/ai-operator-prompt.md`: prompt for another AI assistant to operate the repo

### Usage

Clone and run:

```bash
git clone https://github.com/orime/openclaw-codex-runtime-fix.git
cd openclaw-codex-runtime-fix
./scripts/apply.sh --restart
```

Remote one-liner:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/orime/openclaw-codex-runtime-fix/main/scripts/bootstrap-from-github.sh) --restart
```

Ask another AI to operate it:

- Read `README.md`
- Or read `docs/ai-operator-prompt.md`
- Then clone the repo and run `scripts/apply.sh`, `scripts/verify.sh`, or `scripts/revert.sh` as needed

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

### Target Runtime

By default the scripts try to patch one of:

1. The global `openclaw` install discovered from `command -v openclaw`
2. The bundled QClaw runtime at:
   - `/Applications/QClaw.app/Contents/Resources/openclaw/node_modules/openclaw/dist`

Override the target explicitly:

```bash
OPENCLAW_DIST_DIR=/path/to/openclaw/dist ./scripts/apply.sh --restart
```

### Notes

- This is an operational patch kit, not an official upstream release.
- Future OpenClaw updates may change hashed file names or surrounding code shape.
- The scripts make timestamped backups before editing files.

## 中文

### 这个仓库解决什么

这个仓库主要沉淀 3 类 OpenClaw + Codex 的运行时问题：

1. Codex 默认 base URL 错了
   - 从 `https://chatgpt.com/backend-api`
   - 改到 `https://chatgpt.com/backend-api/codex`

2. 明明配置了代理，但 Undici 实际没走代理
   - 只要存在 `HTTP_PROXY` / `HTTPS_PROXY` / `ALL_PROXY`
   - 就强制让 Codex 请求走 `EnvHttpProxyAgent`
   - 避免运行时直连后报 `fetch failed`

3. Gateway 主会话里 Codex 容易连续报上游 `server_error`
   - 把 Codex 默认 transport 从 `auto` 改成 `sse`
   - 避开更脆弱的 websocket-first 续写路径

### 怎么用

本地 clone 后执行：

```bash
git clone https://github.com/orime/openclaw-codex-runtime-fix.git
cd openclaw-codex-runtime-fix
./scripts/apply.sh --restart
```

远程单行执行：

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/orime/openclaw-codex-runtime-fix/main/scripts/bootstrap-from-github.sh) --restart
```

交给另一个 AI 代操作：

- 让它先阅读 `README.md`
- 或直接阅读 `docs/ai-operator-prompt.md`
- 再让它执行 `scripts/apply.sh` / `scripts/verify.sh` / `scripts/revert.sh`

打补丁：

```bash
./scripts/apply.sh --restart
```

校验：

```bash
./scripts/verify.sh
```

回滚：

```bash
./scripts/revert.sh --restart
```

### 适合什么场景

- OpenClaw 升级后把本地修复覆盖了
- `openai-codex/gpt-5.4` 又开始 `fetch failed`
- 主会话反复报 Codex `server_error`
- 想把这次事故沉淀成可以复用、可开源的补丁包
