# AutoQuantum Compact Rules

Use this file as the default project instruction set for OpenCode. It intentionally mirrors only the high-signal parts of `AGENTS.md` to keep token usage down.

## Project Shape

- `lean/` is the Lean 4 project.
- `notes/` is the project wiki. Add a short kebab-case markdown note there when a session introduces reusable setup or workflow information.
- Build from `lean/` with `lake build AutoQuantum`.

## Lean Conventions

- Imports must come before everything else.
- Mark complex or real-valued definitions `noncomputable` when needed.
- Use `abbrev` for type aliases that should inherit instances.
- Prefer Mathlib imports and existing lemmas over re-proving basics.
- Leave unfinished goals as `sorry` with a short strategy comment.
- Add docstrings to top-level definitions and major lemmas.
- Use `star` for complex conjugation.
- Use `⟪x, y⟫_ℂ` for inner products.

## Working Style

- Keep context tight: read only the relevant Lean files and nearby declarations first.
- Prefer local proof-state inspection and local theorem search before broader search.
- Prefer the fixed tools `lean_build` and `lean_check_file` over ad-hoc shell commands for Lean compilation.
- Keep edits minimal and avoid speculative refactors.
- When changing files in this repo, avoid destructive git operations and do not revert unrelated work.

## Build Reminders

- Standard setup:
  - `cd lean`
  - `lake update`
  - `lake exe cache get`
  - `lake build AutoQuantum`

## Canonical Reference

- If these compact rules are not enough, consult `AGENTS.md`.
