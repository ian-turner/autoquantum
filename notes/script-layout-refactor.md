# Script Layout Refactor

As of April 25, 2026, runtime shell scripts live under `scripts/`, while MCP launcher scripts live under `.mcp/`.

## Layout

- Runtime/container scripts live at `scripts/entrypoint.sh`, `scripts/warm-cache.sh`, and `scripts/bootstrap-lean.sh`.
- Comparator setup remains at `scripts/setup_comparator.sh`.
- MCP launcher scripts live alongside their server implementations under `.mcp/`.

## Why

- The repo root stays focused on project config and source directories.
- Docker/runtime entrypoints now follow a single `scripts/` convention.
- `.mcp/` owns both MCP server code and the launcher scripts that start it.

## Maintenance Rule

When adding a new runtime or bootstrap shell script, place it under `scripts/`. When adding an MCP launcher, keep it under `.mcp/`. Update any Docker, Compose, OpenCode, or documentation references in the same change.
