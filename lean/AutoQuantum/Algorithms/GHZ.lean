import AutoQuantum.Core.Circuit
import AutoQuantum.Lemmas.Gate
import AutoQuantum.Lemmas.Hilbert

/-!
# Greenberger-Horne-Zeilinger (GHZ) State Preparation

This module defines the standard `n`-qubit GHZ state and the corresponding
nearest-neighbor preparation circuit.

For `n + 1` qubits, the circuit is:
1. apply `H` to qubit `0`;
2. apply `CNOT` from qubit `0` to qubit `1`;
3. apply `CNOT` from qubit `1` to qubit `2`;
4. continue the chain up to qubit `n`.

The target state is
`(|0...0⟩ + |1...1⟩) / √2`.

The main correctness theorem is left as a structured proof sketch. Compared to
the QFT development, GHZ is simpler mathematically: the natural proof is by
tracking the state after the initial Hadamard and then inducting over the CNOT
chain.
-/

namespace AutoQuantum.GHZ

open AutoQuantum

/-- The computational-basis index `0...0` on `n` qubits. -/
def zeroIndex (n : ℕ) : Fin (2 ^ n) :=
  ⟨0, Nat.two_pow_pos n⟩

/-- The computational-basis index `1...1` on `n` qubits. -/
def onesIndex (n : ℕ) : Fin (2 ^ n) :=
  ⟨2 ^ n - 1, Nat.sub_lt (Nat.two_pow_pos n) (by decide)⟩

/-- The all-zero basis state `|0...0⟩`. -/
noncomputable def allZeroState (n : ℕ) : QState n :=
  basisState n (zeroIndex n)

/-- The all-one basis state `|1...1⟩`. -/
noncomputable def allOneState (n : ℕ) : QState n :=
  basisState n (onesIndex n)

private lemma one_lt_two_pow_succ (n : ℕ) : 1 < 2 ^ (n + 1) := by
  calc
    1 < 2 := by decide
    _ ≤ 2 * 2 ^ n := by
      exact Nat.mul_le_mul_left 2 (Nat.succ_le_of_lt (Nat.two_pow_pos n))
    _ = 2 ^ (n + 1) := by rw [pow_succ, mul_comm]

private lemma zeroIndex_ne_onesIndex (n : ℕ) : zeroIndex (n + 1) ≠ onesIndex (n + 1) := by
  intro h
  have hval : (onesIndex (n + 1)).val = 0 := by
    simpa [zeroIndex] using congrArg Fin.val h.symm
  have hpos : 0 < (onesIndex (n + 1)).val := by
    dsimp [onesIndex]
    exact Nat.sub_pos_of_lt (one_lt_two_pow_succ n)
  exact (Nat.ne_of_gt hpos) hval

/-- The `n`-qubit GHZ state. For `n = 0` this is defined as the unique basis state;
    for `n + 1` it is `( |0...0⟩ + |1...1⟩ ) / √2`. -/
noncomputable def ghzState : (n : ℕ) → QState n
  | 0 => allZeroState 0
  | n + 1 =>
      QState.mk
        (superpose ((1 : ℂ) / Real.sqrt 2) ((1 : ℂ) / Real.sqrt 2)
          (allZeroState (n + 1)).vec (allOneState (n + 1)).vec)
        (by
          apply superpose_norm_eq_one
          · exact QState.norm_eq_one (allZeroState (n + 1))
          · exact QState.norm_eq_one (allOneState (n + 1))
          · have hb := basisState_braket (n := n + 1) (zeroIndex (n + 1)) (onesIndex (n + 1))
            simpa [QState.braket, zeroIndex_ne_onesIndex n] using hb
          · have hcoef : Complex.normSq (((1 : ℂ) / Real.sqrt 2)) = 1 / 2 := by
              rw [Complex.normSq_div]
              norm_num [Real.sq_sqrt (show (0 : ℝ) ≤ 2 by positivity)]
            nlinarith [hcoef]
        )

/-- The nearest-neighbor CNOT chain on `n + 1` qubits:
    `CX 0 1; CX 1 2; ...; CX (n-1) n`. -/
noncomputable def ghzCnotChain (n : ℕ) : Circuit (n + 1) :=
  (List.finRange n).map fun i =>
    ⟨controlledAt i.castSucc i.succ (ne_of_lt i.castSucc_lt_succ) pauliX⟩

/-- The standard GHZ preparation circuit on `n` qubits. -/
noncomputable def ghzCircuit : (n : ℕ) → Circuit n
  | 0 => []
  | n + 1 => [⟨hadamardAt 0⟩] ++ ghzCnotChain n

/-- On three qubits, the general GHZ circuit specializes to the expected
    `H 0; CX 0 1; CX 1 2` pattern. -/
theorem ghzCircuit_three :
    ghzCircuit 3 =
      [⟨hadamardAt 0⟩,
       ⟨controlledAt 0 1 (by decide) pauliX⟩,
       ⟨controlledAt 1 2 (by decide) pauliX⟩] := by
  rfl

/-- Correctness sketch for GHZ preparation on `n + 1` qubits.

    Proof strategy:
    1. show `hadamardAt 0` maps `|0...0⟩` to
       `( |0...0⟩ + |10...0⟩ ) / √2`;
    2. prove by induction over `ghzCnotChain n` that after the `k`-th CNOT,
       the superposition is `( |0...0⟩ + |1...10...0⟩ ) / √2` with `k + 1`
       leading ones in the second branch;
    3. conclude that the final state is `( |0...0⟩ + |1...1⟩ ) / √2`.

    This theorem is intentionally left as `sorry`: the point of the GHZ module
    is to expose a substantially simpler correctness target than QFT while still
    recording the right circuit and the right proof shape. -/
theorem ghzCircuit_prepares_ghz (n : ℕ) :
    runCircuit (ghzCircuit (n + 1)) (allZeroState (n + 1)) = ghzState (n + 1) := by
  sorry

end AutoQuantum.GHZ
