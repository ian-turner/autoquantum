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
│   ├── lean-toolchain   -- pins leanprover/lean4:v4.29.0
│   └── AutoQuantum/    # Core Lean library
│       ├── Core/
│       │   ├── Hilbert.lean          -- Hilbert space & quantum state types
│       │   ├── Qubit.lean            -- Single-qubit primitives
│       │   ├── Gate.lean             -- Gate definitions, placement API, permutations
│       │   └── Circuit.lean          -- Circuit composition & semantics
│       ├── Lemmas/
│       │   ├── Hilbert.lean          -- tensorState, tensorVec_norm
│       │   ├── Qubit.lean            -- Basis orthonormality
│       │   ├── Gate.lean             -- applyGate lemmas, hadamard_apply_ket*
│       │   └── Circuit.lean          -- circuitMatrix lemmas
│       └── Algorithms/
│           ├── QFT.lean          -- Quantum Fourier Transform
│           ├── GHZ.lean          -- GHZ state and circuit
│           └── HPlus.lean        -- Uniform superposition |+⟩^⊗n
├── .mcp/               # MCP servers (shared by Claude Code and OpenCode)
│   ├── lean-tools/     -- build/check/sorry_count tools (Python, runs via uv)
│   └── run-lean-lsp-mcp.sh  -- launcher for lean-lsp-mcp LSP server
├── notes/              # Research wiki — start at notes/home.md
├── references/         # Local PDFs (gitignored — see notes/reference-assets.md)
├── Dockerfile
└── docker-compose.yml
```

## MCP Tools

Two MCP servers are registered for this project and available to all agents.

### `lean` — build and type-check tools

**Prefer these over raw bash for all Lean build and check operations.**

| Tool | Equivalent bash | Purpose |
|------|----------------|---------|
| `build(target="AutoQuantum")` | `cd lean && lake build AutoQuantum` | Build after editing Lean files |
| `check_file(file="AutoQuantum/Core/Gate.lean")` | `cd lean && lake env lean AutoQuantum/Core/Gate.lean` | Quick typecheck of a single file |
| `sorry_count()` | `grep -r sorry lean/AutoQuantum` | Count remaining sorrys across all source files |

`file` paths are relative to `lean/`. The server handles PATH setup for `lake` automatically.

### `lean_lsp` — LSP-based proof tools

Provided by `lean-lsp-mcp`. Prefer these for interactive proof exploration and Mathlib API lookups:

**Core proof state tools:**
- `lean_goal` — inspect the proof state at a position (goals before/after a tactic)
- `lean_term_goal` — get the expected type at a position (useful for `refine`, `have`, `show`)
- `lean_diagnostic_messages` — get elaboration errors/warnings for a file
- `lean_file_outline` — list top-level definitions in a file (imports + declarations)
- `lean_hover_info` — type signature and documentation for a symbol

**Search tools (in priority order):**
1. `lean_local_search` — fast local search to verify declarations exist (use before trying a lemma name)
2. `lean_loogle` — type‑signature‑based Mathlib lemma search (use when you know the type shape)
3. `lean_leansearch` — semantic natural‑language Mathlib search (use when you know the concept)
4. `lean_state_search` — find tactics/lemmas that close a specific proof goal (most specific)

**Interactive proof assistance:**
- `lean_multi_attempt` — try multiple tactic snippets without modifying the file (returns goal states for each)
- `lean_code_actions` — get LSP quick fixes and “Try this” suggestions at a line
- `lean_verify` — check theorem axioms and scan source for suspicious patterns
- `lean_completions` — IDE autocompletions (use on incomplete code after `.` or partial name)

**Additional tools** (less frequently needed): `lean_declaration_file`, `lean_references`, `lean_get_widgets`, `lean_profile_proof`.

**Note:** All `lean_lsp` tool names have the prefix `lean_lsp_` in the actual MCP interface (e.g., `lean_lsp_lean_goal`). The shorthand names above are used throughout this document for readability. Both `lean_tools` and `lean_lsp` are registered in `.claude/settings.json` and available to Claude Code agents.

## Build

For initial setup or after changing `lean-toolchain`:

```bash
cd lean
lake update          # fetch Mathlib at the pinned tag
lake exe cache get   # download prebuilt .oleans — DO NOT skip this
lake build           # compile only our library
```

`lake build` with no target defaults to a no-op if nothing has changed; use the `build` MCP tool (or `lake build AutoQuantum`) to force compilation.

## Lean 4 Conventions

- **Imports first**: `import` statements must come before everything else in a file, including doc comments (`/-! ... -/`). This is a hard Lean 4 requirement.
- **`noncomputable`**: Any definition that depends on `ℝ`, `ℂ`, or anything from `EuclideanSpace` must be marked `noncomputable`.
- **`abbrev` vs `def` for type aliases**: Use `abbrev` (not `def`) when you want downstream code to inherit typeclass instances automatically (e.g., `abbrev Circuit (n : ℕ) := List (GateStep n)`).
- **Mathlib dependency**: Always import from Mathlib rather than re-proving standard results.
- **`sorry`-tagged goals**: Mark all unproven goals with `sorry` and a comment explaining the proof strategy. Never silently leave holes.
- **Naming**: Follow Mathlib naming conventions (snake_case for definitions/lemmas, CamelCase for structures/types).
- **Docstrings**: Add `/-- ... -/` docstrings to all top-level definitions and major lemmas.
- **Modularity**: Each file should be independently importable with explicit `import` headers.

## Key API Notes (confirmed against Mathlib v4.29.0)

- **Inner product notation**: Use `⟪x, y⟫_ℂ` (expands to `@inner ℂ _ _ x y`). Avoid defining local functions named `inner` — it shadows the notation. Use `braket` or a qualified name instead.
- **EuclideanSpace and mulVec**: `EuclideanSpace ℂ (Fin n) = PiLp 2 (fun _ => ℂ)` is a newtype wrapper, not `Fin n → ℂ`. `Matrix.mulVec` cannot accept it directly. Bridge via `Matrix.toEuclideanLin` (preferred) or `WithLp.equiv 2 (Fin n → ℂ)`.
- **Norm of basis vector**: `EuclideanSpace.norm_single` is deprecated — use `PiLp.norm_single`.
- **Complex conjugate**: In `open Complex` context, `conj` may not resolve to a function. Use `star` (from the `Star` typeclass) for complex conjugation in expressions.
- **4×4 matrix sums**: `fin_cases i <;> fin_cases j <;> simp [...]` leaves unsolved `∑` goals for 4×4 matrices. Add `Fin.sum_univ_four` to the simp set.
- **Imports that don't exist**: `Mathlib.Data.Complex.Exponential` and `Mathlib.Algebra.GeomSum` are not valid module paths in Mathlib 4.29. Use `Mathlib.Analysis.SpecialFunctions.Exp` and look for geometric sum lemmas under `Mathlib.RingTheory.RootsOfUnity` or `Mathlib.Algebra.BigOperators`.

## Proof Strategy for Quantum Circuit Correctness

When generating or verifying a quantum circuit proof, follow this template:

1. **Define the circuit** as a composition of `QGate` values using `singleGate`, `seqComp`, or list append (`++`).
2. **State the correctness theorem**: the circuit's matrix equals the target unitary (e.g., the DFT matrix for QFT).
3. **Prove by `norm_num` / `ring`** for small fixed cases; use `Matrix.ext` + `fin_cases` + entry-wise calculation for general n.
4. **Unitarity side-conditions**: prove the raw matrix is unitary with `Matrix.mem_unitaryGroup_iff` + `Matrix.ext` + `fin_cases`.

## LLM Generation Guidelines

- When generating Lean code, verify that imported modules exist in Mathlib 4.29 before using them.
- Prefer `EuclideanSpace ℂ (Fin n)` for n-dimensional complex Hilbert spaces.
- Use `Matrix (Fin n) (Fin n) ℂ` for gate matrices; `Matrix.unitaryGroup` for unitary membership.
- For the QFT matrix: `qftMatrix n j k = (1 / Real.sqrt (2^n : ℝ) : ℂ) * Complex.exp (2 * Real.pi * Complex.I / (2^n : ℂ)) ^ (j.val * k.val)`.
- Always mark complex/real-valued definitions `noncomputable`.
- Use `star` for complex conjugation, not `conj` or `Complex.conj`.

## Adding New Algorithms

1. Create `lean/AutoQuantum/Algorithms/<AlgorithmName>.lean`.
2. Put `import AutoQuantum.Core.Circuit` (and any Mathlib imports) at the very top, before the module doc comment.
3. Define the circuit, state the correctness theorem, and prove (or `sorry`) it.
4. Add an entry in `lean/AutoQuantum.lean`.
5. Add a kebab-case note in `notes/` and link it from `notes/home.md` if the algorithm has non-trivial prerequisites.

## Testing

- After any Lean edit, run the `build` MCP tool (`target="AutoQuantum"`) — it must succeed with 0 errors (`sorry`s are allowed during scaffolding).
- To check a single file quickly, use the `check_file` MCP tool (`file="AutoQuantum/<File>.lean"`).
- If MCP tools are unavailable, fall back to: `cd lean && lake build AutoQuantum` / `lake env lean AutoQuantum/<File>.lean`.

## Git Conventions

- When making a git commit, agents should add themselves as co-authors using a `Co-authored-by:` trailer in the commit message.

## Keeping Notes in Sync

After every session that changes Lean source files, update the notes wiki **before or in the same commit**:

1. **`notes/home.md` sorry-status table** — mark files sorry-free when all proofs are complete; list remaining gaps for partially-proved files.
2. **`notes/lean-quantum-landscape.md` feature table** — update status (Done / Partial / Deferred) for any definitions or lemmas that changed.
3. **`notes/lean-quantum-landscape.md` pitfalls** — add a new numbered entry for any Lean or Mathlib API surprise encountered during the session (wrong lemma names, elaboration stalls, notation quirks, import paths, etc.).

This is a hard requirement, not optional cleanup.

## Research Context

See `notes/research-references.md` for key papers and `notes/lean-quantum-landscape.md` for the current state of Lean quantum libraries. The notes are organized as a wiki — start at `notes/home.md`.
