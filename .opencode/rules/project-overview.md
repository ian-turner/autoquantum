# AutoQuantum — Project Overview

AutoQuantum is a system for **automatic generation and formal verification of quantum circuits** using LLMs and the Lean 4 proof assistant.

## Pipeline

1. A user specifies a quantum algorithm or circuit.
2. An LLM generates a candidate Lean 4 formalization (circuit definition + correctness statement).
3. Lean's kernel checks the proof. If it fails, the LLM receives elaborated error feedback and retries.
4. Verified circuits can be exported to executable formats (OpenQASM, Qiskit, etc.).

## Repository Layout

```
autoquantum/
├── lean/                        # Lean 4 project (lakefile.lean + source)
│   ├── lean-toolchain            -- pins leanprover/lean4:v4.29.0
│   ├── AutoQuantum/             # Core Lean library (imported by Goals and Solutions)
│   │   └── Core/
│   │       ├── Hilbert.lean      -- Hilbert space & quantum state types
│   │       ├── Tensor.lean       -- Tensor product machinery
│   │       ├── Qubit.lean        -- Single-qubit primitives
│   │       ├── Gate.lean         -- Gate definitions, placement API, permutations
│   │       └── Circuit.lean      -- Circuit composition & semantics
│   ├── Goals/                   # Problem statements — one subdirectory per goal
│   │   ├── QFT/        -- QFT.lean + comparator.json
│   │   ├── GHZ/        -- GHZ.lean + comparator.json
│   │   ├── HPlus/      -- HPlus.lean + comparator.json
│   │   ├── Comm/       -- Comm.lean + comparator.json
│   │   ├── NC_Ex4_2/   -- NC_Ex4_2.lean + comparator.json
│   │   ├── NC_Fig4_6/  -- NC_Fig4_6.lean + comparator.json
│   │   └── NC_Thm4_1/ -- NC_Thm4_1.lean + comparator.json
│   └── Solutions/               # Completed proofs (flat, sorry-free when done)
│       └── Comm.lean, NC_Ex4_2.lean, NC_Fig4_6.lean, NC_Thm4_1.lean
├── .mcp/                        # MCP servers (shared by Claude Code and OpenCode)
│   ├── lean-tools/               -- build/check/sorry_count (Python, runs via uv)
│   ├── latex-tools/              -- LaTeX MCP server
│   └── run-lean-lsp-mcp.sh       -- launcher for lean-lsp-mcp LSP server
├── .opencode/
│   ├── rules/                    -- common rules (this directory, auto-loaded into every session)
│   │   ├── lean-workflow.md       -- iterative proof workflow and tool decision tree
│   │   ├── lean-proof-patterns.md -- tensor/gate/circuit proof patterns and pitfalls
│   │   └── project-overview.md   -- this file
│   └── agents/                   -- per-agent .md files (build, prove, plan, read, latex)
├── scripts/                     # Shell entrypoints and helpers
│   ├── entrypoint.sh             -- container startup: starts opencode serve
│   └── verify_comparator.py      -- proof verification helper
├── notes/                       # Research wiki — start at notes/home.md
├── references/                  # Local PDFs (Nielsen & Chuang, course notes)
├── Dockerfile
├── docker-compose.yml
└── opencode.json                # OpenCode config: MCP servers, agents
```

## Build

```bash
cd lean && lake build              # full build (60–180 s)
cd lean && lake build AutoQuantum  # default target
```

**Never run `lake` or `lean` via bash in an OpenCode session** — use the MCP tools instead (see `lean-workflow.md`).

## Agent Roster

| Agent | Invoked via | Role |
|-------|-------------|------|
| `build` | `@build` | Full-permission project and framework engineering |
| `prove` | `@prove` | Goal-scoped Lean proof writing in `lean/Solutions/`, with mandatory comparator verification on response completion |
| `plan` | `@plan` | Proof strategy and multi-agent workflow planning (read-only) |
| `read` | `@read` | arXiv/PDF ingestion, theorem extraction, Lean skeleton generation |
| `latex` | `@latex` | Lean-to-LaTeX transcription and PDF compilation |
| `verifier` | `@verifier` | Read-only proof and result validation *(planned)* |
| `code-reviewer` | `@code-reviewer` | Read-only code review *(planned)* |

## Key Conventions

- Lean toolchain: `leanprover/lean4:v4.29.0`, Mathlib v4.29.0
- Container working directory: `/workspace/autoquantum` (inside Docker)
- Host working directory: `/Users/ianturner/research/autoquantum`
- Notes are in `notes/` with kebab-case filenames; `notes/home.md` is the index
- Update `notes/` whenever Lean source files change (include sorry-status, feature table, new pitfalls)
- Local PDF references live in `references/` (gitignored)
