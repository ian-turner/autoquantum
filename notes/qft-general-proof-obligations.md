# QFT General Proof Obligations

Exact lemma inventory for finishing the general theorem
`AutoQuantum.QFT.qftCircuit_succ_matrix` without relying on `qft2_correct`.

Last updated: April 18, 2026.

Update after the core lifting refactor: the reusable lift machinery now lives in
`Core/Circuit.lean` / `Lemmas/Circuit.lean` as `idTensorCircuit`, `tensorWithIdCircuit`, and the
corresponding `circuitMatrix_*` lemmas. The likely recursive embedding for the unfinished QFT step
still appears to be `tensorWithId 1` rather than the suffix direction `idTensorWith 1`; the revised
indexing diagnosis is written up in `notes/qft-recursion-indexing.md`.

---

## Executive Summary

The main theorem `qft_correct` does **not** depend on `qft2_correct`.
The induction in `QFT.lean` is:

- base case `qft_correct_zero`,
- inductive step `qftCircuit_succ_matrix`.

So the real work is to prove the `(n+1)`-qubit circuit decomposition in a form that exposes the
induction hypothesis on `qftCircuit n`.

The DFT-side algebra is already in place:

- `tensorWithId_mul`, `idTensorWith_mul`
- `circuitMatrix_tensorWithIdCircuit`, `circuitMatrix_idTensorCircuit`
- `omega_sq_pred`
- `msbIndex`, `lsbIndex`
- `msbIndex_mul_lsbIndex`
- `dftMatrix_succ_entry`

What is still missing is the rest of the circuit-side bridge from the decomposed gate list to that
same factorization, especially the shifted gate-placement lemmas and recursive bit-reversal
decomposition.

---

## Recommended Proof Shape

The cleanest route is:

1. isolate the first layer on qubit `0`;
2. identify the remaining target-`1..n` layers as an embedding of the `n`-qubit QFT circuit on the suffix qubits;
3. separate the full `(n+1)`-qubit bit-reversal into:
   - the embedded `n`-qubit suffix reversal,
   - one final swap moving qubit `0` to the end;
4. apply the induction hypothesis to the embedded suffix circuit;
5. compute the matrix entries of:
   - the first Hadamard on qubit `0`,
   - the controlled-phase stack targeting qubit `0`,
   - the final swap;
6. match the resulting factorization against `dftMatrix_succ_entry`.

This makes `qft2_correct` a sanity check, not a dependency.

---

## Exact Lemmas To Prove

### 1. Lift circuits on the suffix qubits

Status: implemented generically as `idTensorCircuit` in `Core/Circuit.lean` and
`circuitMatrix_idTensorCircuit` in `Lemmas/Circuit.lean`.

Define the embedded suffix circuit:

```lean
abbrev liftCircuit := idTensorCircuit 1
```

Then prove:

```lean
lemma circuitMatrix_liftCircuit (c : Circuit n) :
    circuitMatrix (idTensorCircuit 1 c) = idTensorWith 1 (circuitMatrix c)
```

This reduces to the generic multiplicativity lemma:

```lean
private lemma idTensorWith_mul (U V : QGate n) :
    idTensorWith 1 (U * V) = idTensorWith 1 U * idTensorWith 1 V
```

The matrix proof should use:

- `Matrix.mul_kronecker_mul`
- `Matrix.reindexAlgEquiv_mul`

### 2. Shifted gate-placement lemmas

These are the key API bridge lemmas:

```lean
private lemma hadamardAt_succ (q : Fin n) :
    hadamardAt q.succ = idTensorWith 1 (hadamardAt q)

private lemma controlledPhaseAt_succ_succ
    (control target : Fin n) (h : control ≠ target) (k : ℕ) :
    controlledPhaseAt control.succ target.succ
        (by simpa using h) k =
      idTensorWith 1 (controlledPhaseAt control target h k)
```

Once those are available, the layer lemmas should be straightforward:

```lean
private lemma qftControlledLayer_succ (target : Fin n) :
    qftControlledLayer (n + 1) target.succ =
      idTensorCircuit 1 (qftControlledLayer n target)

private lemma qftQubitLayer_succ (target : Fin n) :
    qftQubitLayer (n + 1) target.succ =
      idTensorCircuit 1 (qftQubitLayer n target)
```

### 3. Decompose bit-reversal recursively

This is the most delicate permutation lemma.

The intended statement is:

```lean
private lemma bitReverse_succ :
    (bitReverse : QGate (n + 1)) =
      liftPermutationOfSuffixBitReverse * swapAt 0 (Fin.last n)
```

where `liftPermutationOfSuffixBitReverse` is the `(n+1)`-qubit permutation gate that fixes qubit `0`
and reverses only qubits `1..n`.

Operationally, this is what allows:

- the suffix `qftCircuit n` to contribute its own embedded `bitReverse`,
- the remaining permutation to be just one final swap sending the leading output bit to the end.

Even if the final implementation uses an explicit lifted qubit permutation rather than a named gate,
this is the permutation identity the proof needs.

### 4. Circuit decomposition for the inductive step

After the gate-placement and bit-reversal lemmas, prove the actual list-level factorization:

```lean
private lemma qftCircuit_succ_decompose :
    qftCircuit (n + 1) =
      qftQubitLayer (n + 1) 0 ++
      idTensorCircuit 1 (qftCircuit n) ++
      [swapAt 0 (Fin.last n)]
```

This is the point where the induction hypothesis becomes usable.

### 5. Matrix-entry lemmas aligned to `msbIndex` / `lsbIndex`

These are the circuit-side analogues of `dftMatrix_succ_entry`.

For the first Hadamard:

```lean
private lemma hadamardAt_zero_entry (b c : Fin 2) (i i' : Fin (2 ^ n)) :
    (hadamardAt (0 : Fin (n + 1)) :
        Matrix (Fin (2 ^ (n + 1))) (Fin (2 ^ (n + 1))) ℂ)
      (msbIndex n b i) (msbIndex n c i') =
      (if i = i' then (hadamard : Matrix (Fin 2) (Fin 2) ℂ) b c else 0)
```

For the controlled-phase stack targeting qubit `0`, the product should collapse to the scalar
phase term:

```lean
private lemma qftControlledLayer_zero_entry (b c : Fin 2) (i : Fin (2 ^ n)) :
    ... =
      if i = i then
        if b = 1 ∧ c = 1 then (omega (n + 1)) ^ i.val else 1
      else 0
```

The exact statement may be cleaner in product form, but the semantic content is:

- the suffix index is preserved,
- the amplitude gains the phase `ω_(n+1)^(i * c)` needed by `dftMatrix_succ_entry`.

For the final swap:

```lean
private lemma swapAt_zero_last_entry (b c : Fin 2) (i i' : Fin (2 ^ n)) :
    (swapAt (0 : Fin (n + 1)) (Fin.last n) :
        Matrix (Fin (2 ^ (n + 1))) (Fin (2 ^ (n + 1))) ℂ)
      (lsbIndex n i b) (msbIndex n c i') =
      if b = c ∧ i = i' then 1 else 0
```

This is the step that converts the embedded suffix-QFT output split into the `lsbIndex` split used
by `dftMatrix_succ_entry`.

---

## What The Final Inductive Step Should Look Like

After the decomposition lemmas, `qftCircuit_succ_matrix` should reduce to:

```lean
swapAt 0 (Fin.last n) *
  idTensorWith 1 (qftMatrix n) *
  firstLayerMatrix
=
qftMatrix (n + 1)
```

Then prove this entrywise on

```lean
(msbIndex n b i, lsbIndex n i' c)
```

using:

- the first-layer entry lemmas,
- the induction hypothesis through `circuitMatrix_liftCircuit`,
- the final-swap entry lemma,
- `qftMatrix_eq_scale_dft`,
- `dftMatrix_succ_entry`.

At that point, the proof should be algebraically routine compared to the permutation bookkeeping.

---

## Conclusion

The general proof does **not** require `qft2_correct`.
It requires a small semantic library for:

- embedding a circuit on suffix qubits,
- commuting `hadamardAt` / `controlledPhaseAt` with that embedding,
- recursively decomposing bit-reversal,
- and evaluating the resulting matrices on the split indices already present in `QFT.lean`.

That is the actual shortest path to `qft_correct`.
