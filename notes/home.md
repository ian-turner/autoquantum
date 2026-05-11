# AutoQuantum Wiki

Central index for durable project notes. Keep this page benchmark-neutral: do not list which goals have completed solutions, theorem-specific proof strategies, or prior proof attempts.

## Project

- **Goal:** Automatic generation and formal verification of quantum circuits using LLMs and Lean 4.
- **Pipeline:** LLM generates a Lean 4 circuit + proof, Lean checks it, and verified circuits can be exported to executable formats.
- **Repo layout:** `lean/` (Lean project), `.opencode/` (OpenCode prompts and plugin), `notes/` (this wiki), `AGENTS.md` (agent instructions).

## Build

Mathlib is pinned by `lean/lean-toolchain`.

```bash
cd lean
lake update
lake exe cache get
lake build AutoQuantum
```

For agent sessions, prefer the Lean MCP tools described in `AGENTS.md`.

## Topics

### Research & Literature

- [Research References](research-references.md) — Annotated bibliography for Lean quantum libraries, LLM+quantum papers, related verification work, and local PDF asset provenance

### Paper

- [Paper](paper.md) — LaTeX scaffold overview, build setup, and bibliography conventions

### Lean Formalization

- [Lean Quantum Landscape](lean-quantum-landscape.md) — Current library surface and Mathlib/API pitfalls; keep benchmark-solution details out of this note
- [Gate Embedding Patterns](gate-embedding-patterns.md) — Reusable Kronecker/reindex and block-matrix patterns for lifted gates in core gate code

### Tooling

- [MCP & OpenCode Setup](opencode-setup.md) — Shared MCP server config, OpenCode configuration, Docker environment, and agent files
