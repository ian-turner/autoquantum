# AutoQuantum Framework

**Status**: Phases 1–2 complete; Phases 3–5 planned but not started.

Goal: generalize AutoQuantum from a single-project setup into a reusable framework for Lean 4 auto-coding.

## Implemented: Agent System

Four agents are active, defined as `.md` files under `.opencode/agents/` (YAML frontmatter + prompt body). OpenCode loads them automatically.

| Agent | Mode | Purpose |
|-------|------|---------|
| `build` | primary | Highest-permission; project engineering, framework changes, cross-cutting work |
| `plan` | primary (read-only) | Designs proof strategies and multi-agent workflows; does not edit Lean source |
| `read` | primary | Fetches arXiv papers and local PDFs; extracts theorems; drafts Lean skeletons |
| `latex` | primary | Transcribes Lean to LaTeX; compiles PDF via the `latex` MCP server |

A `prove` agent (goal-scoped, with mandatory comparator hook) was also added later. See `proof-writer-comparator-hook.md`.

## Implemented: Tiered Rules Architecture

- **Layer 1 — Common rules** (`.opencode/rules/*.md`, auto-loaded into every session): `project-overview.md`, `lean-workflow.md`, `lean-proof-patterns.md`
- **Layer 2 — Agent-specific rules** (`.opencode/agents/<name>.md`): each agent's instructions live here; edit the file to update, no `opencode.json` sync needed

## Implemented: OpenCode Plugin

`.opencode/plugins/lean-tools.js` provides four custom tools and three hooks. See [MCP Setup](opencode-setup.md) for the full table.

Key decisions:
- Use plain `edit: "allow"` for agents that must write files; scoped edit permissions can silently hide the edit tool
- The `prove` agent's comparator hook is mandatory and runs on `session.idle`, not on file-edit events

## Planned: Phases 3–5

- **Phase 3**: Refactor `server.py` / MCP tools to be project-agnostic (configurable `LEAN_PROJECT_PATH`)
- **Phase 4**: Layered configuration system; broad skill definitions
- **Phase 5**: Comprehensive testing, performance optimization, documentation polish

The compose file and scripts still assume `/workspace/autoquantum` as the project mount point — this is the main remaining hardcoded assumption to remove in Phase 3.
