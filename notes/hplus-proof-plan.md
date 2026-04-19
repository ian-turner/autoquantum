# HPlus Correctness Proof Plan

Strategy for eliminating the two `sorry`s in `Algorithms/HPlus.lean`:
- `hPlusState` normalization (`HPlus.lean:37`)
- `hPlus_correct` (`HPlus.lean:49`)

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

### Gap 1 — `tensorState` (foundational missing definition)

No operation `QState k → QState m → QState (k+m)` exists anywhere in the codebase.
The gate side has `tensorWithId`/`idTensorWith` for Kronecker matrix products but nothing analogous for states.
Everything below depends on this.

```lean
-- in Core/Hilbert.lean
noncomputable def tensorState {k m : ℕ} (ψ : QState k) (φ : QState m) : QState (k + m)
lemma tensorState_norm {k m : ℕ} (ψ : QState k) (φ : QState m) :
    ‖(tensorState ψ φ).vec‖ = 1
```

### Gap 2 — `hPlusVector` normalization

Fills the first `sorry` in `hPlusState`. Uses `basisState_braket` (already in `Lemmas/Hilbert.lean`)
plus orthonormality of the basis sum scaled by `1/√(2^n)`.

```lean
-- in Lemmas/Hilbert.lean
lemma hPlusVector_norm (n : ℕ) : ‖hPlusVector n‖ = 1
```

### Gap 3 — State decomposition lemmas

```lean
-- in Lemmas/Hilbert.lean
lemma basisState_zero_tensor (n : ℕ) :
    basisState (1 + n) 0 = tensorState (basisState 1 0) (basisState n 0)

lemma hPlusVector_succ (n : ℕ) :
    hPlusVector (1 + n) = (tensorState (hPlusState 1) (hPlusState n)).vec
```

`hPlusVector_succ` is the combinatorial core: the identity
`∑_{k : Fin(2^{n+1})} |k⟩ = (∑_a |a⟩₁) ⊗ (∑_b |b⟩ₙ)` together with the scalar
`1/√(2^{n+1}) = (1/√2)(1/√(2^n))`.

### Gap 4 — Gate action on tensor-product state

**Likely the most technically painful gap.** Requires unraveling the `reindex` encoding
inside `tensorWithId` (`Gate.lean:249`).

```lean
-- in Lemmas/Gate.lean
lemma tensorWithId_apply {k m : ℕ} (U : QGate k) (ψ : QState k) (φ : QState m) :
    applyGate (tensorWithId m U) (tensorState ψ φ) = tensorState (applyGate U ψ) φ
```

### Gap 5 — `hadamardAt` gate identities

Both require unfolding `onQubit` → `permuteGate` → `idTensorWith` and showing the
permutation-conjugation simplifies correctly.

```lean
-- in Lemmas/Gate.lean

-- H on qubit 0 of (n+1) = H ⊗ Iₙ
lemma hadamardAt_zero_eq (n : ℕ) :
    (hadamardAt (0 : Fin (n+1)) : QGate (n+1)) = tensorWithId n hadamard

-- H on qubit i+1 of (n+1) = I₁ ⊗ (H on qubit i of n-qubit system)
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
      [⟨hadamardAt (0 : Fin (n+1))⟩] ++
      (hPlusCircuit n).map (fun s => ⟨idTensorWith 1 s.unitary⟩)

-- Lifted circuit acts only on left factor of tensor state
lemma runCircuit_idTensorWith {k m : ℕ} (c : Circuit k) (ψ : QState k) (φ : QState m) :
    runCircuit (c.map (fun s => ⟨idTensorWith m s.unitary⟩)) (tensorState ψ φ) =
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
| 2 | `hPlusVector_norm` | `Lemmas/Hilbert.lean` |
| 3 | `basisState_zero_tensor`, `hPlusVector_succ` | `Lemmas/Hilbert.lean` |
| 4 | `tensorWithId_apply` | `Lemmas/Gate.lean` |
| 5 | `hadamardAt_zero_eq`, `hadamardAt_succ` | `Lemmas/Gate.lean` |
| 6 | `hPlusCircuit_succ`, `runCircuit_idTensorWith` | `Lemmas/Circuit.lean` |
| 7 | `hadamard_apply_zero` | `Lemmas/Gate.lean` |
| 8 | Assemble `hPlus_correct` by induction | `Algorithms/HPlus.lean` |

## Known hard points

- **Gap 4** (`tensorWithId_apply`) is the hardest: it requires connecting the `Matrix.reindex`-encoded
  Kronecker structure in `Gate.lean:249–270` to the vector-level `tensorState` definition.
- **Gap 5** (`hadamardAt` identities) requires reasoning about `permuteGate` and `Equiv.swap`
  acting on `Fin (n+1)`.
