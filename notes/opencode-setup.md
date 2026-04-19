# OpenCode Setup

This repo now keeps the OpenCode setup minimal: repo-local config only wires in Lean theorem-proving tools and leaves general OpenCode behavior to the user's own defaults.

## Goals

- Expose useful Lean-local tooling for theorem proving.
- Avoid repo-level overrides for web access, general agents, or compaction behavior.
- Keep model and runtime behavior user-controlled unless Lean tooling needs local wiring.

## Layout

- `opencode.json` only enables the local `lean_lsp` MCP server.
- `.opencode/tools/lean.ts` adds fixed Lean commands as custom tools: `lean_build` for `lake build` and `lean_check_file` for single-file `lake env lean` checks.
- `.opencode/bin/run-lean-lsp-mcp.sh` launches `lean-lsp-mcp` with `LEAN_PROJECT_PATH` resolved to this repo's `lean/` directory and a defensive PATH setup for common local binary locations. It prefers an installed `lean-lsp-mcp` executable and falls back to `uvx lean-lsp-mcp`.

## Notes

- `.opencode/package.json` declares the `@opencode-ai/plugin` helper needed by the local custom tools. OpenCode should run `bun install` for these local dependencies at startup.
- The Lean MCP launcher disables the heaviest remote-search tools by default and biases the agent toward `lean_goal`, diagnostics, file outline, and local search first.
- `mcp.lean_lsp` is enabled now that the local runtime has been installed. During tmux startup debugging on April 19, 2026, OpenCode logs showed that the earlier failure path was `uvx: not found`; that was fixed by installing `uv` and `lean-lsp-mcp` and by making the launcher prefer the installed `lean-lsp-mcp` executable.
- As of April 19, 2026, repo-local OpenCode config no longer overrides web permissions, compaction policy, or subagent definitions; those now fall back to the user's standard OpenCode configuration.
