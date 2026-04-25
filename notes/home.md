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
| `Core/Hilbert.lean` | **Yes** | All proofs complete as of c4dcc6b |
| `Core/Qubit.lean` | **Yes** | All single-qubit basis, superposition, and Bloch-sphere proofs complete; lint-clean as of April 17, 2026 |
| `Core/Gate.lean` | **Yes** | Core gates are sorry-free; qubit-permutation and arbitrary single-qubit placement groundwork added on April 18, 2026, and the generic `controlled : QGate k -> QGate (k + 1)` constructor was added on April 23, 2026 |
| `Lemmas/Gate.lean` | **No** | `tensorWithId_apply`, `idTensorWith_apply`, `hadamardAt_last_eq` proved. Added permutation-matrix helper lemmas (`permuteQubits_coe`, `permMatrix_mul_apply`, `mul_permMatrix_apply`), base-2 digit lemmas for `tensorIndexEquiv n 1` under `finFunctionFinEquiv.symm`, `finFunctionFinEquiv_symm_qubitPerm_apply`, and new tensor-decomposition helpers (`finFunctionFinEquiv_symm_tensorIndex_cons`, `tensorIndexEquiv_symm_{snd_eq_digit_zero,fst_apply_eq_digit_succ}`, `tensorWithId_one_entry`). `hadamardAt_castSucc_eq` is still the remaining sorry; the blocker is now isolated as the exact transport identity for the big swap through the `(tensorIndexEquiv (m+1) 1)` split. |
| `Core/Circuit.lean` | **Yes** | Core circuit API simplified: `Circuit n = List (QGate n)` and the primary correctness predicate is now `Circuit.Implements` |
| `Algorithms/QFT.lean` | No | `dft_orthogonality`, `qftMatrix_isUnitary`, `omega_two`, `qftCircuit_two`, and the explicit target lemma `qftMatrix_two` are proved; general-case scaffolding now uses shared circuit-lift support (`idTensorCircuit`, `tensorWithIdCircuit`, and their `circuitMatrix_*` lemmas) plus `msbIndex`, `lsbIndex`, and `dftMatrix_succ_entry`. Correctness statements were simplified to direct matrix equalities after removing `Circuit.CorrectFor`. Current blocker: the recursive `target.succ` layers appear to align with `tensorWithId 1` (new LSB); remaining gaps are `qft_correct` and `qft2_correct` |
| `Algorithms/GHZ.lean` | No | GHZ state and circuit defined; **normalization lemma proved**; correctness proofs for n=1,2 and general case are `sorry`-tagged; scaffolding includes `allOnesIndex`, `ghzVector`, `ghzState`, `ghzCircuit` (now requires n ≥ 1), and correctness theorems for n=1,2 with general theorem requiring n ≥ 1. |
| `Algorithms/HPlus.lean` | No | All supporting lemmas proved (Gaps 1–4: `tensorState`, `hPlusVector_norm`, `basisState_zero_tensor`, `hPlusVector_succ`, `tensorWithId_apply`). Added `idTensorWith_apply`, `hadamardAt_last_eq`, `basisState_zero_tensor'`, `hPlusVector_succ'`. The file now uses the shared `tensorIndexEquiv` helper instead of repeating the `finProdFinEquiv`/`pow_add` bridge. `hPlus_correct` has structured inductive proof with n=0 base case complete; inductive step scaffolded using `hadamardAt_last_eq` and `idTensorWith_apply`, blocked on `hadamardAt_castSucc_eq`. Current proof work in `Lemmas/Gate.lean` has reduced that blocker to the split-entry transport identity for the larger swap under `(tensorIndexEquiv (m+1) 1)`, not to a simple lifted-permutation rewrite. |

## Container Usage

A Docker container provides a fully reproducible environment with MCP servers pre-configured and the Lean toolchain bootstrapped into persistent caches on startup. See [Docker Setup](docker-containerization-plan.md) for the architecture.

```bash
docker compose build                        # Build the image (once)
docker compose up -d                        # Start the OpenCode server
opencode attach http://localhost:4096       # Connect (requires OpenCode CLI on host)
docker compose down                         # Stop when done
```

**Prerequisites:** Docker, Docker Compose, OpenCode CLI on the host.

## Open Work

Current sorry count: **7** (as of April 24, 2026).

| Algorithm | Remaining gap | Primary reference |
|-----------|--------------|-------------------|
| `QFT.lean` | `qft2_correct` — explicit 4×4 proof; `qft_correct` — general inductive proof | [QFT Formalization Plan](qft-formalization-plan.md), [QFT General Proof Obligations](qft-general-proof-obligations.md) |
| `GHZ.lean` | Correctness for n=1, n=2, and general case | GHZ section of this file |
| `HPlus.lean` | `hPlus_correct` — tensor-induction proof | [HPlus Proof Plan](hplus-proof-plan.md) |

For QFT, the recommended next step is proving explicit 4×4 matrix lemmas for `hadamardAt 0`, `hadamardAt 1`, `controlledPhaseAt 1 0 2`, and `bitReverse`, then assembling `qft2_correct`. The general proof requires shifted-gate-placement lemmas (`hadamardAt q.succ = tensorWithId 1 ...`) plus recursive bit-reversal decomposition — see [QFT Recursion Indexing](qft-recursion-indexing.md).

For HPlus, Gaps 1–4 are complete and the back-qubit induction route was taken: `hadamardAt_last_eq` and `idTensorWith_apply` are both proved. The current blocker is `hadamardAt_castSucc_eq` in `Lemmas/Gate.lean` — a conjugation-by-swap identity showing that swapping the last qubit with position `castSucc i` transforms `idTensorWith (m+1) hadamard` into `tensorWithId 1 (hadamardAt i)`. The goal is reduced to a transport fact through `(tensorIndexEquiv (m+1) 1)`. See [HPlus Proof Plan](hplus-proof-plan.md).

### GHZ

The n-qubit GHZ state is `(|0…0⟩ + |1…1⟩) / √2`. The preparation circuit is:
1. `hadamardAt 0` — put qubit 0 into superposition
2. `controlledAt 0 i.succ pauliX` for each `i : Fin (n-1)` — spread the entanglement

The normalization lemma `norm_ghzVector` is proved. The three remaining sorries are `ghz_correct_one` (n=1), `ghz_correct_two` (n=2), and `ghz_correct` (general, requires n ≥ 1). No proof attempts have been made yet; the n=1 case has a partial `simp` scaffold already in place.

## Topics

### Research & Literature
- [Research References](research-references.md) — Annotated bibliography: Lean quantum libs, LLM+quantum papers, Coq patterns, QFT verification
- [Reference Assets](reference-assets.md) — Local PDF references stored under `references/` with source provenance and git-ignore policy

### Lean Formalization
- [Lean Quantum Landscape](lean-quantum-landscape.md) — What Mathlib provides, what AutoQuantum has built, confirmed API pitfalls (EuclideanSpace/mulVec, import order, `abbrev` vs `def`, `star` vs `conj`, etc.)
- [Comparator Proof Verification Plan](comparator-proof-verification-plan.md) — Planned `Goals/` + `Solutions/` pipeline for comparator-based checking of AI-generated proofs
- [Gate Embedding Patterns](gate-embedding-patterns.md) — Reusable Kronecker/reindex and block-matrix patterns for lifted gates in `Core/Gate.lean`
- [MCP Setup](opencode-setup.md) — Shared MCP server config for Claude Code and OpenCode: `lean` build/check tools and `lean_lsp` LSP server
- [Script Layout Refactor](script-layout-refactor.md) — Shell scripts now live under `scripts/`; `.mcp/` keeps Python MCP server implementations
- [Framework Generalization Plan](framework-generalization-plan.md) — Ongoing evolution of AutoQuantum into a reusable multi-agent framework; Phases 1–2 complete (`build`, `plan`, `reading`, `latex-writer` agents)
- [Docker Containerization Plan](docker-containerization-plan.md) — Architecture and workflow for the fully reproducible OpenCode+Lean Docker environment (implemented)
- [QFT Gate Placement API](qft-api-roadmap.md) — Implemented gate placement API: `onQubit`, `controlledPhaseAt`, `bitReverse`, and the permutation-conjugation pattern
- [Qubit Normalization Pattern](qubit-normalization-pattern.md) — Reusable proof patterns for normalized and orthogonal single-qubit superpositions in `Core/Qubit.lean`

### Algorithms
- [Proof Attempt Log](proof-attempts.md) — running log of approaches tried per sorry; brief new agent sessions from here
- [QFT Formalization Plan](qft-formalization-plan.md) — Step-by-step proof strategy for QFT correctness; current sorry status and known obstacles
- [QFT Recursion Indexing](qft-recursion-indexing.md) — Why the unfinished general proof appears to need `tensorWithId 1` rather than the older suffix-lift helper
- [QFT Textbook Proof Audit](qft-textbook-proof-audit.md) — Comparison of `QFT.lean` against Nielsen–Chuang and Fenner, with the recommended proof shape for the remaining correctness theorem
- [QFT General Proof Obligations](qft-general-proof-obligations.md) — Exact circuit-side lemma inventory needed to finish `qftCircuit_succ_matrix` without depending on `qft2_correct`
- [HPlus Proof Plan](hplus-proof-plan.md) — Lemma inventory and recommended order for proving `hPlus_correct` via tensor-product induction; 7 gaps identified across Core/Hilbert, Lemmas/Gate, Lemmas/Circuit
