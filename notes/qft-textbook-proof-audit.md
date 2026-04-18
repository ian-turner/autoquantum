# QFT Textbook Proof Audit

Audit of the current `lean/AutoQuantum/Algorithms/QFT.lean` development against the two local QFT textbook references:

- Nielsen and Chuang, *Quantum Computation and Quantum Information*, §5.1, especially pages 217–219 in the local PDF numbering
- Steven Fenner, *Quantum computation course notes* (Fall 2022), “The Quantum Fourier Transform” on page 99 and “Implementing the QFT” on pages 109–110 in the local PDF numbering

Last updated: April 18, 2026.

---

## Executive Summary

The current Lean development is structurally consistent with both textbooks, but it matches them in two different ways:

- The proved matrix lemmas (`dft_orthogonality`, `qftMatrix_isUnitary`) follow Fenner’s DFT-first proof pattern very closely.
- The circuit definition `qftCircuit` follows Nielsen and Chuang’s standard gate-by-gate QFT circuit exactly: Hadamard on each target qubit, controlled phase rotations from later qubits, then final bit reversal.

The main remaining gap is that the unfinished theorem `qftCircuit_succ_matrix` is currently set up as a recursive matrix proof. That is textbook-aligned, but it is closer to Fenner’s recursive decomposition than to Nielsen and Chuang’s product-state derivation. This is acceptable. If we want the final Lean proof to read more like Nielsen and Chuang, we should add an intermediate lemma expressing the output state in product form before bit reversal.

---

## Reference Proof Shapes

### Nielsen and Chuang

Section 5.1 presents three ingredients in sequence:

1. Define QFT as the normalized DFT on computational basis states.
2. Rewrite the output on `|j₁ ... jₙ⟩` into a product-state form with binary fractions in the phases.
3. Derive the circuit by showing that:
   - the first Hadamard creates the first phase bit,
   - each controlled `R_k` appends one more binary digit to that phase,
   - the same process repeats qubit by qubit,
   - final swap gates reverse qubit order.

Unitarity is then justified by the circuit construction itself, while a direct proof of unitarity is left as an exercise.

### Fenner

The course notes present two proof patterns that both matter here:

1. A direct DFT unitarity proof on page 99:
   - diagonal entries are sums of ones,
   - off-diagonal entries are geometric series in a nontrivial root of unity.
2. A recursive circuit decomposition on pages 109–110:
   - split the input index `x` into high and low bits,
   - split the output index `y` similarly,
   - factor the exponent,
   - identify the factors with `QFT_{n-m}`, a phase block `P_{n,m}`, and a final qubit permutation.

Shor’s original circuit is the repeated `m = 1` case of that recursive decomposition.

---

## Lean Alignment

### What already matches Nielsen and Chuang

- `qftCircuit` is the standard textbook circuit:
  - `qftQubitLayer` applies `hadamardAt target` first,
  - `qftControlledLayer` applies the controlled rotations from later qubits onto that target,
  - `bitReverse` is applied at the end.
- `qftCircuit_two` matches the explicit two-qubit textbook gate sequence:
  - `H` on qubit 0,
  - controlled `R₂` from qubit 1 to qubit 0,
  - `H` on qubit 1,
  - bit reversal.
- `qft1_correct` matches the standard textbook base case `QFT₁ = H`.

### What already matches Fenner

- `dft_orthogonality` is the same proof pattern as Fenner’s direct DFT unitarity argument:
  - diagonal case: every term simplifies to `1`,
  - off-diagonal case: rewrite as a geometric series with ratio `r`,
  - prove `r^(2^n) = 1` and `r ≠ 1`,
  - conclude the sum is `0`.
- `qftMatrix_isUnitary` uses that orthogonality relation entrywise, which is exactly the matrix-product version of Fenner’s proof.
- `msbIndex`, `lsbIndex`, `msbIndex_mul_lsbIndex`, and `dftMatrix_succ_entry` are already in the right shape for Fenner’s recursive index-splitting argument.

### Where the current Lean plan differs

The unfinished general theorem does not yet encode Nielsen and Chuang’s product-state proof directly. Instead, it is set up to prove correctness by recursively factoring matrix entries. That is still textbook-faithful, because Fenner’s recursive proof is an explicit textbook derivation of the same circuit family.

So the answer to “does the Lean file follow the textbooks?” is:

- yes for the circuit definition,
- yes for the matrix unitarity proof,
- yes for the intended inductive correctness proof,
- but the intended correctness proof is currently closer to Fenner than to Nielsen and Chuang.

---

## Recommended Final Proof Shape

The cleanest way to finish `qft_correct` while staying close to the textbooks is a hybrid:

1. Keep the existing matrix-side lemmas.
   They already match Fenner well and should not be replaced.

2. Finish `qft2_correct` as the concrete small instance.
   This matches both textbooks’ explicit two-qubit circuit discussion and gives a check that the gate-placement API is behaving correctly.

3. Complete `qftCircuit_succ_matrix` in Fenner style.
   Use the existing recursive index split and exponent factorization.

4. Add one explanatory lemma or note connecting that recursive factorization back to Nielsen and Chuang’s product representation.
   This does not need to be the main proof engine; it only needs to make the correspondence explicit.

This gives a final development that is mathematically aligned with both sources:

- operationally Nielsen-like at the circuit level,
- proof-theoretically Fenner-like at the recursive matrix level.

---

## Concrete Follow-up Work

The next proof work should focus on:

1. explicit 4×4 matrix lemmas for `hadamardAt 0`, `hadamardAt 1`, `controlledPhaseAt 1 0 2`, and `bitReverse`;
2. completion of `qft2_correct`;
3. completion of `qftCircuit_succ_matrix` using the existing `msbIndex` / `lsbIndex` infrastructure;
4. a short documentation-level bridge from the recursive Lean proof to Nielsen and Chuang’s product-state derivation.

That sequence preserves the current formalization direction while making the textbook correspondence explicit.
