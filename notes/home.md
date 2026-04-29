# AutoQuantum Wiki

Central index for all project notes. Start here.

## Project

- **Goal:** Automatic generation and formal verification of quantum circuits using LLMs and Lean 4.
- **Pipeline:** LLM generates a Lean 4 circuit + proof → Lean kernel checks it → verified circuit exported to OpenQASM / Qiskit.
- **Repo layout:** `lean/` (Lean library), `notes/` (this wiki), `AGENTS.md` (agent instructions).

## Build Status

Mathlib pinned to **v4.29.0** (`lean/lean-toolchain`). `lake build AutoQuantum` succeeds with 0 errors and 0 warnings.

```bash
cd lean && lake update && lake exe cache get && lake build AutoQuantum
```

### Sorry status (April 2026)

| File | Sorry-free? | Notes |
|------|-------------|-------|
| `Core/Hilbert.lean` | **Yes** | All proofs complete as of c4dcc6b |
| `Core/Qubit.lean` | **Yes** | All single-qubit basis, superposition, and Bloch-sphere proofs complete; lint-clean as of April 17, 2026 |
| `Core/Gate.lean` | **Yes** | Core gates, qubit permutations, generic `controlled` constructor, Rx/Ry rotation gates, and one-qubit `controlPhase` gate (April 27, 2026) |
| `Core/Circuit.lean` | **Yes** | `Circuit n = List (QGate n)`; includes `idTensorCircuit`, `tensorWithIdCircuit`, `circuitMatrix`, `circuitMatrix_append`, and `Circuit.Implements` |
| `Core/Tensor.lean` | **Yes** | Tensor basis equivalence `tensorIndexEquiv k m` |
| `Goals/Comm.lean` | Trusted challenge | `n + m = m + n`; always sorry by design. `Solutions/Comm.lean` has the `omega` proof. |
| `Goals/NC_Ex4_2.lean` | **Solution exists** | `Solutions/NC_Ex4_2.lean` proves `exp (z • A) = cosh z • I + sinh z • A` from `A ^ 2 = 1` |
| `Goals/NC_Thm4_1.lean` | **Solution exists** | `Solutions/NC_Thm4_1.lean` proves Nielsen-Chuang theorem 4.1: single-qubit Z-Y-Z Euler decomposition |
| `Goals/NC_Fig4_6.lean` | **Solution exists** | `Solutions/NC_Fig4_6.lean` proves Nielsen-Chuang Figure 4.6: two-CNOT controlled-U decomposition |
| `Goals/HPlus.lean` | No solution | `hPlusState` norm proof + `hPlus_correct` both sorry'd |
| `Goals/GHZ.lean` | No solution | `ghzState` norm proof + `ghz_correct` both sorry'd |
| `Goals/QFT.lean` | No solution | `qftGate` isUnitary + `qft_correct` both sorry'd |

## Container Usage

A Docker container provides a fully reproducible environment with MCP servers pre-configured and the Lean toolchain bootstrapped into persistent caches on startup. See [Docker Setup](docker-containerization-plan.md) for operational notes.

```bash
docker compose build                        # Build the image (once)
docker compose up -d                        # Start the OpenCode server
opencode attach http://localhost:4096       # Connect (requires OpenCode CLI on host)
docker compose down                         # Stop when done
```

**Prerequisites:** Docker, Docker Compose, OpenCode CLI on the host.

## Open Goals

Six open sorries across three `Goals/` files. Goals carry sorry'd theorems by design; the aim is to write a `Solutions/` file that eliminates each sorry.

| Goal file | Theorems to prove | Notes |
|-----------|------------------|-------|
| `Goals/HPlus.lean` | `hPlus_correct` (uniform superposition circuit), `hPlusState` norm | Induction on n; back-qubit route (Hadamard at last qubit) is likely easiest. See HPlus section below for dead ends. |
| `Goals/GHZ.lean` | `ghz_correct` (GHZ state preparation circuit), `ghzState` norm | Hadamard on qubit 0 then CNOT chain; n=1,2 cases may be a useful warmup. |
| `Goals/QFT.lean` | `qft_correct` (QFT circuit = QFT matrix), `qftGate` isUnitary | QFT matrix unitarity requires DFT orthogonality; circuit correctness requires tensor-product induction over `hadamardAt`, `controlledPhaseAt`, and `bitReverse` layers. |

### HPlus

The n-qubit uniform superposition state is `(1/√(2^n)) ∑_k |k⟩`. The preparation circuit applies `hadamardAt i` for each `i : Fin n`.

**Dead ends (do not retry):**
- Front-qubit induction with `hadamardAt 0 = tensorWithId n hadamard` — requires unpacking `qubitPerm (swap last 0)` through `finFunctionFinEquiv`. Confirmed hard; DeepSeek failed after ~6 attempts (April 20, 2026).

**Recommended approach:**
- Back-qubit induction: `hadamardAt (Fin.last n) = idTensorWith n hadamard` closes with `simp [Equiv.swap_self]`.
- `idTensorWith_apply` mirrors `tensorWithId_apply` (same Matrix.reindex + Kronecker entry pattern).
- Current blocker: `hadamardAt_castSucc_eq` — conjugation-by-swap identity showing swapping qubit `castSucc i` with the last qubit transforms `idTensorWith (m+1) H` into `tensorWithId 1 (hadamardAt i)`.

### GHZ

The n-qubit GHZ state is `(|0…0⟩ + |1…1⟩) / √2`. The preparation circuit is:
1. `hadamardAt 0` — put qubit 0 into superposition
2. `controlledAt 0 i.succ pauliX` for each `i : Fin (n-1)` — spread the entanglement

Circuit is defined for `n ≥ 1`. No proof attempts yet; the n=1 case is a reasonable starting point.

### QFT

The n-qubit QFT maps `|j⟩ ↦ (1/√(2^n)) ∑_k ω^{jk} |k⟩` where `ω = exp(2πi/2^n)`. The circuit applies Hadamard + controlled phase rotations per qubit, then a bit-reversal. Both `qftMatrix` and `qftCircuit` are defined; proving their equality requires tensor-product induction on circuit layers.

## Topics

### Research & Literature
- [Research References](research-references.md) — Annotated bibliography: Lean quantum libs, LLM+quantum papers, Coq patterns, QFT verification
- [Reference Assets](reference-assets.md) — Local PDF references stored under `references/` with source provenance and git-ignore policy

### Lean Formalization
- [Lean Quantum Landscape](lean-quantum-landscape.md) — What Mathlib provides, what AutoQuantum has built, confirmed API pitfalls (EuclideanSpace/mulVec, import order, `abbrev` vs `def`, `star` vs `conj`, etc.)
- [Comparator Proof Verification Plan](comparator-proof-verification-plan.md) — `Goals/` + `Solutions/` pipeline for comparator-based checking of AI-generated proofs; scaffolding implemented
- [Prove Comparator Hook](proof-writer-comparator-hook.md) — Mandatory post-response comparator verification for `@prove` sessions keyed off `goal=<Stem>` prompt syntax
- [Gate Embedding Patterns](gate-embedding-patterns.md) — Reusable Kronecker/reindex and block-matrix patterns for lifted gates in `Core/Gate.lean`
- [MCP Setup](opencode-setup.md) — Shared MCP server config for Claude Code and OpenCode: `lean` build/check tools and `lean_lsp` LSP server
- [Script Layout Refactor](script-layout-refactor.md) — Shell scripts now live under `scripts/`; `.mcp/` keeps Python MCP server implementations
- [Framework Generalization Plan](framework-generalization-plan.md) — Ongoing evolution of AutoQuantum into a reusable multi-agent framework; Phases 1–2 complete (`build`, `plan`, `read`, `latex` agents)
- [Docker Setup](docker-containerization-plan.md) — Workflow and operational notes for the OpenCode+Lean Docker environment
- [Qubit Normalization Pattern](qubit-normalization-pattern.md) — Reusable proof patterns for normalized and orthogonal single-qubit superpositions in `Core/Qubit.lean`

