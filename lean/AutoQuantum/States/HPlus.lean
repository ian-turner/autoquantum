import AutoQuantum.Core.Circuit
import AutoQuantum.Core.Tensor
import Mathlib.Algebra.BigOperators.Fin
import Mathlib.Tactic

/-!
# Uniform Superposition State |+⟩^⊗n

The n-qubit uniform superposition state is:
  |+⟩^⊗n = H^⊗n |0…0⟩ = (1/√(2^n)) ∑_{k=0}^{2^n-1} |k⟩
-/

open AutoQuantum Complex
open scoped InnerProductSpace

/-- The uniform superposition vector for n qubits: `(1/√(2^n)) ∑_k |k⟩`. -/
noncomputable def hPlusVector (n : ℕ) : QHilbert n :=
  (1 / Real.sqrt (2 ^ n : ℝ) : ℂ) • ∑ k : Fin (2 ^ n), (basisState n k).vec

/-- The uniform superposition state |+⟩^⊗n. -/
noncomputable def hPlusState (n : ℕ) : QState n :=
  QState.mk (hPlusVector n) (by
    simp only [hPlusVector]
    rw [norm_smul]
    have hpos : (0 : ℝ) < 2 ^ n := by positivity
    -- Each coordinate of ∑_k |k⟩ equals 1 (each basis vector contributes 1 at its own index)
    have hcoord : ∀ i : Fin (2 ^ n),
        (∑ k : Fin (2 ^ n), (basisState n k).vec) i = 1 := fun i => by
      show (∑ k : Fin (2 ^ n), (basisState n k).vec).ofLp i = 1
      simp only [WithLp.ofLp_sum, basisState, QState.vec, Finset.sum_apply,
                 PiLp.single_apply]
      simp
    -- ‖∑_k |k⟩‖ = √(2^n)
    have hnorm : ‖∑ k : Fin (2 ^ n), (basisState n k).vec‖ = Real.sqrt (2 ^ n : ℝ) := by
      have hsq : ‖∑ k : Fin (2 ^ n), (basisState n k).vec‖ ^ 2 = (2 ^ n : ℝ) := by
        rw [EuclideanSpace.norm_sq_eq]
        simp_rw [hcoord, norm_one, one_pow]
        simp [Fintype.card_fin]
      nlinarith [norm_nonneg (∑ k : Fin (2 ^ n), (basisState n k).vec),
                 Real.sq_sqrt hpos.le, Real.sqrt_nonneg (2 ^ n : ℝ)]
    rw [hnorm, norm_div, norm_one, Complex.norm_real,
        Real.norm_of_nonneg (Real.sqrt_nonneg _)]
    exact div_mul_cancel₀ 1 (Real.sqrt_ne_zero'.mpr hpos))
