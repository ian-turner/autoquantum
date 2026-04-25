# MCP Setup

Both Claude Code and OpenCode are configured to use the same set of MCP servers, all rooted under `.mcp/`.

## Goals

- Expose Lean build and LSP tooling through MCP so all agents share one implementation.
- Avoid repo-level overrides for web access, general agents, or compaction behavior.
- Keep model and runtime behavior user-controlled unless Lean tooling needs local wiring.

## Layout

```
.mcp/
  lean-tools/
    server.py              # FastMCP server — exposes build and check_file tools
    run.sh                 # Launcher: sets PATH (elan, homebrew) and runs the Lean MCP server via uv
  latex-tools/
    server.py              # FastMCP server — exposes LaTeX compilation tools
    run.sh                 # Launcher for the LaTeX MCP server via uv
  run-lean-lsp-mcp.sh      # Launcher for lean-lsp-mcp
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
`LEAN_REPL=false`, which:
- Sets `LEAN_PROJECT_PATH` to this repo's `lean/` directory.
- Keeps the launcher's default `LEAN_LOOGLE_LOCAL=true`, so `lean_loogle` uses the local index instead of the hosted service.
- Biases the agent toward core proof state, search, and interactive proof tools (see AGENTS.md for full list).
- Prefers an installed `lean-lsp-mcp` binary and falls back to `uvx lean-lsp-mcp`.

Note: `lean_lsp` is registered in `.claude/settings.json` and is available to both Claude Code and OpenCode agents.

## Agent instructions

See the **MCP Tools** section in `AGENTS.md` for how agents should use these tools when writing or verifying Lean code.

## OpenCode-specific configuration (`opencode.json`)

OpenCode reads its project config from `opencode.json` (project root), not from `.claude/settings.json`. The configuration is now **canonical** (no runtime generation) and does not include a default model.

### Key Settings

| Setting | Value | Reason |
|---------|-------|--------|
| `mcp.lean.timeout` | 180 000 ms | `lean_check_file` takes 60–180 s; 15 s (original) caused immediate timeout errors |
| `mcp.lean_lsp.timeout` | 120 000 ms | Cold-start LSP queries can exceed 60 s (original) |
| `mcp.lean_lsp.command` | `LEAN_REPL=false .mcp/run-lean-lsp-mcp.sh` | Keep REPL noise off while allowing the launcher default local Loogle index |
| `plugin` | `.opencode/plugins/lean-tools.js` | Custom tools and post-edit hook (see below) |

### Model Selection

The `model` field is omitted from `opencode.json`. Instead, specify the model via the `--model` flag when running OpenCode sessions:

```bash
opencode run --model deepseek/deepseek-reasoner "Your task here"
```

or when attaching to a running server:

```bash
opencode run --attach http://localhost:4096 --model anthropic/claude-3-5-sonnet "Your task here"
```
- `OPENCODE_HOST`, `OPENCODE_PORT`: Server binding

**Important:** OpenCode does **not** read `AGENTS.md` or `CLAUDE.md` automatically. Agent instructions for OpenCode sessions must be placed in `.opencode/rules/` (markdown files, auto-loaded into every session context).

## OpenCode rules (`.opencode/rules/`)

Rules are split into two layers:

**Layer 1 — Common rules (auto-loaded into every session):**

| File | Contents |
|------|----------|
| `project-overview.md` | Project layout, key files, build commands, agent roster and how they relate *(to be created)* |
| `lean-workflow.md` | Tool reference table, decision tree, mandatory iterative workflow, file-path format guidance, stop conditions |
| `lean-proof-patterns.md` | Tensor-product proof patterns (Patterns 1–4), `onQubit`/`permuteGate` algebra notes, circuit decomposition patterns, pitfall table |

**Layer 2 — Agent-specific instructions (inlined into each agent's `prompt` field in `opencode.json`):**

| File | Agent | Contents |
|------|-------|----------|
| `agents/build.md` | `build` | Project engineering guidance, delegation patterns, cross-cutting change conventions |
| `agents/proof-writer.md` | `proof-writer` | Goal-scoped Lean proof workflow for `Goals/` + `Solutions/`, with mandatory comparator verification hook |
| `agents/reading.md` | `reading` | arXiv/PDF workflow, theorem extraction protocol, notes format, Lean skeleton conventions |
| `agents/latex-writer.md` | `latex-writer` | Lean-to-LaTeX translation conventions, document structure, PDF compilation workflow |

Files in `.opencode/rules/agents/` are the canonical editable source. The `prompt` field in `opencode.json` for each agent is kept in sync with the corresponding file's contents.

## OpenCode plugin (`.opencode/plugins/lean-tools.js`)

Registered via `"plugin": [".opencode/plugins/lean-tools.js"]` in `opencode.json`.

Provides four custom tools and three hooks:

| Name | Type | Purpose |
|------|------|---------|
| `lean_proof_step` | tool | Resolves a Lean file path (any format) to absolute and formats the exact arguments for `lean_lsp_lean_multi_attempt` |
| `lean_find_sorry` | tool | Scans a file for `sorry` occurrences and returns each with 3 lines of context and `>>>` markers |
| `lean_goal_context` | tool | Loads a comparator goal contract from `lean/Goals/<Stem>.lean` and shows the paired `lean/Solutions/<Stem>.lean` target |
| `verify_comparator_goal` | tool | Manually runs `scripts/verify_comparator.py --goal <Stem>` and returns the transcript |
| `chat.message` | hook | Tracks the requested `goal=<Stem>` value for `@proof-writer` sessions from the incoming prompt text |
| `event` + `session.idle` | hook | Mandatory post-response comparator run for `@proof-writer` sessions; shows a toast on pass/fail or missing goal |
| `tool.execute.after` | hook | Best-effort: appends a `lean_lsp_lean_diagnostic_messages` reminder after any `.lean` file edit |

**Diagnostic:** If `lean_lsp_lean_goal` and `lean_lsp_lean_multi_attempt` are not being used, check that MCP servers are connected (`opencode mcp list`) and that timeouts are not hitting. The original 15 s `lean` timeout was the root cause of DeepSeek skipping all interactive proof tools.

### Proof-writer invocation

The `proof-writer` agent is goal-scoped. Pass the goal stem directly in the prompt:

```text
@proof-writer goal=Comm
@proof-writer goal: HPlusCorrect
```

The plugin tracks that goal from the prompt and runs comparator automatically whenever the `proof-writer` session returns to idle, regardless of whether the agent chose to call any verification tool itself.
