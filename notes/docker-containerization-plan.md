# Docker Containerization Plan for AutoQuantum

**Status**: ✅ **Implemented and verified** (2025‑04‑20)

All steps have been completed. The container runs OpenCode server with MCP tools `lean` and `lean_lsp` fully functional. Lean builds succeed inside container; host can connect via `opencode attach http://localhost:4096`.

## Goal
Create a fully reproducible, sandboxed environment where the **entire OpenCode session** (agent + Lean toolchain + MCP servers) runs inside a Docker container. The host only interacts with the container via mounted directories and Git operations; all file edits, builds, and proof verification happen in isolation.

## Why
- **Reproducibility** – anyone can run the same container and get identical Lean compilation results.
- **Isolation** – agent cannot affect the host beyond the mounted workspace.
- **Toolchain consistency** – eliminates “works on my machine” issues.
- **CI readiness** – same container can be used in GitHub Actions for automated proof checking.

## Prerequisites

- **Host machine** must have Docker and Docker Compose installed.
- **Host machine** must have OpenCode CLI installed (`npm install -g @anomalyco/opencode`) to connect to the container’s server (the TUI runs on the host).
- **Git** installed on host (for commits outside the container).

## Architecture

### Container Contents
1. **OpenCode CLI** – `npm install -g @anomalyco/opencode` (includes `opencode serve` command)
2. **Minimal base image** – no Lean toolchain or Mathlib cache is baked into the image.
3. **Dedicated cache-warmer service** – runs `bootstrap-lean.sh` with writable volume mounts to install `elan`, the Lean toolchain, and the Lake package tree.
4. **Main OpenCode service** – mounts those warmed cache volumes read-only and never runs the bootstrap script itself.
5. **MCP server dependencies** – Python 3, `uv`, `mcp>=1.0.0`, `lean-lsp-mcp` (via npm or uvx).
6. **Git, bash, coreutils** – for standard operations.
7. **Non‑root user** (`opencode`) with UID/GID matching the host user (501:20) to preserve file ownership.

### Workspace Layout
```
/workspace
├── autoquantum/          # Mounted from host (─v $(pwd):/workspace)
│   ├── lean/
│   ├── .mcp/
│   ├── notes/
│   └── …
├── .elan/                # Persistent volume, warmed by cache-warmer
└── autoquantum/lean/.lake/packages  # Persistent volume, warmed by cache-warmer
```

### Sync Strategy
- **Git commits** made inside the container write directly to the host’s `.git/` directory (instant sync).
- **File edits** via OpenCode’s `edit` tool modify the mounted workspace immediately.
- **Permissions** – container user matches host UID/GID so created files belong to the host user.
- **Git credentials** – mount `~/.gitconfig` (read‑only) to inherit user name/email; SSH keys are not mounted (remote operations handled by host).

## Decisions

### 1. Container Scope
**AutoQuantum‑specific image** – pre-install the OpenCode/MCP runtime in the image, keep the image itself lean, and use a separate compose service to warm the shared Lean volumes before the main service starts. The main `opencode` container mounts those volumes read-only.

### 2. Git Credentials
- **Do not mount SSH keys** – keep container simple and secure.
- **Mount `~/.gitconfig` (read‑only)** to inherit user’s name and email.
- **Agent authorship** – the OpenCode agent will add itself as a co‑author (`Co‑authored‑by:`) in commit messages, as specified in AGENTS.md.
- **Push/pull** – if remote operations are needed, the host’s Git must handle them (container only makes commits to the mounted workspace).

### 3. Development Workflow
**Use Docker Compose** – define volumes, environment, and services in `docker‑compose.yml`. Provides a clear, extensible configuration that can be used both interactively and in CI.

### 4. CI Integration
**Design for CI** – the same image will be usable in GitHub Actions (non‑interactive, `lake build`). However, CI‑specific optimizations (e.g., caching strategy) can be deferred until needed.

## Implementation

All steps are complete. The `Dockerfile`, `docker-compose.yml`, and `bootstrap-lean.sh` at the repo root implement the architecture above. MCP servers (`lean_tools` and `lean_lsp`) run inside the container via `.mcp/` scripts; `opencode.json` is unchanged.

## Workflow

```bash
docker compose build                        # Build the image (once)
docker compose up -d                        # Start the OpenCode server
opencode attach http://localhost:4096       # Connect from the host
docker compose down                         # Stop when done
```

The container mounts the repo as a volume, so file edits and git commits are immediately visible on the host.

## Operational Notes
- **Dedicated prewarming** — `bootstrap-lean.sh` now runs only inside the `cache-warmer` compose service. `serve.sh` and `web.sh` only validate that the read-only caches are present.
- **Read-only runtime caches** — the main `opencode` service mounts `autoquantum-elan-cache` and `autoquantum-mathlib-cache` read-only. If they are missing or stale, rerun the cache-warmer or prune and repopulate the volumes.
- **Bootstrap PATH handling** — `bootstrap-lean.sh` exports `~/.elan/bin` itself before invoking `lake`; do not rely on profile side effects alone, because the container entrypoints run non-login shells.
- **Cache staleness** — if the Mathlib version changes, prune the named volumes (`autoquantum-elan-cache`, `autoquantum-mathlib-cache`) and rebuild.
- **UID/GID** — the compose file hardcodes `user: “501:20”`. If your host UID/GID differs, override in a `docker-compose.override.yml`.
