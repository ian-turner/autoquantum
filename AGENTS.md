# Agent Instructions - AutoQuantum

AutoQuantum is a Lean 4 project for generating and checking formal quantum-circuit proofs. Keep this file focused on repository workflow and tool usage. Do not add solved-goal inventories, proof sketches for benchmark goals, or examples that reveal completed solution status.

## Repository Orientation

- Lean source lives under `lean/`.
- Core library code lives under `lean/AutoQuantum/`.
- Benchmark challenge statements live under `lean/Goals/`.
- Candidate proof files live under `lean/Solutions/`.
- Project notes live under `notes/`; add durable development notes there when changes create useful context for future work.
- OpenCode agent prompts live under `.opencode/agents/`.

Agents can inspect the filesystem directly when they need exact paths. Avoid duplicating directory trees in this file.

## MCP Tools

Prefer the Lean MCP tools over raw shell commands for Lean work.

### `lean`

- `build(target="AutoQuantum")`: build the project after completed Lean edits.
- `check_file(file="...")`: typecheck one Lean file, with paths relative to `lean/`.
- `sorry_count()`: count remaining `sorry`s.
- `search_mathlib_local(query, kind="name" | "type" | "grep")`: search the baked local Mathlib index — offline, no rate limits. **Use this first.**
- `search_mathlib(query, kind="leansearch" | "loogle")`: HTTP search via leansearch.net / loogle.lean-lang.org. Use only when `search_mathlib_local` returns no useful results.

Never read files under `lean/.lake/packages/` to find lemma names. Use `search_mathlib_local` first; fall back to `search_mathlib` (HTTP) only if the local search misses.

### `lean_lsp`

Use LSP tools for interactive proof work:

- Diagnostics: `lean_lsp_lean_diagnostic_messages`
- Goal inspection: `lean_lsp_lean_goal`, `lean_lsp_lean_term_goal`
- Search: `lean_lsp_lean_local_search`, `lean_lsp_lean_loogle`, `lean_lsp_lean_leansearch`, `lean_lsp_lean_state_search`
- Experiments: `lean_lsp_lean_multi_attempt`
- IDE help: `lean_lsp_lean_hover_info`, `lean_lsp_lean_completions`, `lean_lsp_lean_code_actions`

After editing any Lean file, call diagnostics before continuing with more proof edits.

## Build

For initial setup or after changing the Lean toolchain:

```bash
cd lean
lake update
lake exe cache get
lake build AutoQuantum
```

For routine verification, use the MCP build/check tools instead of raw `lake` commands when available.

## Lean Conventions

- Put `import` statements before everything else in a Lean file, including module doc comments.
- Mark definitions that depend on `ℝ`, `ℂ`, `EuclideanSpace`, or noncomputable analysis APIs as `noncomputable`.
- Use `abbrev` for transparent type aliases when downstream typeclass inference should see through the alias.
- Import Mathlib APIs rather than re-proving standard facts.
- If a goal is intentionally left open, use `sorry` with a short comment explaining the remaining obligation.
- Follow Mathlib naming style: snake_case for theorem/definition names and CamelCase for structures/types.
- Add docstrings to top-level definitions and important lemmas.
- Keep files independently importable with explicit imports.
- Use `star` for complex conjugation unless an existing local API requires another spelling.

## Comparator Goals

For benchmark proof tasks:

- Read the target challenge file under `lean/Goals/<Goal>/<Goal>.lean`.
- Read `lean/Goals/<Goal>/comparator.json`; it is the authority for module and theorem names.
- Write the candidate proof in the matching flat file under `lean/Solutions/<Goal>.lean`.
- Do not edit files under `lean/Goals/`.
- Do not import the corresponding `Goals.*` module into the candidate solution.
- Do not consult existing completed solution files for the same benchmark goal.
- Keep theorem names and statements aligned with the comparator config.

The instructions above are intentionally goal-agnostic. Do not add per-goal solution hints here.

## Adding New Benchmark Goals

When adding a new goal, create:

- `lean/Goals/<Name>/<Name>.lean`
- `lean/Goals/<Name>/comparator.json`

Use `sorry` for unproved challenge obligations. Add only the minimal candidate file under `lean/Solutions/` when the benchmark workflow requires it.

## Testing

- After Lean edits: call `lean_lsp_lean_diagnostic_messages`.
- After completing a single-file Lean change: use `check_file`.
- After shared API or multi-file Lean changes: use `build(target="AutoQuantum")`.
- If MCP tools are unavailable, fall back to `cd lean && lake build AutoQuantum` or `cd lean && lake env lean <file>`.

Do not run multiple slow Lean checks in parallel.

## Notes

When changes create durable project knowledge, add a kebab-case markdown note in `notes/` and link it from `notes/home.md` if it should be discoverable. For Lean source changes, keep relevant notes in sync with the current API and known pitfalls, but avoid recording benchmark solution strategies in agent-loaded docs.

## Git

When making a git commit, add yourself as a co-author using a `Co-authored-by:` trailer.
