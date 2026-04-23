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
│       ├── Core/
│       │   ├── Hilbert.lean     -- Hilbert spaces, QState, basisState
│       │   ├── Qubit.lean       -- Single-qubit primitives and basis states
│       │   ├── Gate.lean        -- Gate definitions, placement API, permutations
│       │   └── Circuit.lean     -- Circuit composition and semantics
│       ├── Lemmas/
│       │   ├── Hilbert.lean     -- tensorState, tensorVec_norm
│       │   ├── Qubit.lean       -- Basis orthonormality
│       │   ├── Gate.lean        -- applyGate lemmas, hadamard_apply_ket*
│       │   └── Circuit.lean     -- circuitMatrix lemmas
│       └── Algorithms/
│           ├── QFT.lean         -- Quantum Fourier Transform
│           ├── GHZ.lean         -- GHZ state and circuit
│           └── HPlus.lean       -- Uniform superposition |+⟩^⊗n
├── .mcp/                   # MCP servers (lean build/check tools, lean_lsp)
├── notes/                  # Research wiki — start at notes/home.md
├── references/             # Local PDFs (gitignored — see notes/reference-assets.md)
├── Dockerfile
├── docker-compose.yml
├── AGENTS.md               # All instructions for AI agents working here
└── CLAUDE.md               # Points to AGENTS.md
```

## Docker Development Environment

A Docker container provides a fully reproducible environment with the Lean toolchain and MCP servers pre-configured. A dedicated compose service warms the shared Lean caches first; the main OpenCode container mounts the shared `elan` cache read-only and seeds its own writable Lake package worktree from the warmed package cache.

### Configuration

The container defaults are defined in `docker-compose.yml`. Override them with standard Compose environment handling or inline environment variables when you launch the container. In practice, the only values you usually need to supply are provider API keys.

To switch models, use the `--model` flag when running OpenCode (e.g. `opencode run --model deepseek/deepseek-chat "task"`).

```bash
docker compose build                        # Build the image (once, ~5 min)
docker compose up -d                        # Start the OpenCode server
opencode attach http://localhost:4096       # Connect (requires OpenCode CLI on host)
docker compose down                         # Stop when done
```

`docker compose up` runs a one-shot cache warmer first, which installs `elan` plus the Lean/Lake dependency cache into named Docker volumes. The main `opencode` service mounts the shared `elan` cache read-only, copies the warmed Lake package tree into its own anonymous writable package volume on first start, and then runs a one-time `lake update` against that private worktree so builds succeed without mutating the shared cache.

**Web Interface:** To start OpenCode with a web UI, run `docker compose run opencode web`. The server will be accessible at http://localhost:4096 in your browser.

### Local Development

**Prerequisites:** [Lean 4 + elan](https://leanprover.github.io/lean4/doc/setup.html), `lake` (bundled with elan).

```bash
cd lean
lake update          # fetch Mathlib at the pinned tag (~5–10 min first time)
lake exe cache get   # download prebuilt .oleans — skips hours of compilation
lake build           # compile only our library (~seconds)
```

> **Note:** `lake exe cache get` is essential. Without it, `lake build` will attempt to compile all of Mathlib from source.

## Current Status

`lake build AutoQuantum` succeeds with 0 errors. Mathlib pinned to **v4.29.0**.

| Module | Sorry-free? | Notes |
|--------|-------------|-------|
| `Core/Hilbert.lean` | Yes | `QState`, `QHilbert`, `basisState`, `superpose`; all norm proofs complete |
| `Core/Qubit.lean` | Yes | `ket0`, `ket1`, `ketPlus`, `ketMinus`, Bloch sphere; all proofs complete |
| `Core/Gate.lean` | Yes | Gates, `applyGate`, full placement API (`onQubit`, `controlledPhaseAt`, `bitReverse`, etc.) |
| `Lemmas/Gate.lean` | Yes | `applyGate_vec_apply`, `hadamard_apply_ket0/1`, basis-state apply |
| `Core/Circuit.lean` | Yes | `circuitMatrix`, `circuitMatrix_append`, `CorrectFor` |
| `Algorithms/QFT.lean` | **No** | 2 sorries: `qft_correct`, `qft2_correct` |
| `Algorithms/GHZ.lean` | **No** | 3 sorries: correctness for n=1, n=2, general case |
| `Algorithms/HPlus.lean` | **No** | 1 sorry: `hPlus_correct` |

## Key Design Decisions

- **States as unit vectors** in `EuclideanSpace ℂ (Fin (2^n))` — integrates with Mathlib's inner product space machinery.
- **Gates as `Matrix.unitaryGroup` members** — unitary constraints are type-level, not runtime checks.
- **Circuits as `abbrev` list** — `abbrev Circuit (n : ℕ) := List (GateStep n)` ensures `List` instances (`++`, induction) work without manual unfolding.
- **Gate placement via permutation conjugation** — `onQubit`, `controlledAt`, `controlledPhaseAt`, `bitReverse` are expressed as `P⁻¹ * U * P` rather than ad hoc `SWAP` chains.
- **Tensor products via Kronecker** — `Matrix.kroneckerMap` computes multi-qubit gate embeddings, reindexed through `finProdFinEquiv`.

## References

See [`notes/research-references.md`](notes/research-references.md) for the full literature survey and [`notes/lean-quantum-landscape.md`](notes/lean-quantum-landscape.md) for the current Lean API state.

Key inspirations:
- [LeanQuantum](https://github.com/inQWIRE/LeanQuantum) — Lean 4 quantum gate library on Mathlib
- [Lean-QuantumInfo](https://github.com/Timeroot/Lean-QuantumInfo) — quantum information theory in Lean 4
- [QWIRE (Coq)](https://github.com/inQWIRE/QWIRE) — foundational quantum circuit formalization patterns
- [MerLean](https://arxiv.org/abs/2602.16554) — LLM autoformalization pipeline for quantum computing

See [AGENTS.md](./AGENTS.md) for Lean code style, proof strategy, and how to add new algorithms.
