import AutoQuantum.Core.Circuit
import AutoQuantum.Lemmas.Circuit
import AutoQuantum.Lemmas.Hilbert
import Mathlib.Algebra.BigOperators.Fin
import Mathlib.Tactic

/-!
# Greenberger–Horne–Zeilinger (GHZ) State Preparation

This module defines the GHZ state and a circuit that prepares it from the |0…0⟩ state.

The GHZ state on n qubits is the entangled state:
  |GHZ⟩ = (|0…0⟩ + |1…1⟩) / √2

The preparation circuit is:
  1. Apply a Hadamard gate to the first qubit (qubit 0)
  2. Apply CNOT from qubit 0 to qubit 1, then from qubit 0 to qubit 2, …, up to qubit (n-1)

For n = 1, the circuit is just a Hadamard gate, producing |+⟩ = (|0⟩+|1⟩)/√2,
which coincides with the 1-qubit GHZ state.

## References

- Nielsen & Chuang, "Quantum Computation and Quantum Information", §1.3.6 (page 31)
- Greenberger, Horne, Zeilinger, "Bell's theorem without inequalities" (1990)
- `notes/ghz-formalization-plan.md` for proof strategy (to be written)
-/

namespace AutoQuantum.GHZ

open Matrix AutoQuantum
open scoped Kronecker

/-! ## The GHZ state vector -/

/-- The index of the all-ones computational basis state: |1…1⟩. -/
def allOnesIndex (n : ℕ) : Fin (2 ^ n) :=
  ⟨2 ^ n - 1, by
    have h : 0 < 2 ^ n := pow_pos (by norm_num : 0 < 2) n
    exact Nat.pred_lt (ne_of_gt h)⟩

lemma allOnesIndex_ne_zero {n : ℕ} (hn : n ≥ 1) : allOnesIndex n ≠ 0 := by
  intro h
  have hpos : 0 < 2 ^ n := pow_pos (by norm_num : 0 < 2) n
  have : (allOnesIndex n).val = (0 : Fin (2 ^ n)).val := congrArg Fin.val h
  simp [allOnesIndex] at this
  have hpow : 2 ^ n ≥ 2 := by
    calc
      2 ^ n ≥ 2 ^ 1 := Nat.pow_le_pow_right (by norm_num) hn
      _ = 2 := by norm_num
  omega

/-- The GHZ state vector (unnormalized): |0…0⟩ + |1…1⟩. -/
noncomputable def ghzVector (n : ℕ) : QHilbert n :=
  superpose (1 : ℂ) (1 : ℂ) (basisState n 0).vec (basisState n (allOnesIndex n)).vec

/-- The GHZ state vector has norm √2 when n ≥ 1, and norm 2 when n = 0. -/
lemma norm_ghzVector (n : ℕ) : ‖ghzVector n‖ = if n = 0 then 2 else Real.sqrt 2 := by
  sorry

/-- The normalized GHZ state. -/
noncomputable def ghzState (n : ℕ) : QState n :=
  match n with
  | 0 => basisState 0 0
  | n + 1 => QState.mk ((1 / Real.sqrt 2 : ℂ) • ghzVector (n + 1)) (by
      simp [norm_smul, norm_ghzVector]
      sorry)

/-! ## The GHZ preparation circuit -/

/-- The GHZ circuit on n qubits.
    For n = 0: empty circuit (trivial)
    For n = 1: just a Hadamard on qubit 0
    For n ≥ 2: Hadamard on qubit 0 followed by CNOT from qubit 0 to each qubit i > 0. -/
noncomputable def ghzCircuit (n : ℕ) : Circuit n :=
  match n with
  | 0 => []
  | 1 => [⟨hadamardAt 0⟩]
  | n' + 2 =>
      let hadamardStep : Circuit (n' + 2) := [⟨hadamardAt 0⟩]
      let cnotSteps : Circuit (n' + 2) :=
        ((List.finRange (n' + 2)).filterMap fun i =>
          if h : i ≠ 0 then
            let h' : (0 : Fin (n' + 2)) ≠ i := Ne.symm h
            some ⟨controlledAt (0 : Fin (n' + 2)) i h' pauliX⟩
          else none)
      hadamardStep ++ cnotSteps

/-! ## Correctness theorem -/

theorem ghz_correct_zero :
    runCircuit (ghzCircuit 0) (basisState 0 0) = ghzState 0 := by
  simp [ghzCircuit, ghzState, runCircuit, circuitMatrix, applyGate]
  apply Subtype.ext
  rfl

theorem ghz_correct_one :
    runCircuit (ghzCircuit 1) (basisState 1 0) = ghzState 1 := by
  simp [ghzCircuit, ghzState, ghzVector, allOnesIndex, superpose]
  sorry

theorem ghz_correct_two :
    runCircuit (ghzCircuit 2) (basisState 2 0) = ghzState 2 := by
  sorry

/-- The GHZ circuit applied to |0…0⟩ yields the GHZ state. -/
theorem ghz_correct (n : ℕ) :
    runCircuit (ghzCircuit n) (basisState n 0) = ghzState n := by
  sorry

end AutoQuantum.GHZ