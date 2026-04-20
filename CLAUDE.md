# CLAUDE.md

For all agent and AI assistant instructions, see **[AGENTS.md](./AGENTS.md)**.

## Quick Reference

- Lean project root: `lean/`
- Build: `cd lean && lake build`
- Core library: `lean/AutoQuantum/`
- Research notes: `notes/`

## Spawning OpenCode Sessions (Docker)

The Docker container runs an OpenCode server with the full Lean toolchain and MCP servers. Use this when you want to delegate proof work to an OpenCode agent running in the isolated container environment.

**Start the container (if not already running):**
```bash
docker compose up -d
```

**Run a one-shot task in the container:**
```bash
opencode run --attach http://localhost:4096 "Your task here"
```

**Useful flags:**
- `--model provider/model` — specify the model (e.g. `--model anthropic/claude-sonnet-4-6`)
- `--continue` — continue the last session instead of starting fresh
- `--session <id>` — continue a specific session by ID
- `--dir /workspace/autoquantum` — set the working directory on the remote server

**Stop the container when done:**
```bash
docker compose down
```

The container mounts this repo as a volume, so all file edits and git commits made by the OpenCode agent are immediately visible on the host. See `notes/docker-containerization-plan.md` for architecture details.
