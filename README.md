# AutoQuantum

Automatic generation and formal verification of quantum circuits using LLMs and [Lean 4](https://leanprover.github.io/).

## Vision

AutoQuantum closes the loop between LLM-based quantum circuit synthesis and machine-checked correctness proofs:

```
User intent
    │
    ▼
LLM generates Lean 4 circuit + proof
    │
    ▼
Lean kernel checks proof
    ├── Pass → export to OpenQASM / Qiskit
    └── Fail → structured error fed back to LLM → retry
```

Because every output is a checked Lean proof, correctness is not tested—it is *verified*.

## Repository Layout

```
autoquantum/
├── lean/                   # Lean 4 library (AutoQuantum)
│   ├── lakefile.lean
│   ├── lean-toolchain       -- pins leanprover/lean4:v4.29.0
│   └── AutoQuantum/
│       ├── Hilbert.lean     -- Hilbert spaces, quantum state types
│       ├── Qubit.lean       -- Single-qubit primitives and basis states
│       ├── Gate.lean        -- Quantum gate definitions and properties
│       ├── Circuit.lean     -- Circuit composition and semantics
│       └── Algorithms/
│           └── QFT.lean     -- Quantum Fourier Transform
├── notes/                  # Wiki — start at notes/home.md
│   ├── home.md
│   ├── research-references.md
│   ├── lean-quantum-landscape.md
│   └── qft-formalization-plan.md
├── AGENTS.md               # All instructions for AI agents working here
└── CLAUDE.md               # Points to AGENTS.md
```

## Docker Development Environment

To run Lean and MCP tools in Docker:

```bash
docker compose up -d     # Start the dev container
docker compose exec dev lake build  # Build the Lean project
```

The container includes the Lean toolchain, MCP servers for `lean` and `lean_lsp`, and is pre-configured for use with OpenCode. Connect by adding the workspace in OpenCode and pointing it to this repository.

### Local Development

#### Prerequisites

- [Lean 4 + elan](https://leanprover.github.io/lean4/doc/setup.html)
- `lake` (bundled with elan)

### Build

```bash
cd lean
lake update          # fetch Mathlib at the pinned tag (~5–10 min first time)
lake exe cache get   # download prebuilt .oleans — skips hours of compilation
lake build           # compile only our library (~seconds)
```

> **Note:** `lake exe cache get` is essential. Without it, `lake build` will attempt to compile all of Mathlib from source.

### Explore

```bash
# Open in VS Code with the lean4 extension for interactive proof state
code lean/AutoQuantum/Algorithms/QFT.lean
```

## Current Status

| Module | Status |
|--------|--------|
| `Hilbert.lean` | Builds — `QState`, `QHilbert`, `basisState`, `superpose`; norm proofs sorry'd |
| `Qubit.lean` | Builds — `ket0`, `ket1`, `ketPlus`, `ketMinus`, Bloch sphere; proofs sorry'd |
| `Gate.lean` | Builds — Pauli X/Y/Z, H, R_k, CNOT, SWAP defined; `applyGate` body deferred (EuclideanSpace/PiLp bridge) |
| `Circuit.lean` | Builds — `circuitMatrix`, `runCircuit`, `circuitMatrix_append` proved |
| `QFT.lean` | Builds — `qftMatrix`, `qftGate`, `qftCircuit` defined; correctness sorry'd |

All `sorry`s carry a comment describing the proof strategy. `lake build` completes with 0 errors.

## Key Design Decisions

- **States as unit vectors** in `EuclideanSpace ℂ (Fin (2^n))` — integrates with Mathlib's inner product space machinery.
- **Gates as `Matrix.unitaryGroup` members** — unitary constraints are type-level, not runtime checks.
- **Circuits as `abbrev` list** — `abbrev Circuit (n : ℕ) := List (GateStep n)` ensures `List` instances (`++`, induction) work without manual unfolding.
- **Inner product via `braket`** — `QState.braket` wraps `@inner ℂ (QHilbert n) _` to avoid shadowing Mathlib's `inner`.
- **Tensor products via Kronecker** — `Matrix.kroneckerMap` computes multi-qubit gate embeddings (gate embedding deferred).

## References

See [`notes/research-references.md`](notes/research-references.md) for the full literature survey.

Key inspirations:
- [LeanQuantum](https://github.com/inQWIRE/LeanQuantum) — Lean 4 quantum gate library on Mathlib
- [Lean-QuantumInfo](https://github.com/Timeroot/Lean-QuantumInfo) — quantum information theory in Lean 4
- [QWIRE (Coq)](https://github.com/inQWIRE/QWIRE) — foundational quantum circuit formalization patterns
- [MerLean](https://arxiv.org/abs/2602.16554) — LLM autoformalization pipeline for quantum computing

## Contributing

See [AGENTS.md](./AGENTS.md) for conventions on Lean code style, proof strategy, and how to add new algorithms.
