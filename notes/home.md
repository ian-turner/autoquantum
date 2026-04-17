# AutoQuantum Wiki

Central index for all project notes. Start here.

## Project

- **Goal:** Automatic generation and formal verification of quantum circuits using LLMs and Lean 4.
- **Pipeline:** LLM generates a Lean 4 circuit + proof → Lean kernel checks it → verified circuit exported to OpenQASM / Qiskit.
- **Repo layout:** `lean/` (Lean library), `notes/` (this wiki), `AGENTS.md` (agent instructions).

## Build Status

Mathlib pinned to **v4.29.0** (`lean/lean-toolchain`). `lake build AutoQuantum` succeeds with 0 errors.

```bash
cd lean && lake update && lake exe cache get && lake build AutoQuantum
```

### Sorry status (April 2026)

| File | Sorry-free? | Notes |
|------|-------------|-------|
| `Hilbert.lean` | **Yes** | All proofs complete as of c4dcc6b |
| `Qubit.lean` | No | `ketPlus` and `ketMinus` norm proofs complete; remaining gaps are `ketPlus_braket_ketMinus` and the `blochState` lemmas |
| `Gate.lean` | No | `hadamard` unitarity, `phaseRotation` unitarity, `applyGate`, tensor embeddings |
| `Circuit.lean` | **Yes** | All proofs complete |
| `Algorithms/QFT.lean` | No | `omega_pow_two_pow`, `dft_orthogonality`, `qftMatrix_isUnitary`, circuit construction |

## Topics

### Research & Literature
- [Research References](research-references.md) — Annotated bibliography: Lean quantum libs, LLM+quantum papers, Coq patterns, QFT verification

### Lean Formalization
- [Lean Quantum Landscape](lean-quantum-landscape.md) — What Mathlib provides, what AutoQuantum has built, confirmed API pitfalls (EuclideanSpace/mulVec, import order, `abbrev` vs `def`, `star` vs `conj`, etc.)
- [Qubit Normalization Pattern](qubit-normalization-pattern.md) — Reusable proof pattern for `1 / sqrt 2` superpositions in `Qubit.lean`

### Algorithms
- [QFT Formalization Plan](qft-formalization-plan.md) — Step-by-step proof strategy for QFT correctness; current sorry status and known obstacles
