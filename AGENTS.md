# Agent Instructions — AutoQuantum

This file contains all instructions for AI agents working in this repository.

## Project Overview

AutoQuantum is a system for **automatic generation and formal verification of quantum circuits** using LLMs and the Lean 4 proof assistant. The high-level pipeline is:

1. A user specifies a quantum algorithm or circuit (in natural language or a structured DSL).
2. An LLM generates a candidate Lean 4 formalization (circuit definition + correctness statement).
3. Lean's kernel checks the proof. If it fails, the LLM receives elaborated error feedback and retries.
4. Verified circuits are exported to executable formats (OpenQASM, Qiskit, etc.).

## Repository Layout

```
autoquantum/
├── lean/               # Lean 4 project (lakefile.lean + source)
│   └── AutoQuantum/    # Core Lean library
│       ├── Hilbert.lean          -- Hilbert space & quantum state types
│       ├── Qubit.lean            -- Single-qubit primitives
│       ├── Gate.lean             -- Gate definitions & properties
│       ├── Circuit.lean          -- Circuit composition & semantics
│       └── Algorithms/
│           └── QFT.lean          -- Quantum Fourier Transform
├── notes/              # Research notes and literature summaries
└── scripts/            # Generation / verification pipeline scripts (future)
```

## Lean 4 Conventions

- **Mathlib dependency**: Always import from Mathlib rather than re-proving standard results.
- **`sorry`-tagged goals**: Mark all unproven goals with `sorry` and a comment explaining the proof strategy. Never silently leave holes.
- **Naming**: Follow Mathlib naming conventions (snake_case for definitions/lemmas, CamelCase for structures/types).
- **Docstrings**: Add `/-- ... -/` docstrings to all top-level definitions and major lemmas.
- **Modularity**: Each file should be independently importable with explicit `import` headers.

## Proof Strategy for Quantum Circuit Correctness

When generating or verifying a quantum circuit proof, follow this template:

1. **Define the circuit** as a composition of `QGate` values (`Circuit.compose`).
2. **State the correctness theorem**: the circuit's matrix equals the target unitary (e.g., the DFT matrix for QFT).
3. **Prove by `norm_num` / `decide` / `ring`** for small cases; use `Matrix.ext` + entry-wise calculation for general n.
4. **Unitarity side-conditions**: use `Matrix.unitaryGroup` membership proofs or `Matrix.IsUnitary` directly.

## LLM Generation Guidelines

- When generating Lean code, always check that imported modules exist in Mathlib before referencing them.
- Prefer `EuclideanSpace ℂ (Fin n)` for n-dimensional complex Hilbert spaces.
- Use `Matrix (Fin n) (Fin n) ℂ` for gate matrices; `Matrix.unitaryGroup` for unitary constraints.
- Tensor products of gates = Kronecker products (`Matrix.kroneckerMap`).
- For the QFT: the defining equation is `QFT_matrix i j = (1 / Real.sqrt (2^n)) * Complex.exp (2 * Real.pi * Complex.I * i * j / 2^n)`.

## Adding New Algorithms

1. Create `lean/AutoQuantum/Algorithms/<AlgorithmName>.lean`.
2. Import `AutoQuantum.Circuit`.
3. Define the circuit, state the correctness theorem, and prove (or `sorry`) it.
4. Add an entry in `lean/AutoQuantum.lean`.
5. Add a note in `notes/` if the algorithm has non-trivial mathematical prerequisites.

## Testing

- `lake build` from `lean/` must succeed (no elaboration errors, `sorry`s are allowed during scaffolding).
- Run `lake env lean --check AutoQuantum/<file>.lean` for individual file checks.
- Future: a CI script in `scripts/` will also run the LLM generation pipeline against a test suite.

## Research Context

See `notes/research-references.md` for key papers and `notes/lean-quantum-landscape.md` for the current state of Lean quantum libraries to build on or avoid duplicating. The notes are organized as a wiki — start at `notes/home.md`.
