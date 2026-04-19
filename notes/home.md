# AutoQuantum Wiki

Central index for all project notes. Start here.

## Project

- **Goal:** Automatic generation and formal verification of quantum circuits using LLMs and Lean 4.
- **Pipeline:** LLM generates a Lean 4 circuit + proof → Lean kernel checks it → verified circuit exported to OpenQASM / Qiskit.
- **Repo layout:** `lean/` (Lean library), `notes/` (this wiki), `AGENTS.md` (agent instructions).

## Build Status

Mathlib pinned to **v4.29.0** (`lean/lean-toolchain`). `lake build AutoQuantum` succeeds with 0 errors.
All non-`sorry` linter warnings in the Lean sources were cleaned up on April 17, 2026; current warnings come from the unfinished QFT and GHZ development.

```bash
cd lean && lake update && lake exe cache get && lake build AutoQuantum
```

### Sorry status (April 18, 2026)

| File | Sorry-free? | Notes |
|------|-------------|-------|
| `Hilbert.lean` | **Yes** | All proofs complete as of c4dcc6b |
| `Qubit.lean` | **Yes** | All single-qubit basis, superposition, and Bloch-sphere proofs complete; lint-clean as of April 17, 2026 |
| `Gate.lean` | **Yes** | Core gates are sorry-free; qubit-permutation and arbitrary single-qubit placement groundwork added on April 18, 2026 |
| `Circuit.lean` | **Yes** | All proofs complete; `CorrectFor` keeps an intentionally unused unitary witness |
| `Algorithms/GHZ.lean` | No | General `n`-qubit GHZ development added on April 18, 2026. The file now defines `zeroIndex`, `onesIndex`, `allZeroState`, `allOneState`, `ghzState`, the nearest-neighbor `ghzCnotChain`, and the general `ghzCircuit`; it also proves the 1-qubit base case via `hadamardAt_fin1_zero`, `ghzState_one_eq_ketPlus`, `apply_hadamard_allZero_one`, and `ghzCircuit_prepares_ghz_zero`. Only the general theorem `ghzCircuit_prepares_ghz` remains a `sorry`; the remaining work is the nontrivial Hadamard/CNOT-chain invariant on `n + 1` qubits |
| `Algorithms/QFT.lean` | No | `dft_orthogonality`, `qftMatrix_isUnitary`, `omega_two`, `qftCircuit_two`, and the explicit target lemma `qftMatrix_two` are proved; general-case scaffolding now also includes `qftLayers`, `liftEquiv`, `liftGate`, `liftCircuit`, `liftGate_mul`, `liftGate_one`, `circuitMatrix_liftCircuit`, `msbIndex`, `lsbIndex`, and `dftMatrix_succ_entry`. Current blocker: the recursive `target.succ` layers appear to align with `tensorWithId 1` (new LSB) rather than the existing `liftGate` / `liftCircuit` suffix embedding; remaining gaps are `qft_correct` and `qft2_correct` |

## Topics

### Research & Literature
- [Research References](research-references.md) — Annotated bibliography: Lean quantum libs, LLM+quantum papers, Coq patterns, QFT verification
- [Reference Assets](reference-assets.md) — Local PDF references stored under `references/` with source provenance and git-ignore policy

### Lean Formalization
- [Lean Quantum Landscape](lean-quantum-landscape.md) — What Mathlib provides, what AutoQuantum has built, confirmed API pitfalls (EuclideanSpace/mulVec, import order, `abbrev` vs `def`, `star` vs `conj`, etc.)
- [Gate Embedding Patterns](gate-embedding-patterns.md) — Reusable Kronecker/reindex and block-matrix patterns for lifted gates in `Gate.lean`
- [QFT API Roadmap](qft-api-roadmap.md) — Required gate and circuit abstractions for the full decomposed QFT circuit: qubit permutations, arbitrary placement, and bit-reversal
- [Qubit Normalization Pattern](qubit-normalization-pattern.md) — Reusable proof patterns for normalized and orthogonal single-qubit superpositions in `Qubit.lean`

### Algorithms
- [GHZ Proof Sketch](ghz-proof-sketch.md) — General `n`-qubit GHZ circuit, state definitions, and the inductive proof plan used in `Algorithms/GHZ.lean`
- [QFT Formalization Plan](qft-formalization-plan.md) — Step-by-step proof strategy for QFT correctness; current sorry status and known obstacles
- [QFT Recursion Indexing](qft-recursion-indexing.md) — Why the unfinished general proof appears to need `tensorWithId 1` rather than the older suffix-lift helper
- [QFT Textbook Proof Audit](qft-textbook-proof-audit.md) — Comparison of `QFT.lean` against Nielsen–Chuang and Fenner, with the recommended proof shape for the remaining correctness theorem
- [QFT General Proof Obligations](qft-general-proof-obligations.md) — Exact circuit-side lemma inventory needed to finish `qftCircuit_succ_matrix` without depending on `qft2_correct`
