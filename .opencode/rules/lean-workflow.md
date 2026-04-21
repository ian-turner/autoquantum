# Lean 4 Proof Workflow — AutoQuantum

This repo uses two MCP servers for Lean 4 work. **Always use them; never run bash lean/lake commands.**

In this repo, `check_file` is expensive enough that broad edits should be verified with a
single `lean_build` call rather than many per-file checks.

## Tool reference

| Situation | Tool to call |
|-----------|-------------|
| Inspect goal after writing a tactic | `lean_lsp_lean_goal` ← **start here** |
| Test tactic candidates without editing | `lean_lsp_lean_multi_attempt` |
| See elaboration errors for a file | `lean_lsp_lean_diagnostic_messages` |
| Verify a lemma name exists | `lean_lsp_lean_local_search` |
| Find tactic that closes a goal | `lean_lsp_lean_state_search` |
| Lookup Mathlib by type shape | `lean_lsp_lean_loogle` |
| Lookup Mathlib by concept | `lean_lsp_lean_leansearch` |
| Get type/doc for a symbol | `lean_lsp_lean_hover_info` |
| Resolve file path + format multi_attempt call | `lean_proof_step` (custom tool) |
| Find sorry positions with context | `lean_find_sorry` (custom tool) |
| Typecheck a completed proof block | `lean_check_file` (slow — only after finishing, and only for one file) |
| Full build | `lean_build` (preferred after broad refactors or edits across multiple Lean files) |

**`lean_check_file` and `lean_build` take 60–180 seconds. Never use them mid-proof to check if a tactic works — that is what `lean_lsp_lean_goal` and `lean_lsp_lean_multi_attempt` are for. Do not spawn multiple `lean_check_file` calls in parallel for this repository; after a multi-file change, prefer one `lean_build` call.**

## Decision tree: what to do next

```
Starting a proof?
  → lean_find_sorry to see what goals remain

Writing a tactic?
  → lean_lsp_lean_goal immediately after to verify the goal changed as expected
  → If goal is unexpected: lean_lsp_lean_multi_attempt with 3-5 alternatives

Stuck on a goal?
  → lean_lsp_lean_state_search  (finds tactics that close it)
  → lean_lsp_lean_loogle        (if you know the type shape of the lemma you need)
  → lean_lsp_lean_leansearch    (if you know the concept but not the name)

About to write rw [X] or exact X?
  → lean_lsp_lean_local_search first to confirm X exists

Unsure of the correct absolute path for an LSP call?
  → lean_proof_step to resolve it

Finished a proof block?
  → If you changed one Lean file: lean_check_file
  → If you changed multiple Lean files or refactored shared APIs: lean_build once
```

## Mandatory iterative workflow

**Never write a whole proof body and hope it compiles.**

1. Write 1–3 tactics.
2. Call `lean_lsp_lean_goal` to see the resulting goal state.
3. If correct, proceed to the next 1–3 tactics. If not, diagnose before continuing.
4. Use `lean_lsp_lean_multi_attempt` to test candidates without touching the file.
5. Before any `rw [X]` or `exact X`, call `lean_lsp_lean_local_search` to verify `X` exists.
6. **After every Edit or Write to a `.lean` file**, call `lean_lsp_lean_diagnostic_messages` before doing anything else.
7. After a complete proof block, call `lean_check_file` only if you changed a single file.
8. After changes spanning multiple Lean files or shared APIs, make one `lean_build` call instead of multiple `lean_check_file` calls.

## File path format for LSP tools

All `lean_lsp_*` tools require **absolute paths**. Use `lean_proof_step` to resolve paths automatically. If calling LSP tools directly, the path must be:
```
/workspace/autoquantum/lean/AutoQuantum/Algorithms/HPlus.lean   ✓ absolute
AutoQuantum/Algorithms/HPlus.lean                                ✗ relative (will fail)
```

`lean_check_file` uses paths **relative to `lean/`**:
```
AutoQuantum/Algorithms/HPlus.lean   ✓ relative to lean/
```

## Stop conditions

If you cannot close a subgoal after 3 distinct tactic approaches: insert `sorry` with a comment describing the exact remaining goal state, and **stop**. Do not spiral or rewrite the same approach. Report what you proved and what remains.

## Key API notes (Mathlib v4.29.0)

- `EuclideanSpace ℂ (Fin n)` = `PiLp 2 (fun _ => ℂ)` — not `Fin n → ℂ` directly
- Use `star` for complex conjugation, not `conj`
- `change` fails on concrete types; use `show` instead
- `subst ha` before `simp` when you have `ha : a = 0`
- Tensor decomposition: `obtain ⟨⟨a, b⟩, rfl⟩ := e.surjective j` (nested brackets)

See `lean-proof-patterns.md` for confirmed working proof patterns.
