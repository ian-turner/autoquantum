import AutoQuantum.Core.Tensor
import AutoQuantum.Core.Gate
import AutoQuantum.Lemmas.Gate
import Mathlib.LinearAlgebra.Matrix.Kronecker

/-!
# Tensor Product Lemmas

Properties of the tensor product operations defined in `AutoQuantum.Core.Tensor`:
norm preservation and the action of tensor-embedded gates on product states.

This file is part of the **Lemmas** module and may be generated or elaborated
by AI assistants.
-/

namespace AutoQuantum

open scoped InnerProductSpace Kronecker

/-! ## Norm preservation -/

/-- The tensor product of unit-norm vectors is unit-norm.
    Proof: ‖tensorVec ψ φ‖² = ∑_{a,b} |ψ a|²|φ b|² = ‖ψ‖²·‖φ‖² = 1. -/
lemma tensorVec_norm {k m : ℕ} (ψ : QHilbert k) (φ : QHilbert m)
    (hψ : ‖ψ‖ = 1) (hφ : ‖φ‖ = 1) : ‖tensorVec ψ φ‖ = 1 := by
  simpa [tensorState, QState.vec, QState.mk] using
    (QState.norm_eq_one (tensorState (QState.mk ψ hψ) (QState.mk φ hφ)))

/-! ## Tensor-product gate action -/

/-- Applying `tensorWithId m U` (U ⊗ I_m) to a tensor state `ψ ⊗ φ` acts only on the
    first factor: the result is `(U ψ) ⊗ φ`. -/
lemma tensorWithId_apply {k m : ℕ} (U : QGate k) (ψ : QState k) (φ : QState m) :
    applyGate (tensorWithId m U) (tensorState ψ φ) = tensorState (applyGate U ψ) φ := by
  apply Subtype.ext
  let e : Fin (2 ^ k) × Fin (2 ^ m) ≃ Fin (2 ^ (k + m)) :=
    finProdFinEquiv.trans <| finCongr (show 2 ^ k * 2 ^ m = 2 ^ (k + m) by rw [pow_add])
  let Im : Matrix (Fin (2 ^ m)) (Fin (2 ^ m)) ℂ := ((1 : QGate m) : Matrix _ _ ℂ)
  ext i
  obtain ⟨⟨a, b⟩, rfl⟩ := e.surjective i
  show (applyGate (tensorWithId m U) (tensorState ψ φ)).vec (e (a, b)) =
       (tensorState (applyGate U ψ) φ).vec (e (a, b))
  rw [applyGate_vec_apply]
  have hrhs : (tensorState (applyGate U ψ) φ).vec (e (a, b)) =
      (applyGate U ψ).vec a * φ.vec b := by
    show tensorVec (applyGate U ψ).vec φ.vec (e (a, b)) = _
    exact tensorVec_apply _ _ a b
  rw [hrhs]
  rw [← Fintype.sum_equiv e
      (fun p => (tensorWithId m U : Matrix _ _ ℂ) (e (a, b)) (e p) * (tensorState ψ φ).vec (e p))
      (fun j => (tensorWithId m U : Matrix _ _ ℂ) (e (a, b)) j * (tensorState ψ φ).vec j)
      (fun p => rfl)]
  simp_rw [Fintype.sum_prod_type]
  have hmat : ∀ x : Fin (2 ^ k), ∀ y : Fin (2 ^ m),
      (tensorWithId m U : Matrix _ _ ℂ) (e (a, b)) (e (x, y)) =
        (U : Matrix _ _ ℂ) a x * Im b y := by
    intro x y
    show (Matrix.reindex e e ((U : Matrix _ _ ℂ) ⊗ₖ Im)) (e (a, b)) (e (x, y)) = _
    simp [Matrix.reindex_apply, Matrix.submatrix_apply, Equiv.symm_apply_apply]
  have htensor : ∀ x : Fin (2 ^ k), ∀ y : Fin (2 ^ m),
      (tensorState ψ φ).vec (e (x, y)) = ψ.vec x * φ.vec y :=
    fun x y => tensorVec_apply ψ.vec φ.vec x y
  have hImby : ∀ y : Fin (2 ^ m), Im b y = if b = y then 1 else 0 := fun _ => rfl
  simp_rw [hmat, htensor, hImby, mul_ite, mul_one, mul_zero, ite_mul, zero_mul]
  simp only [Finset.sum_ite_eq, Finset.mem_univ, if_true]
  simp_rw [← mul_assoc]
  rw [← Finset.sum_mul]
  congr 1

/-- Applying `idTensorWith m U` (I_m ⊗ U) to a tensor state `ψ ⊗ φ` acts only on the
    second factor: the result is `ψ ⊗ (U φ)`. -/
lemma idTensorWith_apply {k m : ℕ} (U : QGate k) (ψ : QState m) (φ : QState k) :
    applyGate (idTensorWith m U) (tensorState ψ φ) = tensorState ψ (applyGate U φ) := by
  apply Subtype.ext
  let e : Fin (2 ^ m) × Fin (2 ^ k) ≃ Fin (2 ^ (m + k)) :=
    finProdFinEquiv.trans <| finCongr (show 2 ^ m * 2 ^ k = 2 ^ (m + k) by rw [pow_add])
  let Im : Matrix (Fin (2 ^ m)) (Fin (2 ^ m)) ℂ := ((1 : QGate m) : Matrix _ _ ℂ)
  ext i
  obtain ⟨⟨a, b⟩, rfl⟩ := e.surjective i
  show (applyGate (idTensorWith m U) (tensorState ψ φ)).vec (e (a, b)) =
       (tensorState ψ (applyGate U φ)).vec (e (a, b))
  rw [applyGate_vec_apply]
  have hrhs : (tensorState ψ (applyGate U φ)).vec (e (a, b)) =
      ψ.vec a * (applyGate U φ).vec b := by
    show tensorVec ψ.vec (applyGate U φ).vec (e (a, b)) = _
    exact tensorVec_apply _ _ a b
  rw [hrhs]
  rw [← Fintype.sum_equiv e
      (fun p => (idTensorWith m U : Matrix _ _ ℂ) (e (a, b)) (e p) * (tensorState ψ φ).vec (e p))
      (fun j => (idTensorWith m U : Matrix _ _ ℂ) (e (a, b)) j * (tensorState ψ φ).vec j)
      (fun p => rfl)]
  simp_rw [Fintype.sum_prod_type]
  have hmat : ∀ x : Fin (2 ^ m), ∀ y : Fin (2 ^ k),
      (idTensorWith m U : Matrix _ _ ℂ) (e (a, b)) (e (x, y)) =
        Im a x * (U : Matrix _ _ ℂ) b y := by
    intro x y
    change (Matrix.reindex e e (Im ⊗ₖ (U : Matrix _ _ ℂ))) (e (a, b)) (e (x, y)) =
        Im a x * (U : Matrix _ _ ℂ) b y
    simp [Matrix.reindex_apply, Matrix.submatrix_apply, Equiv.symm_apply_apply]
  have htensor : ∀ x : Fin (2 ^ m), ∀ y : Fin (2 ^ k),
      (tensorState ψ φ).vec (e (x, y)) = ψ.vec x * φ.vec y :=
    fun x y => tensorVec_apply ψ.vec φ.vec x y
  have hImax : ∀ x : Fin (2 ^ m), Im a x = if a = x then 1 else 0 := fun _ => rfl
  simp_rw [hmat, htensor]
  -- Reorder factors: Im a x * U b y * (ψ.vec x * φ.vec y) = Im a x * ψ.vec x * (U b y * φ.vec y)
  simp_rw [show ∀ (x : Fin (2 ^ m)) (y : Fin (2 ^ k)),
      Im a x * (U : Matrix _ _ ℂ) b y * (ψ.vec x * φ.vec y) =
        Im a x * ψ.vec x * ((U : Matrix _ _ ℂ) b y * φ.vec y) from fun x y => by ring]
  -- Factor the y-independent part out of the y-sum
  simp_rw [← Finset.mul_sum]
  -- Factor the x-independent part out of the x-sum
  rw [← Finset.sum_mul]
  -- Collapse ∑ x, Im a x * ψ.vec x = ψ.vec a
  have hcollapse : ∑ x : Fin (2 ^ m), Im a x * ψ.vec x = ψ.vec a := by
    simp_rw [hImax, ite_mul, one_mul, zero_mul]
    simp [Finset.sum_ite_eq, Finset.mem_univ]
  rw [hcollapse, ← applyGate_vec_apply]

end AutoQuantum
