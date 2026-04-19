# OpenCode Setup

This repo now keeps the OpenCode setup minimal: repo-local config only wires in Lean theorem-proving tools and leaves general OpenCode behavior to the user's own defaults.

## Goals

- Expose useful Lean-local tooling for theorem proving.
- Avoid repo-level overrides for web access, general agents, or compaction behavior.
- Keep model and runtime behavior user-controlled unless Lean tooling needs local wiring.

## Layout

- `opencode.json` enables two MCP servers:
  - `lean` (`.mcp/lean-tools/run.sh`) provides `lean_build` and `lean_check_file` tools.
  - `lean_lsp` (`.opencode/bin/run-lean-lsp-mcp.sh`) provides LSP-based tools (`lean_lsp_*`).
- The custom TypeScript tools (`.opencode/tools/lean.ts`) have been retired; their functionality is now provided by the `lean` MCP server.
- `.opencode/bin/run-lean-lsp-mcp.sh` launches `lean-lsp-mcp` with `LEAN_PROJECT_PATH` resolved to this repo's `lean/` directory and a defensive PATH setup for common local binary locations. It prefers an installed `lean-lsp-mcp` executable and falls back to `uvx lean-lsp-mcp`.

## Notes

- `.opencode/package.json` declares the `@opencode-ai/plugin` helper needed by the local custom tools (currently unused). OpenCode should run `bun install` for these local dependencies at startup.
- The Lean MCP launcher disables the heaviest remote-search tools by default and biases the agent toward `lean_goal`, diagnostics, file outline, and local search first.
- Both `mcp.lean` (build/check tools) and `mcp.lean_lsp` (LSP tools) are enabled. The `lean` MCP server is implemented in Python and runs via `uv`; the `lean_lsp` server uses the installed `lean-lsp-mcp` executable (or `uvx` fallback).
- The previous `lean_tools` MCP server (with prefixed tool names) is disabled in config; any remaining `lean_tools_*` tools will disappear after OpenCode restart.
- As of April 19, 2026, repo-local OpenCode config no longer overrides web permissions, compaction policy, or subagent definitions; those now fall back to the user's standard OpenCode configuration.
