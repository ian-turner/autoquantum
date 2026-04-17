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
├── lean/               # Lean 4 library (AutoQuantum)
│   ├── lakefile.lean
│   └── AutoQuantum/
│       ├── Hilbert.lean     -- Hilbert spaces, quantum state types
│       ├── Qubit.lean       -- Single-qubit primitives and basis states
│       ├── Gate.lean        -- Quantum gate definitions and properties
│       ├── Circuit.lean     -- Circuit composition and semantics
│       └── Algorithms/
│           └── QFT.lean     -- Quantum Fourier Transform
├── notes/              # Literature survey and design notes
│   ├── research_references.md
│   ├── lean_quantum_landscape.md
│   └── qft_formalization_plan.md
├── AGENTS.md           # All instructions for AI agents working here
└── CLAUDE.md           # Points to AGENTS.md
```

## Getting Started

### Prerequisites

- [Lean 4 + elan](https://leanprover.github.io/lean4/doc/setup.html)
- `lake` (bundled with elan)

### Build

```bash
cd lean
lake update        # fetch Mathlib and dependencies
lake build         # compile the library
```

### Explore

```bash
# Open in VS Code with lean4 extension for interactive proof state
code lean/AutoQuantum/Algorithms/QFT.lean
```

## Current Status

| Module | Status |
|--------|--------|
| `Hilbert.lean` | Scaffold — core types defined, proofs partial |
| `Qubit.lean` | Scaffold — basis states defined |
| `Gate.lean` | Scaffold — standard gates defined, unitarity sorry'd |
| `Circuit.lean` | Scaffold — composition semantics defined |
| `QFT.lean` | Scaffold — statement proven sorry, proof strategy outlined |

All `sorry`s are intentional scaffolding markers; each carries a comment describing the intended proof strategy.

## Key Design Decisions

- **States as unit vectors** in `EuclideanSpace ℂ (Fin (2^n))` — integrates cleanly with Mathlib's inner product space machinery.
- **Gates as `Matrix.unitaryGroup` members** — unitary constraints are type-level, not runtime checks.
- **Circuits as gate lists with qubit indices** — compositional and easy to generate from LLM output.
- **Tensor products via Kronecker** — `Matrix.kroneckerMap` computes multi-qubit gate embeddings.

## References

See [`notes/research-references.md`](notes/research-references.md) for the full literature survey.

Key inspirations:
- [LeanQuantum](https://github.com/inQWIRE/LeanQuantum) — Lean 4 quantum gate library on Mathlib
- [Lean-QuantumInfo](https://github.com/Timeroot/Lean-QuantumInfo) — quantum information theory in Lean 4
- [QWIRE (Coq)](https://github.com/inQWIRE/QWIRE) — foundational quantum circuit formalization patterns
- [MerLean](https://arxiv.org/abs/2602.16554) — LLM autoformalization pipeline for quantum computing

## Contributing

See [AGENTS.md](./AGENTS.md) for conventions on Lean code style, proof strategy, and how to add new algorithms.
