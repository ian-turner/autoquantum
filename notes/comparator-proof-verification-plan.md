# Comparator Proof Verification Plan

**Date**: April 25, 2026  
**Status**: Initial scaffolding implemented  
**Goal**: Add a comparator-based verification pipeline for AI-generated Lean proofs.

## Overview

We want a workflow where trusted challenge theorems live in `lean/Goals/` and AI-produced candidate proofs live in `lean/Solutions/`. Each solution should restate the same theorem as the corresponding goal, and `comparator` should verify that the solution proves the same statement with only the permitted axioms.

We are intentionally **not** enforcing import provenance in the first version. The initial focus is only:

1. same theorem statement,
2. acceptable axiom footprint,
3. Lean kernel acceptance.

## Planned Lean Layout

Keep all challenge and solution files directly under `Goals/` and `Solutions/` respectively, with **no nested submodules** such as `Goals.Basic`.

```text
lean/
  Goals/
    Comm.lean
    GHZ2Correct.lean
    HPlusCorrect.lean
  Solutions/
    Comm.lean
    GHZ2Correct.lean
    HPlusCorrect.lean
```

Each goal file pairs with a solution file of the same basename.

Examples:

- `lean/Goals/Comm.lean` ↔ `lean/Solutions/Comm.lean`
- `lean/Goals/HPlusCorrect.lean` ↔ `lean/Solutions/HPlusCorrect.lean`

## Module Contract

Each paired file should define the **same theorem name** with the **same statement**.

The initial scaffold uses a filename-based naming convention so the verifier can derive theorem names automatically:

- `Comm.lean` → `comm_goal`
- `HPlusCorrect.lean` → `h_plus_correct_goal`
- stems that already contain underscores are normalized before suffixing, so `NC_Ex4_2.lean` maps to `nc_ex4_2_goal` rather than preserving doubled separators

Example goal file:

```lean
theorem comm_goal (n m : Nat) : n + m = m + n := by
  sorry
```

Example solution file:

```lean
theorem comm_goal (n m : Nat) : n + m = m + n := by
  omega
```

Rules:

- `Solutions/*.lean` should **not** import `Goals/*.lean`
- each file should import whatever trusted shared modules it needs directly
- use **one primary theorem per file**
- theorem names should be globally unique to simplify automation

## Comparator Fit

Comparator is a good fit for this design because it compares a trusted challenge module against a candidate solution module and checks that specified theorem names:

1. have the same statement,
2. use no more axioms than the configured allowlist,
3. are accepted by the Lean kernel.

For this repo, the intended comparator configuration shape is:

```json
{
  "challenge_module": "Goals.Comm",
  "solution_module": "Solutions.Comm",
  "theorem_names": ["comm_goal"],
  "permitted_axioms": ["propext", "Quot.sound", "Classical.choice"],
  "enable_nanoda": false
}
```

Comparator has a `v4.29.0` tag, so it is compatible with this repo's pinned Lean version.

## Planned Verification Script

The initial script lives at:

```text
scripts/verify_comparator.py
```

Responsibilities:

1. enumerate `lean/Goals/*.lean`,
2. find matching `lean/Solutions/*.lean`,
3. derive module names such as `Goals.Comm` and `Solutions.Comm`,
4. generate comparator config JSON on the fly,
5. invoke comparator for each pair,
6. print a pass/fail summary.

The verifier also supports a flat `--goal <Stem>` selector, `--list-goals`, `--dry-run`, and automatic comparator binary discovery from `PATH`, `COMPARATOR_BIN`, or `.tools/bin/comparator`.

## External Dependencies

Comparator itself requires additional binaries in `PATH`:

- `comparator`
- `landrun`
- `lean4export`

To simplify local setup, the repo now includes:

```text
scripts/setup_comparator.sh
```

This helper bootstraps local checkouts of `comparator` and `lean4export` under `.tools/`, copies their built binaries into `.tools/bin/`, and attempts to build `landrun` there as well when Go is available.

Optional later strengthening:

- `nanoda`, if we enable comparator's additional-kernel check.

## First Milestone

Build the pipeline around a tiny test pair first:

- `lean/Goals/Comm.lean`
- `lean/Solutions/Comm.lean`

Only after that works end-to-end should we add AutoQuantum-specific proof goals.

## Deferred for Later

Not part of the first version:

- import provenance checks,
- declaration-origin allowlists,
- CI integration,
- multi-theorem files,
- nanoda support.

## Success Criteria

Version 1 is complete when:

1. a valid goal/solution pair passes comparator,
2. an invalid solution fails comparator,
3. a missing solution is reported clearly,
4. forbidden axiom use is reported clearly,
5. the script can run across all registered goal files.
