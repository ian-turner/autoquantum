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
│   └── AutoQuantum/             # Core Lean library
│       ├── Core/
│       │   ├── Hilbert.lean      -- Hilbert space & quantum state types
│       │   ├── Qubit.lean        -- Single-qubit primitives
│       │   ├── Gate.lean         -- Gate definitions, placement API, permutations
│       │   └── Circuit.lean      -- Circuit composition & semantics
│       ├── Lemmas/
│       │   ├── Hilbert.lean      -- tensorState, tensorVec_norm
│       │   ├── Qubit.lean        -- Basis orthonormality
│       │   ├── Gate.lean         -- applyGate lemmas, hadamard_apply_ket*
│       │   └── Circuit.lean      -- circuitMatrix lemmas
│       └── Algorithms/
│           ├── QFT.lean          -- Quantum Fourier Transform
│           ├── GHZ.lean          -- GHZ state and circuit
│           └── HPlus.lean        -- Uniform superposition |+⟩^⊗n
├── .mcp/                        # MCP servers (shared by Claude Code and OpenCode)
│   ├── lean-tools/               -- build/check/sorry_count (Python, runs via uv)
│   └── run-lean-lsp-mcp.sh       -- launcher for lean-lsp-mcp LSP server
├── .opencode/
│   ├── rules/                    -- common rules (this directory, auto-loaded)
│   │   └── agents/               -- agent-specific rules (inlined into opencode.json prompt fields)
│   └── plugins/lean-tools.js     -- custom tools + post-edit diagnostic hook
├── notes/                       # Research wiki — start at notes/home.md
├── references/                  # Local PDFs (Nielsen & Chuang, course notes)
├── Dockerfile
├── docker-compose.yml
├── entrypoint.sh                # Container startup: seeds Lake cache, starts opencode serve
└── opencode.json                # OpenCode config: MCP servers, agents, plugin
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
| `proof-writer` | `@proof-writer` | Goal-scoped Lean proof writing in `lean/Solutions/`, with mandatory comparator verification on response completion |
| `reading` | `@reading` | arXiv/PDF ingestion, theorem extraction, Lean skeleton generation |
| `latex-writer` | `@latex-writer` | Lean-to-LaTeX transcription and PDF compilation |
| `verifier` | `@verifier` | Read-only proof and result validation *(planned)* |
| `code-reviewer` | `@code-reviewer` | Read-only code review *(planned)* |

## Key Conventions

- Lean toolchain: `leanprover/lean4:v4.29.0`, Mathlib v4.29.0
- Container working directory: `/workspace/autoquantum` (inside Docker)
- Host working directory: `/Users/ianturner/research/autoquantum`
- Notes are in `notes/` with kebab-case filenames; `notes/home.md` is the index
- Update `notes/` whenever Lean source files change (include sorry-status, feature table, new pitfalls)
- Local PDF references live in `references/` (gitignored)
