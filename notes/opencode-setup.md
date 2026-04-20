# MCP Setup

Both Claude Code and OpenCode are configured to use the same set of MCP servers, defined under `.mcp/`.

## Goals

- Expose Lean build and LSP tooling through MCP so all agents share one implementation.
- Avoid repo-level overrides for web access, general agents, or compaction behavior.
- Keep model and runtime behavior user-controlled unless Lean tooling needs local wiring.

## Layout

```
.mcp/
  lean-tools/
    server.py          # FastMCP server — exposes build and check_file tools
    run.sh             # Launcher: sets PATH (elan, homebrew) and runs server.py via uv
  run-lean-lsp-mcp.sh  # Launcher for lean-lsp-mcp LSP server
```

### `lean` server

Registered as `mcp.lean` in `opencode.json` and `mcpServers.lean_tools` in `.claude/settings.json`.

Provides three tools:

| Tool | What it runs |
|------|-------------|
| `build(target="AutoQuantum")` | `lake build <target>` in `lean/` |
| `check_file(file="AutoQuantum/Core/Gate.lean")` | `lake env lean <file>` in `lean/` |
| `sorry_count()` | `grep -r sorry lean/AutoQuantum` — count remaining sorries |

Implemented in Python (`mcp>=1.0.0`, FastMCP). Runs via `uv run` — no separate install needed.

### `lean_lsp` server

Registered as `mcp.lean_lsp` in `opencode.json`. Launched by `.mcp/run-lean-lsp-mcp.sh`, which:
- Sets `LEAN_PROJECT_PATH` to this repo's `lean/` directory.
- Disables the heaviest remote-search tools by default.
  - Biases the agent toward core proof state, search, and interactive proof tools (see AGENTS.md for full list).
- Prefers an installed `lean-lsp-mcp` binary and falls back to `uvx lean-lsp-mcp`.

Note: `lean_lsp` is registered in `.claude/settings.json` and is available to both Claude Code and OpenCode agents.

## Agent instructions

See the **MCP Tools** section in `AGENTS.md` for how agents should use these tools when writing or verifying Lean code.
