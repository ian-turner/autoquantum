# HPlus Correctness Proof Plan

Strategy for eliminating the remaining `sorry` in `Algorithms/HPlus.lean`:
- `hPlusState` normalization is now handled locally in `Algorithms/HPlus.lean` via `hPlusVector_norm`
- `hPlus_correct` (`HPlus.lean:47`)

## What was done (2026-04-19)

- Moved `hPlusVector` and `hPlusVector_norm` back into `Algorithms/HPlus.lean` so `Core/Hilbert.lean` stays focused on shared foundational definitions
- Added `tensorVec` (raw Kronecker product of Hilbert vectors) to `Core/Hilbert.lean`
- Added `tensorState` (normalized tensor product, sorry in norm proof) to `Core/Hilbert.lean`
- Added `tensorVec_norm` (sorry, proof sketch commented) to `Lemmas/Hilbert.lean`
- Wired `hPlusState` to use the local `hPlusVector_norm`, eliminating the old inline normalization `sorry`

**Sorry count**: one HPlus algorithm `sorry` remains (`hPlus_correct`); supporting Hilbert gaps are still `tensorState` and `tensorVec_norm`.

## Proof sketch

Induction on `n`, factoring the `n+1` circuit as a tensor product:

```
hPlusCircuit (n+1) |0…0⟩_{n+1}
  = [H₀] ++ shiftedCircuit(n)   on   |0⟩₁ ⊗ |0…0⟩ₙ
  = shiftedCircuit(n)            on   |+⟩₁ ⊗ |0…0⟩ₙ     -- H|0⟩ = |+⟩
  = |+⟩₁ ⊗ runCircuit(hPlusCircuit n)|0…0⟩ₙ              -- lifted circuit acts on right factor
  = |+⟩₁ ⊗ hPlusState n                                   -- inductive hypothesis
  = hPlusState (n+1)                                       -- tensor decomposition of target
```

## Required lemmas (by priority)

### Gap 1 — `tensorState` ✅ scaffolded

`tensorVec` and `tensorState` are now defined in `Core/Hilbert.lean`.
`tensorState` carries a sorry (norm proof); that sorry is in `tensorVec_norm` in `Lemmas/Hilbert.lean`.
Everything below still depends on completing `tensorVec_norm`.

```lean
-- in Core/Hilbert.lean
noncomputable def tensorState {k m : ℕ} (ψ : QState k) (φ : QState m) : QState (k + m)
lemma tensorState_norm {k m : ℕ} (ψ : QState k) (φ : QState m) :
    ‖(tensorState ψ φ).vec‖ = 1
```

### Gap 2 — `hPlusVector` normalization ✅ complete

Fills the first `sorry` in `hPlusState`. Uses `basisState_braket` (already in `Lemmas/Hilbert.lean`)
plus orthonormality of the basis sum scaled by `1/√(2^n)`.

Implemented in `Algorithms/HPlus.lean` by observing that every coordinate of
`hPlusVector n` is the constant amplitude `(1 / √(2^n) : ℂ)`, then applying
`PiLp.norm_sq_eq_of_L2` and simplifying the resulting finite sum.

```lean
-- in Algorithms/HPlus.lean
lemma hPlusVector_norm (n : ℕ) : ‖hPlusVector n‖ = 1
```

### Gap 3 — State decomposition lemmas ✅ complete

Both proved in `Algorithms/HPlus.lean` (April 20, 2026).

```lean
lemma basisState_zero_tensor (n : ℕ) :
    basisState (1 + n) 0 = tensorState (basisState 1 0) (basisState n 0)

lemma hPlusVector_succ (n : ℕ) :
    hPlusVector (1 + n) = (tensorState (hPlusState 1) (hPlusState n)).vec
```

`hPlusVector_succ` uses `tensorVec_apply` (abstract-type pattern), `pow_add`, and `Real.sqrt_mul`.

### Gap 4 — Gate action on tensor-product state ✅ complete

`tensorWithId_apply` is proved in `Lemmas/Gate.lean` (April 20, 2026).

```lean
-- in Lemmas/Gate.lean
lemma tensorWithId_apply {k m : ℕ} (U : QGate k) (ψ : QState k) (φ : QState m) :
    applyGate (tensorWithId m U) (tensorState ψ φ) = tensorState (applyGate U ψ) φ
```

**Proof sketch**: `apply Subtype.ext; ext i; obtain ⟨⟨a,b⟩,rfl⟩ := e.surjective i`.
After `show` to `.vec` form, use `applyGate_vec_apply`, `tensorVec_apply`, reindex the sum via
`Fintype.sum_equiv`, expand entries via `Matrix.reindex_apply` + `Matrix.submatrix_apply` +
`Matrix.kronecker_apply` (all `rfl`), collapse `Im b y = if b = y then 1 else 0` by `rfl`,
then `Finset.sum_ite_eq` (no prime — pattern `a = x`). The key constraint: define `e` with
`show 2^k * 2^m = 2^(k+m) by rw [pow_add]` (exact copy of `tensorWithId`'s internal `e`) so
that `Equiv.symm_apply_apply` fires inside `simp`.

### Gap 5 — `hadamardAt` gate identities ← current blocker

**Status (April 20, 2026):** DeepSeek attempted this via OpenCode and could not close it after ~6 approaches. The front-qubit route (proving `hadamardAt 0 = tensorWithId n hadamard`) requires working through `qubitPerm` / `finFunctionFinEquiv` matrix algebra and is confirmed hard.

**Easier alternative — induct from the back:**

`hadamardAt (Fin.last n)` in an `(n+1)`-qubit system unfolds to
`permuteGate (Equiv.swap (Fin.last n) (Fin.last n)) (idTensorWith n hadamard)`.
Since `Equiv.swap x x = Equiv.refl`, the permutation is trivial and
`permuteGate refl V = V`. Therefore:

```lean
lemma hadamardAt_last_eq (n : ℕ) :
    hadamardAt (Fin.last n) = idTensorWith n hadamard
-- Proof: unfold hadamardAt/onQubit, simp [Equiv.swap_self, permuteGate, permuteQubits]
```

This only requires `idTensorWith_apply` (the companion to the already-proved
`tensorWithId_apply`) instead of the hard permutation proof.

**Original front-qubit lemmas (harder):**

```lean
-- H on qubit 0 of (n+1) = H ⊗ Iₙ  (requires qubitPerm algebra)
lemma hadamardAt_zero_eq (n : ℕ) :
    (hadamardAt (0 : Fin (n+1)) : QGate (n+1)) = tensorWithId n hadamard

-- H on qubit i+1 of (n+1) = I₁ ⊗ (H on qubit i of n)  (requires qubitPerm algebra)
lemma hadamardAt_succ {n : ℕ} (i : Fin n) :
    (hadamardAt (i.succ : Fin (n+1)) : QGate (n+1)) = idTensorWith 1 (hadamardAt i)
```

### Gap 6 — Circuit structure lemmas

`hPlusCircuit_succ` is a list identity from `List.finRange_succ` + `hadamardAt_succ`.
`runCircuit_idTensorWith` follows from `tensorWithId_apply` by induction on the circuit.

```lean
-- in Lemmas/Circuit.lean

-- hPlusCircuit factors as one head gate + shifted tail
lemma hPlusCircuit_succ (n : ℕ) :
    hPlusCircuit (n+1) =
      [hadamardAt (0 : Fin (n+1))] ++
      tensorWithIdCircuit 1 (hPlusCircuit n)

-- Lifted circuit acts only on left factor of tensor state
lemma runCircuit_idTensorWith {k m : ℕ} (c : Circuit k) (ψ : QState k) (φ : QState m) :
    runCircuit (tensorWithIdCircuit m c) (tensorState ψ φ) =
    tensorState (runCircuit c ψ) φ
```

### Gap 7 — Atomic base case

```lean
-- in Lemmas/Gate.lean
lemma hadamard_apply_zero : applyGate hadamard (basisState 1 0) = hPlusState 1
```

## Recommended implementation order

| Step | Lemma | File |
|------|-------|------|
| 1 | Define `tensorState` | `Core/Hilbert.lean` |
| 2 | `hPlusVector_norm` | `Algorithms/HPlus.lean` |
| 3 | `basisState_zero_tensor`, `hPlusVector_succ` | `Algorithms/HPlus.lean` or a dedicated HPlus lemma file |
| 4 | `tensorWithId_apply` | `Lemmas/Gate.lean` |
| 5 | `hadamardAt_zero_eq`, `hadamardAt_succ` | `Lemmas/Gate.lean` |
| 6 | `hPlusCircuit_succ`, `runCircuit_idTensorWith` | `Lemmas/Circuit.lean` |
| 7 | `hadamard_apply_zero` | `Lemmas/Gate.lean` |
| 8 | Assemble `hPlus_correct` by induction | `Algorithms/HPlus.lean` |

## Session history

### April 20, 2026

- Gaps 1–4 all complete.
- DeepSeek (via OpenCode) attempted `hPlus_correct` with the front-qubit induction strategy.
  - n=0 base case proved successfully (empty circuit + `applyGate_one`).
  - Inductive step scaffolded: `circuitMatrix_append`, `applyGate_mul`, `basisState_zero_tensor` applied.
  - Blocked on `hadamardAt 0` permutation algebra (Gap 5 front-qubit route). ~6 tactic attempts all
    ended in `sorry`. DeepSeek also failed to use `lean_lsp_lean_goal` (root cause: 15 s MCP timeout
    caused tool failures on first call, making the model abandon interactive tools).
- OpenCode tooling fixes applied: timeouts raised, rules files added, plugin with `lean_proof_step`
  and `lean_find_sorry` tools created. See `notes/opencode-setup.md`.
- Recommended next approach: **induct from the back** via `hadamardAt_last_eq` + `idTensorWith_apply`,
  which avoids the hard `qubitPerm` algebra entirely.

## Known hard points

- **Gap 5 front route** (`hadamardAt_zero_eq`): requires unpacking `qubitPerm (swap last 0)` through
  `finFunctionFinEquiv` to show it swaps tensor factors. Confirmed difficult for LLM agents.
- **Gap 5 back route** (`hadamardAt_last_eq` + `idTensorWith_apply`): `hadamardAt_last_eq` is easy
  (`Equiv.swap_self`); `idTensorWith_apply` mirrors `tensorWithId_apply` (already proved) and should
  follow the same Matrix.reindex + Kronecker entry calculation pattern.
