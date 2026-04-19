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
| `Algorithms/QFT.lean` | No | `dft_orthogonality`, `qftMatrix_isUnitary`, `omega_two`, `qftCircuit_two`, and the explicit target lemma `qftMatrix_two` are proved; general-case scaffolding now also includes `qftLayers`, `liftEquiv`, `liftGate`, `liftCircuit`, `liftGate_mul`, `liftGate_one`, `circuitMatrix_liftCircuit`, `msbIndex`, `lsbIndex`, and `dftMatrix_succ_entry`. Current blocker: the recursive `target.succ` layers appear to align with `tensorWithId 1` (new LSB) rather than the existing `liftGate` / `liftCircuit` suffix embedding; remaining gaps are `qft_correct` and `qft2_correct` |
| `Algorithms/GHZ.lean` | No | GHZ state and circuit defined; **normalization lemma proved**; correctness proofs for n=1,2 and general case are `sorry`-tagged; scaffolding includes `allOnesIndex`, `ghzVector`, `ghzState`, `ghzCircuit` (now requires n ≥ 1), and correctness theorems for n=1,2 with general theorem requiring n ≥ 1. |
| `Algorithms/HPlus.lean` | No | Uniform superposition |+⟩^⊗n scaffolding added April 19, 2026; `hPlusVector`, `hPlusState`, `hPlusCircuit` defined; normalization proof and `hPlus_correct` are `sorry`-tagged pending proof. |

## Topics

### Research & Literature
- [Research References](research-references.md) — Annotated bibliography: Lean quantum libs, LLM+quantum papers, Coq patterns, QFT verification
- [Reference Assets](reference-assets.md) — Local PDF references stored under `references/` with source provenance and git-ignore policy

### Lean Formalization
- [Lean Quantum Landscape](lean-quantum-landscape.md) — What Mathlib provides, what AutoQuantum has built, confirmed API pitfalls (EuclideanSpace/mulVec, import order, `abbrev` vs `def`, `star` vs `conj`, etc.)
- [Gate Embedding Patterns](gate-embedding-patterns.md) — Reusable Kronecker/reindex and block-matrix patterns for lifted gates in `Gate.lean`
- [MCP Setup](opencode-setup.md) — Shared MCP server config for Claude Code and OpenCode: `lean` build/check tools and `lean_lsp` LSP server
- [QFT API Roadmap](qft-api-roadmap.md) — Required gate and circuit abstractions for the full decomposed QFT circuit: qubit permutations, arbitrary placement, and bit-reversal
- [Qubit Normalization Pattern](qubit-normalization-pattern.md) — Reusable proof patterns for normalized and orthogonal single-qubit superpositions in `Qubit.lean`

### Algorithms
- [QFT Formalization Plan](qft-formalization-plan.md) — Step-by-step proof strategy for QFT correctness; current sorry status and known obstacles
- [QFT Recursion Indexing](qft-recursion-indexing.md) — Why the unfinished general proof appears to need `tensorWithId 1` rather than the older suffix-lift helper
- [QFT Textbook Proof Audit](qft-textbook-proof-audit.md) — Comparison of `QFT.lean` against Nielsen–Chuang and Fenner, with the recommended proof shape for the remaining correctness theorem
- [QFT General Proof Obligations](qft-general-proof-obligations.md) — Exact circuit-side lemma inventory needed to finish `qftCircuit_succ_matrix` without depending on `qft2_correct`
- [HPlus Proof Plan](hplus-proof-plan.md) — Lemma inventory and recommended order for proving `hPlus_correct` via tensor-product induction; 7 gaps identified across Core/Hilbert, Lemmas/Gate, Lemmas/Circuit
