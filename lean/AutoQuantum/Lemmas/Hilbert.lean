import AutoQuantum.Core.Hilbert
import Mathlib.Analysis.InnerProductSpace.PiL2
import Mathlib.Algebra.BigOperators.Fin

/-!
# Hilbert Space Lemmas

Mathematical properties of the Hilbert space, inner product, basis states, and
superposition operator defined in `AutoQuantum.Core.Hilbert`.

This file is part of the **Lemmas** module and may be generated or elaborated
by AI assistants. All definitions it depends on are in `Core.Hilbert`.
-/

namespace AutoQuantum

open scoped InnerProductSpace
open Complex

/-- The probability amplitude ⟨φ|ψ⟩ has norm ≤ 1 (Cauchy-Schwarz). -/
lemma QState.braket_norm_le_one {n : ℕ} (phi psi : QState n) : ‖braket phi psi‖ ≤ 1 := by
  have h := norm_inner_le_norm (𝕜 := ℂ) phi.vec psi.vec
  rw [phi.norm_eq_one, psi.norm_eq_one, mul_one] at h
  exact h

/-- Basis states are orthonormal: ⟨j|k⟩ = δ_{j,k}. -/
lemma basisState_braket {n : ℕ} (j k : Fin (2 ^ n)) :
    QState.braket (basisState n j) (basisState n k) = if j = k then 1 else 0 := by
  simp only [QState.braket, basisState, QState.vec]
  have h : Orthonormal ℂ (fun i : Fin (2 ^ n) => EuclideanSpace.single i (1 : ℂ)) :=
    EuclideanSpace.orthonormal_single
  rw [orthonormal_iff_ite] at h
  exact h j k

/-! ## Tensor product norm -/

/-- The tensor product of unit-norm vectors is unit-norm.
    Proof sketch: ‖tensorVec ψ φ‖² = ∑_{a,b} |ψ a|²|φ b|² = ‖ψ‖²·‖φ‖² = 1.
    Uses PiLp.norm_sq_eq_of_L2 and Finset.sum_product. -/
lemma tensorVec_norm {k m : ℕ} (ψ : QHilbert k) (φ : QHilbert m)
    (hψ : ‖ψ‖ = 1) (hφ : ‖φ‖ = 1) : ‖tensorVec ψ φ‖ = 1 := by
  sorry

/-! ## Uniform superposition norm -/

/-- The uniform superposition vector has unit norm.
    Proof sketch:
      ‖(1/√(2^n)) • ∑_k e_k‖² = (1/(2^n)) * ‖∑_k e_k‖²
      ‖∑_k e_k‖² = ∑_j ∑_k ⟨e_j, e_k⟩ = ∑_k 1 = 2^n   (by basisState_braket + inner linearity)
      so the product is 1. -/
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

end AutoQuantum
