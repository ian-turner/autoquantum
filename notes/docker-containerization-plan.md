# Docker Containerization Plan for AutoQuantum

**Status**: ✅ **Implemented and verified** (2025‑04‑20)

All steps have been completed. The container runs OpenCode server with MCP tools `lean` and `lean_lsp` fully functional. Lean builds succeed inside container; host can connect via `opencode --hostname localhost --port 4096`.

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
2. **Lean 4.29.0** via elan (`elan toolchain install leanprover/lean4:v4.29.0`)
3. **Mathlib v4.29.0** – fetched via `lake update`; `.olean` cache stored in a Docker volume.
4. **MCP server dependencies** – Python 3, `uv`, `mcp>=1.0.0`, `lean-lsp-mcp` (via npm or uvx).
5. **Git, bash, coreutils** – for standard operations.
6. **Non‑root user** (`opencode`) with UID/GID matching the host user (501:20) to preserve file ownership.

### Workspace Layout
```
/workspace
├── autoquantum/          # Mounted from host (─v $(pwd):/workspace)
│   ├── lean/
│   ├── .mcp/
│   ├── notes/
│   └── …
├── .elan/                # Persistent volume for elan toolchains
└── .cache/lean/         # Persistent volume for Mathlib .oleans
```

### Sync Strategy
- **Git commits** made inside the container write directly to the host’s `.git/` directory (instant sync).
- **File edits** via OpenCode’s `edit` tool modify the mounted workspace immediately.
- **Permissions** – container user matches host UID/GID so created files belong to the host user.
- **Git credentials** – mount `~/.gitconfig` (read‑only) to inherit user name/email; SSH keys are not mounted (remote operations handled by host).

## Decisions

### 1. Container Scope
**AutoQuantum‑specific image** – pre‑install Lean 4.29.0, Mathlib v4.29.0, and all MCP dependencies. This ensures reproducibility and fast startup; image size (~1–2 GB) is acceptable.

### 2. Git Credentials
- **Do not mount SSH keys** – keep container simple and secure.
- **Mount `~/.gitconfig` (read‑only)** to inherit user’s name and email.
- **Agent authorship** – the OpenCode agent will add itself as a co‑author (`Co‑authored‑by:`) in commit messages, as specified in AGENTS.md.
- **Push/pull** – if remote operations are needed, the host’s Git must handle them (container only makes commits to the mounted workspace).

### 3. Development Workflow
**Use Docker Compose** – define volumes, environment, and services in `docker‑compose.yml`. Provides a clear, extensible configuration that can be used both interactively and in CI.

### 4. CI Integration
**Design for CI** – the same image will be usable in GitHub Actions (non‑interactive, `lake build`). However, CI‑specific optimizations (e.g., caching strategy) can be deferred until needed.

## Implementation Steps

### 1. Dockerfile
Create `Dockerfile` at repo root with:
- Base: `ubuntu:22.04` (or `debian:stable`)
- Install: curl, git, python3, python3‑pip, nodejs, npm, cargo (if needed)
- Install elan, set default toolchain to `leanprover/lean4:v4.29.0`
- Install `uv` globally, then `mcp>=1.0.0`
- Install `lean‑lsp‑mcp` via `npm install -g lean‑lsp‑mcp`
- Install OpenCode CLI globally (`npm install -g @anomalyco/opencode`)
- Create user `opencode` with UID 501, GID 20 (match host)
- Set working directory `/workspace`
- Entrypoint: `opencode serve --hostname 0.0.0.0 --port 4096` (headless HTTP server)

### 2. Docker Compose Configuration
Create `docker‑compose.yml` with:
- Service `opencode` using the built image
- Mount host’s `autoquantum/` directory as `/workspace/autoquantum`
- Mount host’s `~/.gitconfig` (read‑only) if present
- Define named volumes for `elan‑cache` (`.elan`) and `mathlib‑cache` (`.cache/lean`)
- Set environment variables: `LEAN_PROJECT_PATH=/workspace/autoquantum/lean`, `LEAN_TOOLS_REPO_ROOT=/workspace/autoquantum`
  - Optionally, set `OPENCODE_SERVER_PASSWORD` (and `OPENCODE_SERVER_USERNAME`) to protect the server with HTTP basic auth.
- Expose port `4096:4096` (container server → host)
- Optionally, include a health‑check that runs `lake build AutoQuantum`

### 3. Helper Scripts
- **`scripts/docker‑build.sh`** – builds the image, tags it `opencode‑autoquantum:latest`
- **`scripts/docker‑compose‑up.sh`** – starts the OpenCode server in the background (`docker‑compose up -d`)
- **`scripts/docker‑compose‑connect.sh`** – launches `opencode --hostname localhost --port 4096` on the host (requires OpenCode installed on host)
- **`.mcp/` script updates** – ensure `run.sh` and `run‑lean‑lsp‑mcp.sh` work inside container (they already use relative paths; may need PATH adjustments)

### 4. OpenCode Configuration
- `opencode.json` unchanged – MCP server commands execute inside container.
- MCP servers (`lean` and `lean_lsp`) are launched via the same `.mcp/` scripts (now running inside container).

## Expected Workflow

```bash
# Build the image once
docker-compose build

# Start the OpenCode server in the background
docker-compose up -d

# On the host, connect to the container’s OpenCode server
opencode --hostname localhost --port 4096
# → OpenCode TUI starts on the host, but all tool execution happens inside the container

# Through the TUI, the agent can:
#   – edit files (host sees changes immediately via mounted volume)
#   – run lake build (uses cached Mathlib .oleans inside container)
#   – commit (using host’s Git name/email; agent adds itself as co‑author)

# Stop the container when done
docker-compose down
```

## Next Steps
1. Write `Dockerfile` following the above spec.
2. Create `docker‑compose.yml` with volume definitions.
3. Write helper scripts (`scripts/docker‑build.sh`, `scripts/docker‑compose‑up.sh`, `scripts/docker‑compose‑connect.sh`).
4. Test that `lake build AutoQuantum` works inside container.
5. Test that OpenCode’s MCP tools (`lean_build`, `lean_lsp_*`) work.
6. Update `notes/home.md` to link to this plan and add a “Container Usage” section.
7. Optionally, add a pre‑commit hook that warns if Lean files are edited outside the container.

## Risks & Mitigations
- **Performance** – mounting the entire repo as a volume may cause I/O overhead on macOS/Windows; use `cached` mount option.
- **Cache staleness** – if Mathlib version changes, need to prune the cache volume.
- **User‑ID mismatch** – if host UID/GID differs, container may not have write permission; script should detect and adjust.