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

## Docker Development Environment

A Docker container provides a fully reproducible environment with the Lean toolchain and MCP servers pre-configured. A dedicated compose service still warms shared Lean caches first, but `scripts/entrypoint.sh` also falls back to `scripts/bootstrap-lean.sh` when runtime caches are missing and the container has permission to populate them.

### Configuration

The container defaults are defined in `docker-compose.yml`. Override them with standard Compose environment handling or inline environment variables when you launch the container. In practice, the only values you usually need to supply are provider API keys.

To switch models, use the `--model` flag when running OpenCode (e.g. `opencode run --model deepseek/deepseek-chat "task"`).

```bash
docker compose build                        # Build the image (once, ~5 min)
docker compose up -d                        # Start the OpenCode server
opencode run --attach http://localhost:4096  # Connect (requires OpenCode CLI on host)
docker compose down                         # Stop when done
```

`docker compose up` runs a one-shot cache warmer first, which installs `elan`, the Lean/Lake dependency cache, and the comparator toolchain (`comparator`, `lean4export`, `landrun`) into named Docker volumes. The main `opencode` service mounts the shared `elan` cache and comparator tool cache read-only, copies the warmed Lake package tree into its own anonymous writable package volume on first start, and then runs a one-time `lake update` against that private worktree so builds succeed without mutating the shared cache. If you run the image standalone without those shared caches, the entrypoint now attempts the same Lean bootstrap flow directly inside the container.

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

## Comparator Proof Verification

The repo now includes a comparator-oriented proof verification scaffold under `lean/Goals/` and `lean/Solutions/`.

- `lean/Goals/*.lean` are trusted challenge theorems.
- `lean/Solutions/*.lean` are candidate proofs with the same module basename and theorem statement.
- theorem names are derived from the file stem in snake case with a `_goal` suffix, e.g. `Comm.lean` → `comm_goal`.

For local host development outside Docker, bootstrap comparator tooling with:

```bash
./scripts/setup_comparator.sh
export PATH="$PWD/.tools/bin:$PATH"
```

Inside the Compose-managed container, no extra comparator setup is needed: warmup installs the toolchain into the shared read-only cache and `scripts/entrypoint.sh` adds it to `PATH`. For host-local setup, `setup_comparator.sh` builds `landrun` too when Go is available; without Go, comparator verification will still be blocked on that binary.

Then verify the sample goal with:

```bash
python3 scripts/verify_comparator.py --goal Comm
```

Useful script options:

- `--list-goals` — show discovered goal files and expected theorem names
- `--dry-run` — print generated comparator configs without invoking comparator
- `--comparator /path/to/comparator` — use a specific comparator binary

## Current Status

`lake build AutoQuantum` succeeds with 0 errors. Mathlib pinned to **v4.29.0**.

| Module | Sorry-free? | Notes |
|--------|-------------|-------|
| `Core/Hilbert.lean` | Yes | `QState`, `QHilbert`, `basisState`, `superpose`; all norm proofs complete |
| `Core/Qubit.lean` | Yes | `ket0`, `ket1`, `ketPlus`, `ketMinus`, Bloch sphere; all proofs complete |
| `Core/Gate.lean` | Yes | Gates, `applyGate`, full placement API (`onQubit`, `controlledPhaseAt`, `bitReverse`, etc.) |
| `Core/Circuit.lean` | Yes | `circuitMatrix`, `circuitMatrix_append`, `CorrectFor` |
| `Core/Tensor.lean` | Yes | Tensor product helpers; all proofs complete |

Algorithm correctness goals live in `lean/Goals/` (trusted challenge statements) with candidate proofs in `lean/Solutions/`.

## References

See [`notes/research-references.md`](notes/research-references.md) for the full literature survey and [`notes/lean-quantum-landscape.md`](notes/lean-quantum-landscape.md) for the current Lean API state.

Key inspirations:
- [LeanQuantum](https://github.com/inQWIRE/LeanQuantum) — Lean 4 quantum gate library on Mathlib
- [Lean-QuantumInfo](https://github.com/Timeroot/Lean-QuantumInfo) — quantum information theory in Lean 4
- [QWIRE (Coq)](https://github.com/inQWIRE/QWIRE) — foundational quantum circuit formalization patterns
- [MerLean](https://arxiv.org/abs/2602.16554) — LLM autoformalization pipeline for quantum computing

See [AGENTS.md](./AGENTS.md) for Lean code style, proof strategy, and how to add new algorithms.
