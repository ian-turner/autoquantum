import AutoQuantum.Core.Circuit
import AutoQuantum.Core.Tensor
import AutoQuantum.Lemmas.Circuit
import AutoQuantum.Lemmas.Hilbert
import AutoQuantum.Lemmas.Tensor
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

open Matrix AutoQuantum Complex
open scoped Kronecker InnerProductSpace

/-! ## The GHZ state vector -/

/-- The index of the all-ones computational basis state: |1…1⟩. -/
def allOnesIndex (n : ℕ) : Fin (2 ^ n) :=
  ⟨2 ^ n - 1, Nat.pred_lt (pow_pos (by norm_num : (0 : ℕ) < 2) n).ne'⟩

lemma allOnesIndex_ne_zero {n : ℕ} (hn : n ≥ 1) : allOnesIndex n ≠ 0 := by
  intro h
  have : (allOnesIndex n).val = (0 : Fin (2 ^ n)).val := congrArg Fin.val h
  simp [allOnesIndex] at this
  have : 2 ^ n ≥ 2 := by
    calc 2 ^ n ≥ 2 ^ 1 := Nat.pow_le_pow_right (by norm_num) hn
         _ = 2           := by norm_num
  omega

/-- The GHZ state vector (unnormalized): |0…0⟩ + |1…1⟩. -/
noncomputable def ghzVector (n : ℕ) : QHilbert n :=
  superpose (1 : ℂ) (1 : ℂ) (basisState n 0).vec (basisState n (allOnesIndex n)).vec

/-- The GHZ state vector has norm √2 when n ≥ 1, and norm 2 when n = 0. -/
lemma norm_ghzVector (n : ℕ) : ‖ghzVector n‖ = if n = 0 then 2 else Real.sqrt 2 := by
  simp only [ghzVector, superpose, one_smul]
  split_ifs with h
  · -- n = 0: allOnesIndex 0 = 0, so both summands are the same basis state
    subst h
    have heq : allOnesIndex 0 = 0 := Fin.ext (by simp [allOnesIndex])
    rw [heq, ← two_smul ℂ (basisState 0 0).vec, norm_smul,
        (basisState 0 0).norm_eq_one, mul_one]
    norm_num
  · -- n ≥ 1: the two basis states are orthogonal, so ‖u + v‖ = √(‖u‖² + ‖v‖²) = √2
    have hn : n ≥ 1 := by omega
    have hne : (0 : Fin (2 ^ n)) ≠ allOnesIndex n := (allOnesIndex_ne_zero hn).symm
    have horth : @inner ℂ (QHilbert n) _ (basisState n 0).vec (basisState n (allOnesIndex n)).vec = 0 := by
      simpa [hne] using basisState_braket (n := n) (0 : Fin (2 ^ n)) (allOnesIndex n)
    have hkey : ‖(basisState n 0).vec + (basisState n (allOnesIndex n)).vec‖ ^ 2 = 2 := by
      rw [@norm_add_sq ℂ (QHilbert n) _ _ _, horth]
      simp
      norm_num
    rw [← Real.sqrt_sq (norm_nonneg _), hkey]

/-- The normalized GHZ state. -/
noncomputable def ghzState (n : ℕ) : QState n :=
  match n with
  | 0 => basisState 0 0
  | n + 1 => QState.mk ((1 / Real.sqrt 2 : ℂ) • ghzVector (n + 1)) (by
      have hpos : Real.sqrt 2 > 0 := Real.sqrt_pos.mpr (by norm_num : (0 : ℝ) < 2)
      calc
        ‖(1 / Real.sqrt 2 : ℂ) • ghzVector (n + 1)‖ = |Real.sqrt 2|⁻¹ * Real.sqrt 2 := by
          simp [norm_smul, norm_ghzVector]
        _ = (Real.sqrt 2)⁻¹ * Real.sqrt 2 := by rw [abs_of_pos hpos]
        _ = 1 := by field_simp [hpos.ne'])

/-! ## The GHZ preparation circuit -/

/-- The GHZ circuit on n qubits (requires n ≥ 1).
    Hadamard on qubit 0, then CNOT from qubit 0 to each qubit i.succ. -/
noncomputable def ghzCircuit (n : ℕ) (hn : n ≥ 1) : Circuit n :=
  match n, hn with
  | 0, h => by
      exfalso
      omega
  | n + 1, _ =>
      [⟨hadamardAt 0⟩] ++
      (List.finRange n).map fun i =>
        ⟨controlledAt 0 i.succ (Ne.symm (Fin.succ_ne_zero i)) pauliX⟩

/-! ## Correctness theorem -/



theorem ghz_correct_one :
    runCircuit (ghzCircuit 1 (by omega)) (basisState 1 0) = ghzState 1 := by
  simp [ghzCircuit, ghzState, ghzVector, allOnesIndex, superpose]
  sorry

theorem ghz_correct_two :
    runCircuit (ghzCircuit 2 (by omega)) (basisState 2 0) = ghzState 2 := by
  sorry

/-- The GHZ circuit applied to |0…0⟩ yields the GHZ state. -/
theorem ghz_correct (n : ℕ) (hn : n ≥ 1) :
    runCircuit (ghzCircuit n hn) (basisState n 0) = ghzState n := by
  sorry

end AutoQuantum.GHZ