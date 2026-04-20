import AutoQuantum.Core.Hilbert

/-!
# Tensor Products of Quantum States [Core]

Defines the Kronecker (tensor) product of quantum state vectors and the
lifted `tensorState` operation on normalized states.

This file is part of the **Core** module and is intended for human review.
It contains only the definitions and the minimal proofs required to construct
`tensorState` from its normalization witness.
-/

namespace AutoQuantum

open scoped InnerProductSpace

/-! ## Tensor product of state vectors -/

/-- The Kronecker (tensor) product of two quantum state vectors.
    The output index set Fin(2^(k+m)) is identified with Fin(2^k) × Fin(2^m) via the standard
    `finProdFinEquiv` bijection; the (a,b) component of the result is ψ(a)·φ(b). -/
noncomputable def tensorVec {k m : ℕ} (ψ : QHilbert k) (φ : QHilbert m) : QHilbert (k + m) :=
  let e : Fin (2 ^ k) × Fin (2 ^ m) ≃ Fin (2 ^ (k + m)) :=
    finProdFinEquiv.trans (finCongr (pow_add 2 k m).symm)
  ∑ a : Fin (2 ^ k), ∑ b : Fin (2 ^ m),
    (ψ a * φ b) • (EuclideanSpace.single (e (a, b)) (1 : ℂ))

/-- The coordinate formula for tensorVec: at index e(a,b), the value is ψ(a)·φ(b). -/
lemma tensorVec_apply {k m : ℕ} (ψ : QHilbert k) (φ : QHilbert m) (a : Fin (2^k)) (b : Fin (2^m)) :
    let e : Fin (2 ^ k) × Fin (2 ^ m) ≃ Fin (2 ^ (k + m)) :=
      finProdFinEquiv.trans (finCongr (pow_add 2 k m).symm)
    tensorVec ψ φ (e (a, b)) = ψ a * φ b := by
  intro e; unfold tensorVec
  rw [WithLp.ofLp_sum]; simp_rw [WithLp.ofLp_sum]
  simp [WithLp.ofLp_smul, Pi.single_apply]
  change ∑ x : Fin (2 ^ k), ∑ y : Fin (2 ^ m),
      (if e (a, b) = e (x, y) then ψ x * φ y else 0) = ψ a * φ b
  rw [Finset.sum_eq_single a]
  · rw [Finset.sum_eq_single b]
    · simp
    · intro y _ hyb
      simp [show e (a, b) ≠ e (a, y) from fun h => hyb (congrArg Prod.snd (e.injective h)).symm]
    · exact fun h => absurd (Finset.mem_univ b) h
  · intro x _ hxa
    exact Finset.sum_eq_zero fun y _ => by
      simp [show e (a, b) ≠ e (x, y) from fun h => hxa (congrArg Prod.fst (e.injective h)).symm]
  · exact fun h => absurd (Finset.mem_univ a) h

/-- The tensor product of two normalized quantum states.
    Normalization follows by reindexing to the product basis and factoring the squared norm. -/
noncomputable def tensorState {k m : ℕ} (ψ : QState k) (φ : QState m) : QState (k + m) :=
  QState.mk (tensorVec ψ.vec φ.vec) (by
    let e : Fin (2 ^ k) × Fin (2 ^ m) ≃ Fin (2 ^ (k + m)) :=
      finProdFinEquiv.trans (finCongr (pow_add 2 k m).symm)
    have hψsq : ∑ a : Fin (2 ^ k), ‖ψ.vec a‖ ^ 2 = 1 := by
      rw [← PiLp.norm_sq_eq_of_L2, ψ.norm_eq_one, one_pow]
    have hφsq : ∑ b : Fin (2 ^ m), ‖φ.vec b‖ ^ 2 = 1 := by
      rw [← PiLp.norm_sq_eq_of_L2, φ.norm_eq_one, one_pow]
    have hcoord : ∀ p : Fin (2 ^ k) × Fin (2 ^ m),
        tensorVec ψ.vec φ.vec (e p) = ψ.vec p.1 * φ.vec p.2 := by
      intro ⟨a, b⟩; exact tensorVec_apply ψ.vec φ.vec a b
    have hsq : ‖tensorVec ψ.vec φ.vec‖ ^ 2 = 1 := by
      rw [PiLp.norm_sq_eq_of_L2]
      calc
        ∑ i : Fin (2 ^ (k + m)), ‖tensorVec ψ.vec φ.vec i‖ ^ 2
            = ∑ p : Fin (2 ^ k) × Fin (2 ^ m), ‖tensorVec ψ.vec φ.vec (e p)‖ ^ 2 :=
                (Fintype.sum_equiv e _ _ (fun p => rfl)).symm
        _ = ∑ p : Fin (2 ^ k) × Fin (2 ^ m), ‖ψ.vec p.1 * φ.vec p.2‖ ^ 2 := by
              simp [hcoord]
        _ = ∑ a : Fin (2 ^ k), ∑ b : Fin (2 ^ m), ‖ψ.vec a * φ.vec b‖ ^ 2 := by
              rw [Fintype.sum_prod_type]
        _ = ∑ a : Fin (2 ^ k), ∑ b : Fin (2 ^ m), (‖ψ.vec a‖ ^ 2) * (‖φ.vec b‖ ^ 2) := by
              simp_rw [norm_mul, mul_pow]
        _ = (∑ a : Fin (2 ^ k), ‖ψ.vec a‖ ^ 2) * ∑ b : Fin (2 ^ m), ‖φ.vec b‖ ^ 2 := by
              rw [Finset.sum_mul_sum]
        _ = 1 := by simp [hψsq, hφsq]
    rw [← Real.sqrt_sq (norm_nonneg _), hsq]; exact Real.sqrt_one)

end AutoQuantum
