import AutoQuantum.Core.Circuit
import AutoQuantum.Lemmas.Circuit
import AutoQuantum.Lemmas.Hilbert
import Mathlib.Algebra.BigOperators.Fin
import Mathlib.Tactic

/-!
# Uniform Superposition State |+⟩^⊗n

This module defines the n-qubit uniform superposition state and the circuit
that prepares it from |0…0⟩ by applying a Hadamard gate to each qubit.

The target state is:
  |+⟩^⊗n = H^⊗n |0…0⟩ = (1/√(2^n)) ∑_{k=0}^{2^n-1} |k⟩

The preparation circuit applies `hadamardAt i` for each i : Fin n.

## References

- Nielsen & Chuang, §1.3 (Hadamard gate and superposition)
-/

namespace AutoQuantum.HPlus

open Matrix AutoQuantum Complex
open scoped Kronecker InnerProductSpace

/-! ## The uniform superposition state -/

/-- The uniform superposition vector for n qubits: `(1/√(2^n)) ∑_k |k⟩`. -/
noncomputable def hPlusVector (n : ℕ) : QHilbert n :=
  (1 / Real.sqrt (2 ^ n : ℝ) : ℂ) • ∑ k : Fin (2 ^ n), (basisState n k).vec

/-- The uniform superposition vector has unit norm. -/
lemma hPlusVector_norm (n : ℕ) : ‖hPlusVector n‖ = 1 := by
  have hcoord : ∀ j : Fin (2 ^ n), hPlusVector n j = (1 / Real.sqrt (2 ^ n : ℝ) : ℂ) := by
    intro j
    simp [hPlusVector, basisState, QState.vec]
  have hsq : ‖hPlusVector n‖ ^ 2 = 1 := by
    rw [PiLp.norm_sq_eq_of_L2]
    calc
      ∑ j : Fin (2 ^ n), ‖hPlusVector n j‖ ^ 2
          = ∑ _j : Fin (2 ^ n), ‖(1 / Real.sqrt (2 ^ n : ℝ) : ℂ)‖ ^ 2 := by
              simp [hcoord]
      _ = (2 ^ n : ℝ) * ‖(1 / Real.sqrt (2 ^ n : ℝ) : ℂ)‖ ^ 2 := by
            simp [Nat.cast_pow]
      _ = (2 ^ n : ℝ) * ((1 / Real.sqrt (2 ^ n : ℝ)) ^ 2) := by
            simp
      _ = 1 := by
            rcases Nat.eq_zero_or_pos (2 ^ n) with hpow | hpow
            · exfalso
              exact pow_ne_zero n (by norm_num) hpow
            · have hpow' : (0 : ℝ) < (2 ^ n : ℝ) := by exact_mod_cast hpow
              have hsqrt : Real.sqrt (2 ^ n : ℝ) ≠ 0 := Real.sqrt_ne_zero'.mpr hpow'
              field_simp [hsqrt]
              rw [Real.sq_sqrt (show (0 : ℝ) ≤ (2 ^ n : ℝ) by positivity)]
  calc
    ‖hPlusVector n‖ = Real.sqrt (‖hPlusVector n‖ ^ 2) := (Real.sqrt_sq (norm_nonneg _)).symm
    _ = Real.sqrt 1 := by rw [hsq]
    _ = 1 := Real.sqrt_one

/-- The uniform superposition state |+⟩^⊗n: the equal-weight sum of all basis states.
    For n = 0 this is the unique 1-dimensional unit vector |∅⟩ = |0⟩. -/
noncomputable def hPlusState (n : ℕ) : QState n :=
  QState.mk (hPlusVector n) (hPlusVector_norm n)

/-! ## The uniform superposition circuit -/

/-- The circuit that produces |+⟩^⊗n: apply Hadamard to every qubit. -/
noncomputable def hPlusCircuit (n : ℕ) : Circuit n :=
  (List.finRange n).map fun i => ⟨hadamardAt i⟩

/-! ## Correctness theorem -/

/-- Applying a Hadamard to every qubit of |0…0⟩ yields the uniform superposition state. -/
theorem hPlus_correct (n : ℕ) :
    runCircuit (hPlusCircuit n) (basisState n 0) = hPlusState n := by
  sorry

end AutoQuantum.HPlus
