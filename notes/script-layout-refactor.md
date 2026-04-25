# Script Layout Refactor

As of April 25, 2026, repository shell scripts live under `scripts/` instead of being split between the repo root and `.mcp/`.

## Layout

- Runtime/container scripts live at `scripts/entrypoint.sh`, `scripts/warm-cache.sh`, and `scripts/bootstrap-lean.sh`.
- Comparator setup remains at `scripts/setup_comparator.sh`.
- MCP launcher scripts live at `scripts/mcp/` and point back to the Python server implementations under `.mcp/`.

## Why

- The repo root stays focused on project config and source directories.
- Docker and OpenCode entrypoints now follow a single script convention.
- `.mcp/` now contains MCP server code, while `scripts/mcp/` contains shell launchers.

## Maintenance Rule

When adding a new shell script, place it under `scripts/` and update any Docker, Compose, OpenCode, or documentation references in the same change.
