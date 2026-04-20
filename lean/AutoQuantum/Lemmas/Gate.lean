import AutoQuantum.Core.Gate
import AutoQuantum.Core.Qubit
import AutoQuantum.Core.Hilbert

/-!
# Gate Lemmas

Derived properties of the quantum gates defined in `AutoQuantum.Core.Gate`:
the `applyGate` composition laws, basis-state action, and self-inverse identities.

This file is part of the **Lemmas** module and may be generated or elaborated
by AI assistants.
-/

namespace AutoQuantum

/-! ## applyGate laws -/

/-- The identity gate leaves every state unchanged. -/
lemma applyGate_one {k : ℕ} (ψ : QState k) :
    applyGate (1 : QGate k) ψ = ψ := by
  apply Subtype.ext
  change Matrix.toEuclideanLin
      ((1 : QGate k) : Matrix (Fin (2 ^ k)) (Fin (2 ^ k)) ℂ) ψ.vec = ψ.vec
  simp

/-- Composing gates corresponds to sequential application. -/
lemma applyGate_mul {k : ℕ} (U V : QGate k) (ψ : QState k) :
    applyGate (U * V) ψ = applyGate U (applyGate V ψ) := by
  apply Subtype.ext
  change Matrix.toEuclideanLin
      (((U * V : QGate k) : Matrix (Fin (2 ^ k)) (Fin (2 ^ k)) ℂ)) ψ.vec
      = Matrix.toEuclideanLin (U : Matrix (Fin (2 ^ k)) (Fin (2 ^ k)) ℂ)
          (Matrix.toEuclideanLin (V : Matrix (Fin (2 ^ k)) (Fin (2 ^ k)) ℂ) ψ.vec)
  simp

/-! ## applyGate coordinate formula -/

/-- The i-th coordinate of `applyGate U ψ` is the dot product of row i of U with ψ. -/
lemma applyGate_vec_apply {k : ℕ} (U : QGate k) (ψ : QState k) (i : Fin (2 ^ k)) :
    (applyGate U ψ).vec i =
      ∑ j : Fin (2 ^ k), (U : Matrix (Fin (2 ^ k)) (Fin (2 ^ k)) ℂ) i j * ψ.vec j := by
  change Matrix.toEuclideanLin (U : Matrix (Fin (2 ^ k)) (Fin (2 ^ k)) ℂ) ψ.vec i = _
  simp [Matrix.toEuclideanLin, Matrix.toLin'_apply, Matrix.mulVec]
  rfl

/-- Applying gate U to basis state |j⟩ gives the j-th column of U's matrix. -/
lemma applyGate_basisState_vec_apply {k : ℕ} (U : QGate k) (j i : Fin (2 ^ k)) :
    (applyGate U (basisState k j)).vec i =
      (U : Matrix (Fin (2 ^ k)) (Fin (2 ^ k)) ℂ) i j := by
  rw [applyGate_vec_apply]
  simp [basisState, QState.vec, PiLp.single_apply, mul_comm]

/-! ## Hadamard action on computational basis -/

/-- H|0⟩ = |+⟩: Hadamard maps the zero state to the uniform superposition. -/
lemma hadamard_apply_ket0 : applyGate hadamard ket0 = ketPlus := by
  apply Subtype.ext
  ext i
  show (applyGate hadamard ket0).vec i = ketPlus.vec i
  rw [applyGate_vec_apply]
  fin_cases i
  · simp [hadamard, hadamardMatrix, ket0, basisState, QState.vec,
          PiLp.single_apply, ketPlus, superpose, QState.mk, ket1]
  · simp [hadamard, hadamardMatrix, ket0, basisState, QState.vec,
          PiLp.single_apply, ketPlus, superpose, QState.mk, ket1]

/-- H|1⟩ = |−⟩: Hadamard maps the one state to the minus superposition. -/
lemma hadamard_apply_ket1 : applyGate hadamard ket1 = ketMinus := by
  apply Subtype.ext
  ext i
  show (applyGate hadamard ket1).vec i = ketMinus.vec i
  rw [applyGate_vec_apply]
  fin_cases i
  · simp [hadamard, hadamardMatrix, ket1, basisState, QState.vec,
          PiLp.single_apply, ketMinus, superpose, QState.mk, ket0]
  · simp [hadamard, hadamardMatrix, ket1, basisState, QState.vec,
          PiLp.single_apply, ketMinus, superpose, QState.mk, ket0]

/-! ## Gate self-inverse identities -/

/-- H² = I (Hadamard is self-inverse). -/
lemma hadamard_mul_self : hadamard * hadamard = (1 : QGate 1) := by
  apply Subtype.ext
  have hne : Real.sqrt 2 ≠ 0 := Real.sqrt_ne_zero'.mpr (by norm_num)
  ext i j
  fin_cases i <;> fin_cases j <;>
    simp [hadamard, hadamardMatrix]
  all_goals
    have hneC : (Real.sqrt 2 : ℂ) ≠ 0 := by
      exact_mod_cast hne
    field_simp [hneC]
    ring_nf
    have hsq : ((Real.sqrt 2 : ℂ) ^ 2) = 2 := by
      exact_mod_cast Real.sq_sqrt (show (0 : ℝ) ≤ 2 by norm_num)
    simpa using hsq.symm

/-- CNOT² = I (CNOT is self-inverse). -/
lemma cnot_mul_self : cnot * cnot = (1 : QGate 2) := by
  apply Subtype.ext
  ext i j
  fin_cases i <;> fin_cases j <;>
    simp [cnot, cnotMatrix]

/-! ## Tensor-product gate action -/

open scoped Kronecker in
/-- Applying `tensorWithId m U` (U ⊗ I_m) to a tensor state `ψ ⊗ φ` acts only on the
    first factor: the result is `(U ψ) ⊗ φ`. -/
lemma tensorWithId_apply {k m : ℕ} (U : QGate k) (ψ : QState k) (φ : QState m) :
    applyGate (tensorWithId m U) (tensorState ψ φ) = tensorState (applyGate U ψ) φ := by
  apply Subtype.ext
  -- Use the exact same e as in tensorWithId so the `show` step unifies
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
  -- Im b y = if b = y then 1 else 0 (Im = (1 : QGate m) cast to matrix, which equals 1)
  have hImby : ∀ y : Fin (2 ^ m), Im b y = if b = y then 1 else 0 := fun _ => rfl
  simp_rw [hmat, htensor, hImby, mul_ite, mul_one, mul_zero, ite_mul, zero_mul]
  -- Collapse inner sum (Finset.sum_ite_eq uses a = x pattern, matching our b = y)
  simp only [Finset.sum_ite_eq, Finset.mem_univ, if_true]
  simp_rw [← mul_assoc]
  rw [← Finset.sum_mul]
  congr 1

end AutoQuantum
