# GHZ Proof Sketch

Date: April 18, 2026.

## Circuit

`lean/AutoQuantum/Algorithms/GHZ.lean` now uses the standard nearest-neighbor
`n`-qubit GHZ construction.

For `n + 1` qubits:

1. apply `H` to qubit `0`
2. apply `CX 0 1`
3. apply `CX 1 2`
4. continue up to `CX n-1 n`

In Lean this is represented as:

- `ghzCnotChain n : Circuit (n + 1)`
- `ghzCircuit 0 := []`
- `ghzCircuit (n + 1) := [⟨hadamardAt 0⟩] ++ ghzCnotChain n`

The file also includes the specialization
```lean
ghzCircuit 3 =
  [⟨hadamardAt 0⟩,
   ⟨controlledAt 0 1 (by decide) pauliX⟩,
   ⟨controlledAt 1 2 (by decide) pauliX⟩]
```
as a sanity check that the general definition reduces to the familiar 3-qubit pattern.

## Source Notes

I checked the local `references/course-notes-fa22.pdf` and `references/Nielsen_Chuang.pdf`
copies while revising the GHZ file. The searchable OCR text did not expose a dedicated GHZ
construction passage in either reference, so the Lean implementation records the standard
textbook circuit shape directly rather than claiming a page-exact local citation.

## States

The general file defines:

- `zeroIndex n : Fin (2^n)`
- `onesIndex n : Fin (2^n)`
- `allZeroState n`
- `allOneState n`
- `ghzState n`

The main subtlety is the `n = 0` case. The usual formula
`(|0...0⟩ + |1...1⟩) / √2` only makes sense as a genuine two-branch superposition once the
register is nonempty. So the file defines:

- `ghzState 0 := allZeroState 0`
- `ghzState (n + 1) := (|0...0⟩ + |1...1⟩) / √2`

## Lean Strategy

The main correctness theorem is:

```lean
theorem ghzCircuit_prepares_ghz (n : ℕ) :
    runCircuit (ghzCircuit (n + 1)) (allZeroState (n + 1)) = ghzState (n + 1)
```

The intended proof is:

1. prove the base case `n = 0`, where `ghzCircuit 1` is just `H` on a single qubit
2. introduce an intermediate family of states with a growing prefix of ones in the second branch
3. show each CNOT in `ghzCnotChain n` extends that prefix by one qubit
4. compose the chain to reach `allOneState (n + 1)`

## Current Blocker

The theorem is still `sorry`, but the 1-qubit base case is now proved in Lean:

- `hadamardAt_fin1_zero`
- `ghzState_one_eq_ketPlus`
- `apply_hadamard_allZero_one`
- `ghzCircuit_prepares_ghz_zero`

So the remaining gap is now the genuinely general part rather than the degenerate `n = 0` endpoint.

That intermediate family is now named in Lean:

- `prefixOnesIndex n count` and `prefixOnesState n count` for the branch with `count` leading ones
- `ghzProgressState n count` for the normalized superposition
  `( |0...0⟩ + |11...10...0⟩ ) / √2`
  where the second branch has `count + 1` leading ones on `n + 1` qubits

The file also now proves the endpoint identifications:

- `prefixOnesIndex_zero`, `prefixOnesState_zero`
- `prefixOnesIndex_all`, `prefixOnesState_all`
- `ghzProgressState_terminal`

The latest helper pass also added the permutation-side bookkeeping that the final proof will need:

- `lowBitIndex` and `lowBitIndex_val` for the basis index with only the least-significant bit set
- `qubitPerm_zeroIndex` showing every qubit permutation fixes `|0...0⟩`
- `qubitPerm_lowBitIndex` showing the swap used by `hadamardAt 0` sends the low-bit branch to the
  expected leading-`1` branch
- `apply_permuteQubits_allZero` for the state-level version of that zero-branch invariance
- `runCircuit_append` in `Lemmas/Circuit.lean` so the final theorem can be written as "Hadamard step,
  then CNOT chain"

The next useful Lean milestones are:

- prove the nontrivial Hadamard-step lemma
  `applyGate (hadamardAt 0) (allZeroState (n + 1)) = ghzProgressState n 0 (Nat.zero_le n)`
- prove one CNOT-step extension lemma
  sending `ghzProgressState n k hk` to `ghzProgressState n (k + 1) _`
  under the `k`th gate of `ghzCnotChain`

Once those states are named and those two transition lemmas exist, the rest should be a
straightforward induction over the nearest-neighbor CNOT chain.

## Exact Remaining Gaps

The file only has one surface-level `sorry`, but that theorem still depends on four distinct
pieces of missing Lean work.

1. A general Hadamard-entry lemma.

   The proved lemma `apply_hadamard_allZero_one` only handles `Fin 1`. The general theorem needs
   the `n + 1` qubit statement

   ```lean
   applyGate (hadamardAt 0) (allZeroState (n + 1))
     = ghzProgressState n 0 (Nat.zero_le n)
   ```

   In practice this is the first real arbitrary-placement gate proof in the file: `hadamardAt 0`
   is defined through `onQubit`, so Lean has to see that the swap/permutation implementation still
   produces the expected basis superposition `|0...0⟩ + |10...0⟩`.

2. A one-step CNOT propagation lemma.

   For each `k < n`, the `k`th nearest-neighbor CNOT should extend the prefix of ones in the second
   GHZ branch:

   ```lean
   applyGate
     (controlledAt i.castSucc i.succ (ne_of_lt i.castSucc_lt_succ) pauliX)
     (ghzProgressState n i.1 ?_)
   = ghzProgressState n (i.1 + 1) ?_
   ```

   Conceptually the all-zero branch is fixed, while the `|11...10...0⟩` branch has control bit `1`
   and target bit `0`, so the target flips to `1`. The Lean content here is showing that the
   resulting basis index is exactly the next `prefixOnesIndex`.

3. A clean induction vehicle for `ghzCnotChain`.

   The circuit is currently defined as

   ```lean
   (List.finRange n).map fun i => ...
   ```

   so the mathematical induction is obvious, but the proof still needs a convenient circuit-side
   statement to induct on. The likely options are:

   - add a prefix-chain helper on the same `n + 1` qubits, or
   - prove a decomposition lemma for `List.finRange` and consume the chain one gate at a time.

   This is proof-engineering work rather than new mathematics, but it is still a real remaining gap.

4. A small run-circuit composition wrapper.

   The final theorem wants to move from

   ```lean
   runCircuit ([⟨hadamardAt 0⟩] ++ ghzCnotChain n) (allZeroState (n + 1))
   ```

   to "apply the Hadamard first, then run the CNOT chain". This helper is now proved as
   `runCircuit_append`, so the remaining work is no longer circuit-semantics plumbing but only the
   state-transition lemmas themselves.

## Planned Completion Order

The proof should be completed in the following order.

1. Prove the general Hadamard-step lemma by extensionality on amplitudes.

   The target state has support on exactly two indices, so the proof should split on:

   - `i = zeroIndex (n + 1)`
   - `i = prefixOnesIndex (n + 1) 1 (Nat.succ_le_succ (Nat.zero_le n))`
   - all other `i`

   If the permutation definitions become too opaque, the right fallback is to first isolate small
   lemmas saying qubit permutations preserve `allZeroState` and send the "last-bit one" basis state
   to the expected "first-bit one" basis state.

2. Add the arithmetic/index lemma needed for the CNOT step.

   The next basis index differs from the current one by turning on exactly one more trailing zero:
   in index arithmetic, that is adding the power of two for the target bit. If the existing
   `prefixOnesIndex_succ_val` lemma is not enough, a same-register increment lemma for
   `prefixOnesIndex` should be introduced.

3. Prove the CNOT propagation lemma for one gate.

   This should again be an amplitude-extensional proof: the all-zero branch is unchanged, the
   active branch is sent to the next prefix-ones basis state, and all other amplitudes stay zero.

4. Package the chain induction.

   Once the single-step lemma exists, prove that the first `k` CNOTs send the post-Hadamard state
   to `ghzProgressState n k _`. If induction directly on `List.finRange` is awkward, I will add an
   explicit fixed-arity prefix-chain helper and prove the result by recursion on `k`.

5. Finish `ghzCircuit_prepares_ghz`.

   The final theorem then becomes:

   - rewrite `ghzCircuit (n + 1)` as Hadamard followed by the chain,
   - apply the Hadamard-step lemma,
   - apply the chain induction result at `k = n`,
   - rewrite with `ghzProgressState_terminal`.

That should leave the GHZ file sorry-free without changing the high-level circuit definitions.
