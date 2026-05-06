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

A Docker container provides a reproducible OpenCode environment with Lean 4.29.0, Mathlib v4.29.0, MCP server dependencies, comparator, `lean4export`, `landrun`, and LaTeX tooling baked into the image.

### Configuration

The container defaults are defined in `docker-compose.yml`. Override them with standard Compose environment handling or inline environment variables when you launch the container. In practice, the only values you usually need to supply are provider API keys.

To switch models, use the `--model` flag when running OpenCode (for example, `opencode run --model provider/model-id "task"`).

```bash
docker compose build                         # Build the image and baked tool caches
docker compose up -d                         # Start the OpenCode server
opencode run --attach http://localhost:4096  # Connect (requires OpenCode CLI on host)
docker compose down                          # Stop when done
```

The Compose service bind-mounts the repository at `/workspace/autoquantum` and overlays `lean/.lake` with an anonymous volume so the container uses the image's prebuilt Lake package cache instead of any host-local `.lake` tree. `scripts/entrypoint.sh` starts `opencode serve` and honors `OPENCODE_HOST` / `OPENCODE_PORT` if those need to be overridden.

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

The repo includes a comparator-oriented proof verification scaffold under `lean/Goals/` and `lean/Solutions/`.

- `lean/Goals/<Goal>/<Goal>.lean` files are trusted challenge theorems.
- `lean/Goals/<Goal>/comparator.json` is the authority for trusted module, candidate module, theorem names, and permitted axioms.
- `lean/Solutions/<Goal>.lean` files are candidate proofs with flat `Solutions.<Goal>` module names.

Inside the Compose-managed container, no extra comparator setup is needed because the image includes comparator, `lean4export`, and `landrun` in `/home/opencode/.tools/bin`.

For host-local development outside Docker, provide a comparator binary on `PATH`, set `COMPARATOR_BIN=/path/to/comparator`, or use the same `.tools/` layout expected by `scripts/verify_comparator.py`. Comparator also needs `lean4export` and `landrun` available on `PATH` or under the expected `.tools/` directories.

Then verify the sample goal with:

```bash
python3 scripts/verify_comparator.py --goal Comm
```

Useful script options:

- `--goal <Goal>` — limit verification to one goal folder; can be repeated
- `--list-goals` — show discovered goal folders
- `--fail-fast` — stop after the first comparator failure

## References

See [`notes/research-references.md`](notes/research-references.md) for the full literature survey and [`notes/lean-quantum-landscape.md`](notes/lean-quantum-landscape.md) for the current Lean API state.

Key inspirations:
- [LeanQuantum](https://github.com/inQWIRE/LeanQuantum) — Lean 4 quantum gate library on Mathlib
- [Lean-QuantumInfo](https://github.com/Timeroot/Lean-QuantumInfo) — quantum information theory in Lean 4
- [QWIRE (Coq)](https://github.com/inQWIRE/QWIRE) — foundational quantum circuit formalization patterns
- [MerLean](https://arxiv.org/abs/2602.16554) — LLM autoformalization pipeline for quantum computing

See [AGENTS.md](./AGENTS.md) for Lean code style, proof strategy, and how to add new algorithms.
