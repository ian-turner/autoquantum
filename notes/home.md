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

- [Research References](research-references.md) — Annotated bibliography for Lean quantum libraries, LLM+quantum papers, and related verification work
- [Reference Assets](reference-assets.md) — Local PDF references stored under `references/` with source provenance and git-ignore policy
- [Paper Extended Abstract](paper-extended-abstract.md) — Notes for the initial `paper/` LaTeX scaffold and extended-abstract direction
- [Paper Bibliography](paper-bibliography.md) — Bibliography cleanup notes for paper sources
- [Paper Build](paper-build.md) — Notes on the intentionally minimal `paper/Makefile` build target

### Lean Formalization

- [Lean Quantum Landscape](lean-quantum-landscape.md) — Current library surface and Mathlib/API pitfalls; keep benchmark-solution details out of this note
- [Gate Embedding Patterns](gate-embedding-patterns.md) — Reusable Kronecker/reindex and block-matrix patterns for lifted gates in core gate code

### Tooling

- [MCP Setup](opencode-setup.md) — Shared MCP server config for Claude Code and OpenCode
- [Docker Build Context](docker-build-context.md) — Notes on Docker image build context and baked Lean/comparator caches
