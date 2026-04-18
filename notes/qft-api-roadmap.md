# QFT API Roadmap

Required gate- and circuit-level abstractions for constructing the standard decomposed Quantum Fourier Transform circuit in Lean.

---

## Why the Current API Is Not Enough

`Gate.lean` currently supports:

- end-placement embeddings via `tensorWithId` and `idTensorWith`
- a fixed-layout 2-qubit `controlled` constructor
- a 2-qubit `swap`

This is enough for small explicit circuits, but not for the full textbook QFT decomposition. The standard QFT on `n` qubits needs:

- Hadamard on arbitrary qubit `m`
- controlled phase rotations between arbitrary pairs `(m + j, m)`
- a final bit-reversal permutation of the whole register

The missing capability is arbitrary qubit placement.

---

## Required API Layers

### 1. Qubit permutations

We need a way to lift a permutation of qubit positions to a permutation of the `Fin (2^n)` computational basis.

Target abstractions:

- `qubitPerm : Equiv.Perm (Fin n) -> Equiv.Perm (Fin (2 ^ n))`
- `permuteQubits : Equiv.Perm (Fin n) -> QGate n`
- `swapAt : Fin n -> Fin n -> QGate n`
- `bitReverse : QGate n`

This turns qubit reordering into a reusable primitive instead of ad hoc `SWAP` chains.

### 2. Permutation-conjugation helpers

Once qubit permutations exist, gate placement should be expressed by conjugation:

```lean
P⁻¹ * U * P
```

Target abstraction:

- `permuteGate : Equiv.Perm (Fin n) -> QGate n -> QGate n`

This is the right bridge between local gate definitions and global register placement.

### 3. Arbitrary single-qubit placement

Target abstraction:

- `onQubit : (q : Fin n) -> QGate 1 -> QGate n`

This should be implemented by moving `q` to the front (or back), applying `tensorWithId` / `idTensorWith`, and undoing the permutation.

### 4. Arbitrary 2-qubit placement

Target abstractions:

- `onQubits : (q₁ q₂ : Fin n) -> q₁ ≠ q₂ -> QGate 2 -> QGate n`
- `controlledAt : (control target : Fin n) -> control ≠ target -> QGate 1 -> QGate n`
- `controlledPhaseAt : (control target : Fin n) -> control ≠ target -> (k : ℕ) -> QGate n`

For QFT this is the critical layer: the circuit is mostly `controlledPhaseAt` plus `onQubit hadamard`.

### 5. Structured circuit syntax

`Circuit` currently stores fully embedded `QGate n` values. This is semantically fine, but it discards placement structure that matters for generation and proof.

If the decomposed QFT proof becomes awkward, add a syntax layer for primitive operations:

- `hadamardAt q`
- `phaseAt q k`
- `controlledPhaseAt control target k`
- `swapAt i j`
- `permute σ`

and interpret that syntax into `QGate n` afterwards.

This is not the first blocker, but it is the natural next step if proof scripts become opaque.

---

## Recommended Implementation Order

1. Add qubit permutations and `permuteQubits`.
2. Add `permuteGate`.
3. Add `onQubit` and `swapAt`.
4. Add `onQubits` / `controlledAt` / `controlledPhaseAt`.
5. Define `bitReverse`.
6. Revisit whether `Circuit` needs a structured syntax layer.

This order matches the real dependency graph for decomposed QFT.

---

## Immediate Goal

The first milestone is to make this definition possible without manual matrix hacking:

```lean
for m = 0, ..., n - 1:
  apply hadamardAt m
  for j = 1, ..., n - 1 - m:
    apply controlledPhaseAt (m + j) m (j + 1)
apply bitReverse
```

Until the API can express that shape directly, the full standard QFT circuit is not really available in the library.
