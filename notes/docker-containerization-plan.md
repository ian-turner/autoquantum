# Docker Setup

**Status**: Implemented (2026-04-20)

Docker container runs an OpenCode server with the full Lean toolchain and MCP servers (`lean`, `lean_lsp`, `latex`).

## Workflow

```bash
docker compose build                        # Build the image (once)
docker compose up -d                        # Start the OpenCode server
opencode attach http://localhost:4096       # Connect from the host
docker compose down                         # Stop when done
```

## Operational Notes

- **Cache volumes** — `autoquantum-elan-cache`, `autoquantum-mathlib-cache`, `autoquantum-comparator-cache` persist across restarts. If Mathlib version or comparator refs change, prune these volumes and rebuild.
- **Cache-warmer** — the `cache-warmer` compose service seeds shared Elan / Lake caches before the main service starts. The main container also falls back to running `scripts/bootstrap-lean.sh` directly if the shared caches are missing.
- **Mutable Lake packages** — the main service mounts the warmed Lake seed read-only and copies it into a per-container writable anonymous volume at `.lake/packages`, because `lake build` mutates dependency directories.
- **UID/GID** — compose hardcodes `user: "501:20"`. If your host UID/GID differs, override in `docker-compose.override.yml`.
- **Bash recursion** — `.bashrc` sources `~/.elan/env` directly; do not source `.profile` from `.bashrc` (causes recursive segfault).
- **Comparator tools** — installed under `/home/opencode/.cache/autoquantum-tools/bin` by `scripts/setup_comparator.sh`; the `cache-warmer` handles this via block-aware `rev` rewriting in `lakefile.toml` (the earlier regex was brittle against intervening TOML fields).
- **Git sync** — container user UID/GID matches host; file edits and commits are immediately visible on the host. SSH keys are not mounted; remote operations must go through the host.
