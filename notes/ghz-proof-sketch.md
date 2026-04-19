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

The next useful Lean milestones are:

- prove the nontrivial Hadamard-step lemma
  `applyGate (hadamardAt 0) (allZeroState (n + 1)) = ghzProgressState n 0 (Nat.zero_le n)`
- prove one CNOT-step extension lemma
  sending `ghzProgressState n k hk` to `ghzProgressState n (k + 1) _`
  under the `k`th gate of `ghzCnotChain`

Once those states are named and those two transition lemmas exist, the rest should be a
straightforward induction over the nearest-neighbor CNOT chain.
