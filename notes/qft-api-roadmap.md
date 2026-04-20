# QFT Gate Placement API

Reference for the gate- and circuit-level abstractions in `Core/Gate.lean` used by the QFT circuit. **All items below are fully implemented** (as of April 18, 2026).

---

## Implemented API

### Qubit permutations

Lift a permutation of qubit positions to a permutation of the `Fin (2^n)` computational basis:

```lean
qubitPerm    : Equiv.Perm (Fin n) → Equiv.Perm (Fin (2^n))
permuteQubits : Equiv.Perm (Fin n) → QGate n
swapAt       : Fin n → Fin n → QGate n
bitReverse   : QGate n
```

### Permutation-conjugation

Gate placement expressed as conjugation `P⁻¹ * U * P`:

```lean
permuteGate : Equiv.Perm (Fin n) → QGate n → QGate n
```

### Single-qubit placement

Move qubit `q` to the front, apply the gate via `tensorWithId`, undo the permutation:

```lean
onQubit      : (q : Fin n) → QGate 1 → QGate n
hadamardAt   : Fin n → QGate n
phaseRotationAt : Fin n → ℕ → QGate n
```

### Two-qubit placement

```lean
onQubits          : (q₁ q₂ : Fin n) → q₁ ≠ q₂ → QGate 2 → QGate n
controlledAt      : (control target : Fin n) → control ≠ target → QGate 1 → QGate n
controlledPhaseAt : (control target : Fin n) → control ≠ target → ℕ → QGate n
```

---

## QFT Circuit Shape

The full standard QFT circuit is now expressible directly:

```lean
-- for each target qubit m = 0, ..., n-1:
--   hadamardAt m
--   for each j = 1, ..., n-1-m: controlledPhaseAt (m+j) m (j+1)
-- bitReverse
```

This is implemented in `Algorithms/QFT.lean` as `qftCircuit n`.

---

## Proof Notes

The key structural facts for proofs involving this API are recorded in:

- [Gate Embedding Patterns](gate-embedding-patterns.md) — Kronecker/reindex patterns and unitarity preservation
- [QFT Recursion Indexing](qft-recursion-indexing.md) — why `tensorWithId 1` (new LSB) is the right embedding for the inductive step, not `idTensorWith 1`
