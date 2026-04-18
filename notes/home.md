# AutoQuantum Wiki

Central index for all project notes. Start here.

## Project

- **Goal:** Automatic generation and formal verification of quantum circuits using LLMs and Lean 4.
- **Pipeline:** LLM generates a Lean 4 circuit + proof → Lean kernel checks it → verified circuit exported to OpenQASM / Qiskit.
- **Repo layout:** `lean/` (Lean library), `notes/` (this wiki), `AGENTS.md` (agent instructions).

## Build Status

Mathlib pinned to **v4.29.0** (`lean/lean-toolchain`). `lake build AutoQuantum` succeeds with 0 errors.
All non-`sorry` linter warnings in the Lean sources were cleaned up on April 17, 2026; current warnings come from the unfinished QFT development.

```bash
cd lean && lake update && lake exe cache get && lake build AutoQuantum
```

### Sorry status (April 2026)

| File | Sorry-free? | Notes |
|------|-------------|-------|
| `Hilbert.lean` | **Yes** | All proofs complete as of c4dcc6b |
| `Qubit.lean` | **Yes** | All single-qubit basis, superposition, and Bloch-sphere proofs complete; lint-clean as of April 17, 2026 |
| `Gate.lean` | **Yes** | Core gates are sorry-free; qubit-permutation and arbitrary single-qubit placement groundwork added on April 18, 2026 |
| `Circuit.lean` | **Yes** | All proofs complete; `CorrectFor` keeps an intentionally unused unitary witness |
| `Algorithms/QFT.lean` | No | `dft_orthogonality`, `qftMatrix_isUnitary`, `omega_two`, and `qftCircuit_two` are proved; general-case scaffolding now includes `msbIndex`, `lsbIndex`, and `dftMatrix_succ_entry`; remaining gaps are `qft_correct` and `qft2_correct` |

## Topics

### Research & Literature
- [Research References](research-references.md) — Annotated bibliography: Lean quantum libs, LLM+quantum papers, Coq patterns, QFT verification

### Lean Formalization
- [Lean Quantum Landscape](lean-quantum-landscape.md) — What Mathlib provides, what AutoQuantum has built, confirmed API pitfalls (EuclideanSpace/mulVec, import order, `abbrev` vs `def`, `star` vs `conj`, etc.)
- [Gate Embedding Patterns](gate-embedding-patterns.md) — Reusable Kronecker/reindex and block-matrix patterns for lifted gates in `Gate.lean`
- [QFT API Roadmap](qft-api-roadmap.md) — Required gate and circuit abstractions for the full decomposed QFT circuit: qubit permutations, arbitrary placement, and bit-reversal
- [Qubit Normalization Pattern](qubit-normalization-pattern.md) — Reusable proof patterns for normalized and orthogonal single-qubit superpositions in `Qubit.lean`

### Algorithms
- [QFT Formalization Plan](qft-formalization-plan.md) — Step-by-step proof strategy for QFT correctness; current sorry status and known obstacles
