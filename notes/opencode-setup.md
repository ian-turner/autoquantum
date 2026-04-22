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

Registered as `mcp.lean_lsp` in `opencode.json`. Launched by `.mcp/run-lean-lsp-mcp.sh`, with
`LEAN_LOOGLE_LOCAL=false LEAN_REPL=false`, which:
- Sets `LEAN_PROJECT_PATH` to this repo's `lean/` directory.
- Disables the heaviest remote-search tools by default.
  - Biases the agent toward core proof state, search, and interactive proof tools (see AGENTS.md for full list).
- Prefers an installed `lean-lsp-mcp` binary and falls back to `uvx lean-lsp-mcp`.

Note: `lean_lsp` is registered in `.claude/settings.json` and is available to both Claude Code and OpenCode agents.

## Agent instructions

See the **MCP Tools** section in `AGENTS.md` for how agents should use these tools when writing or verifying Lean code.

## OpenCode-specific configuration (`opencode.json`)

OpenCode reads its project config from `opencode.json` (project root), not from `.claude/settings.json`. The configuration is now **generated at runtime** from `opencode.json.template` using environment variable substitution.

### Template System

- `opencode.json.template` contains placeholders (e.g., `${MODEL}`) that are replaced with environment variables at container startup.
- The entrypoint script runs `envsubst '${MODEL}'` (with explicit variable list) to generate the final `opencode.json`, preserving the `$schema` field.
- Generated `opencode.json` is excluded from Git (see `.gitignore`).

### Key Settings

| Setting | Template Value | Reason |
|---------|---------------|--------|
| `model` | `${MODEL}` | Model specified via `MODEL` environment variable (default: deepseek/deepseek-reasoner) |
| `mcp.lean.timeout` | 180 000 ms | `lean_check_file` takes 60–180 s; 15 s (original) caused immediate timeout errors |
| `mcp.lean_lsp.timeout` | 120 000 ms | Cold-start LSP queries can exceed 60 s (original) |
| `mcp.lean_lsp.command` | `LEAN_LOOGLE_LOCAL=false LEAN_REPL=false .mcp/run-lean-lsp-mcp.sh` | Avoid local loogle initialization and missing-REPL startup noise |
| `plugin` | `.opencode/plugins/lean-tools.js` | Custom tools and post-edit hook (see below) |

### Runtime Configuration

All configuration is driven by environment variables defined in `.env.template`. Key variables:

- `MODEL`: LLM model (provider/model format)
- `PROJECT_ROOT`: Host path to project directory
- `LEAN_PROJECT_PATH`: Path to Lean project inside container
- `LEAN_TARGET`: Lean library target name
- `OPENCODE_HOST`, `OPENCODE_PORT`: Server binding

**Important:** OpenCode does **not** read `AGENTS.md` or `CLAUDE.md` automatically. Agent instructions for OpenCode sessions must be placed in `.opencode/rules/` (markdown files, auto-loaded into every session context).

## OpenCode rules (`.opencode/rules/`)

| File | Contents |
|------|----------|
| `lean-workflow.md` | Tool reference table, decision tree, mandatory iterative workflow, file-path format guidance, stop conditions |
| `lean-proof-patterns.md` | Tensor-product proof patterns (Patterns 1–4), `onQubit`/`permuteGate` algebra notes, circuit decomposition patterns, pitfall table |

## OpenCode plugin (`.opencode/plugins/lean-tools.js`)

Registered via `"plugin": [".opencode/plugins/lean-tools.js"]` in `opencode.json`.

Provides two custom tools and one hook:

| Name | Type | Purpose |
|------|------|---------|
| `lean_proof_step` | tool | Resolves a Lean file path (any format) to absolute and formats the exact arguments for `lean_lsp_lean_multi_attempt` |
| `lean_find_sorry` | tool | Scans a file for `sorry` occurrences and returns each with 3 lines of context and `>>>` markers |
| `tool.execute.after` | hook | Best-effort: appends a `lean_lsp_lean_diagnostic_messages` reminder after any `.lean` file edit |

**Diagnostic:** If `lean_lsp_lean_goal` and `lean_lsp_lean_multi_attempt` are not being used, check that MCP servers are connected (`opencode mcp list`) and that timeouts are not hitting. The original 15 s `lean` timeout was the root cause of DeepSeek skipping all interactive proof tools.
