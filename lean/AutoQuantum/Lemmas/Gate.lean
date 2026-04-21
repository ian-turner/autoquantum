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

open scoped Kronecker

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

/-! ## Tensor-embedding algebra -/

/-- Embedding on the first k qubits preserves multiplication. -/
lemma tensorWithId_mul {k : ℕ} (m : ℕ) (U V : QGate k) :
    tensorWithId m (U * V) = tensorWithId m U * tensorWithId m V := by
  apply Subtype.ext
  let e := tensorIndexEquiv k m
  let Im : Matrix (Fin (2 ^ m)) (Fin (2 ^ m)) ℂ := ((1 : QGate m) : Matrix _ _ ℂ)
  show ((tensorWithId m (U * V) : QGate (k + m)) :
      Matrix (Fin (2 ^ (k + m))) (Fin (2 ^ (k + m))) ℂ) =
    (((tensorWithId m U : QGate (k + m)) :
      Matrix (Fin (2 ^ (k + m))) (Fin (2 ^ (k + m))) ℂ) *
      ((tensorWithId m V : QGate (k + m)) :
        Matrix (Fin (2 ^ (k + m))) (Fin (2 ^ (k + m))) ℂ))
  have hkr :
      (((U * V : QGate k) : Matrix (Fin (2 ^ k)) (Fin (2 ^ k)) ℂ) ⊗ₖ Im) =
        (((U : Matrix (Fin (2 ^ k)) (Fin (2 ^ k)) ℂ) ⊗ₖ Im) *
          ((V : Matrix (Fin (2 ^ k)) (Fin (2 ^ k)) ℂ) ⊗ₖ Im)) := by
    simpa [Im] using
      (Matrix.mul_kronecker_mul
        (U : Matrix (Fin (2 ^ k)) (Fin (2 ^ k)) ℂ)
        (V : Matrix (Fin (2 ^ k)) (Fin (2 ^ k)) ℂ)
        Im Im)
  have hleft : ((tensorWithId m (U * V) : QGate (k + m)) :
      Matrix (Fin (2 ^ (k + m))) (Fin (2 ^ (k + m))) ℂ) =
        Matrix.reindex e e (((U * V : QGate k) : Matrix (Fin (2 ^ k)) (Fin (2 ^ k)) ℂ) ⊗ₖ Im) := rfl
  have hU : ((tensorWithId m U : QGate (k + m)) :
      Matrix (Fin (2 ^ (k + m))) (Fin (2 ^ (k + m))) ℂ) =
        Matrix.reindex e e ((U : Matrix (Fin (2 ^ k)) (Fin (2 ^ k)) ℂ) ⊗ₖ Im) := rfl
  have hV : ((tensorWithId m V : QGate (k + m)) :
      Matrix (Fin (2 ^ (k + m))) (Fin (2 ^ (k + m))) ℂ) =
        Matrix.reindex e e ((V : Matrix (Fin (2 ^ k)) (Fin (2 ^ k)) ℂ) ⊗ₖ Im) := rfl
  rw [hleft, hU, hV,
    ← Matrix.reindexAlgEquiv_apply (R := ℂ) (A := ℂ),
    ← Matrix.reindexAlgEquiv_apply (R := ℂ) (A := ℂ),
    ← Matrix.reindexAlgEquiv_apply (R := ℂ) (A := ℂ), hkr,
    Matrix.reindexAlgEquiv_mul (R := ℂ) (A := ℂ)]

/-- Embedding on the first k qubits preserves the identity gate. -/
@[simp]
lemma tensorWithId_one {k : ℕ} (m : ℕ) : tensorWithId m (1 : QGate k) = 1 := by
  apply Subtype.ext
  let e := tensorIndexEquiv k m
  let Im : Matrix (Fin (2 ^ m)) (Fin (2 ^ m)) ℂ := ((1 : QGate m) : Matrix _ _ ℂ)
  show ((tensorWithId m (1 : QGate k) : QGate (k + m)) :
      Matrix (Fin (2 ^ (k + m))) (Fin (2 ^ (k + m))) ℂ) =
    (1 : Matrix (Fin (2 ^ (k + m))) (Fin (2 ^ (k + m))) ℂ)
  have hleft : ((tensorWithId m (1 : QGate k) : QGate (k + m)) :
      Matrix (Fin (2 ^ (k + m))) (Fin (2 ^ (k + m))) ℂ) =
        Matrix.reindex e e (((1 : QGate k) : Matrix (Fin (2 ^ k)) (Fin (2 ^ k)) ℂ) ⊗ₖ Im) := rfl
  rw [hleft, ← Matrix.reindexAlgEquiv_apply (R := ℂ) (A := ℂ)]
  simp [Im]

/-- Embedding on the last k qubits preserves multiplication. -/
lemma idTensorWith_mul {k : ℕ} (m : ℕ) (U V : QGate k) :
    idTensorWith m (U * V) = idTensorWith m U * idTensorWith m V := by
  apply Subtype.ext
  let e := tensorIndexEquiv m k
  let Im : Matrix (Fin (2 ^ m)) (Fin (2 ^ m)) ℂ := ((1 : QGate m) : Matrix _ _ ℂ)
  show ((idTensorWith m (U * V) : QGate (m + k)) :
      Matrix (Fin (2 ^ (m + k))) (Fin (2 ^ (m + k))) ℂ) =
    (((idTensorWith m U : QGate (m + k)) :
      Matrix (Fin (2 ^ (m + k))) (Fin (2 ^ (m + k))) ℂ) *
      ((idTensorWith m V : QGate (m + k)) :
        Matrix (Fin (2 ^ (m + k))) (Fin (2 ^ (m + k))) ℂ))
  have hkr :
      (Im ⊗ₖ ((U * V : QGate k) : Matrix (Fin (2 ^ k)) (Fin (2 ^ k)) ℂ)) =
        ((Im ⊗ₖ (U : Matrix (Fin (2 ^ k)) (Fin (2 ^ k)) ℂ)) *
          (Im ⊗ₖ (V : Matrix (Fin (2 ^ k)) (Fin (2 ^ k)) ℂ))) := by
    simpa [Im] using
      (Matrix.mul_kronecker_mul
        Im Im
        (U : Matrix (Fin (2 ^ k)) (Fin (2 ^ k)) ℂ)
        (V : Matrix (Fin (2 ^ k)) (Fin (2 ^ k)) ℂ))
  have hleft : ((idTensorWith m (U * V) : QGate (m + k)) :
      Matrix (Fin (2 ^ (m + k))) (Fin (2 ^ (m + k))) ℂ) =
        Matrix.reindex e e (Im ⊗ₖ ((U * V : QGate k) : Matrix (Fin (2 ^ k)) (Fin (2 ^ k)) ℂ)) := rfl
  have hU : ((idTensorWith m U : QGate (m + k)) :
      Matrix (Fin (2 ^ (m + k))) (Fin (2 ^ (m + k))) ℂ) =
        Matrix.reindex e e (Im ⊗ₖ (U : Matrix (Fin (2 ^ k)) (Fin (2 ^ k)) ℂ)) := rfl
  have hV : ((idTensorWith m V : QGate (m + k)) :
      Matrix (Fin (2 ^ (m + k))) (Fin (2 ^ (m + k))) ℂ) =
        Matrix.reindex e e (Im ⊗ₖ (V : Matrix (Fin (2 ^ k)) (Fin (2 ^ k)) ℂ)) := rfl
  rw [hleft, hU, hV,
    ← Matrix.reindexAlgEquiv_apply (R := ℂ) (A := ℂ),
    ← Matrix.reindexAlgEquiv_apply (R := ℂ) (A := ℂ),
    ← Matrix.reindexAlgEquiv_apply (R := ℂ) (A := ℂ), hkr,
    Matrix.reindexAlgEquiv_mul (R := ℂ) (A := ℂ)]

/-- Embedding on the last k qubits preserves the identity gate. -/
@[simp]
lemma idTensorWith_one {k : ℕ} (m : ℕ) : idTensorWith m (1 : QGate k) = 1 := by
  apply Subtype.ext
  let e := tensorIndexEquiv m k
  let Im : Matrix (Fin (2 ^ m)) (Fin (2 ^ m)) ℂ := ((1 : QGate m) : Matrix _ _ ℂ)
  show ((idTensorWith m (1 : QGate k) : QGate (m + k)) :
      Matrix (Fin (2 ^ (m + k))) (Fin (2 ^ (m + k))) ℂ) =
    (1 : Matrix (Fin (2 ^ (m + k))) (Fin (2 ^ (m + k))) ℂ)
  have hleft : ((idTensorWith m (1 : QGate k) : QGate (m + k)) :
      Matrix (Fin (2 ^ (m + k))) (Fin (2 ^ (m + k))) ℂ) =
        Matrix.reindex e e (Im ⊗ₖ ((1 : QGate k) : Matrix (Fin (2 ^ k)) (Fin (2 ^ k)) ℂ)) := rfl
  rw [hleft, ← Matrix.reindexAlgEquiv_apply (R := ℂ) (A := ℂ)]
  simp [Im]

/-! ## hadamardAt placement identities -/

/-- `permuteQubits` of the identity permutation is the identity gate. -/
private lemma permuteQubits_refl {n : ℕ} :
    permuteQubits (Equiv.refl (Fin n)) = (1 : QGate n) := by
  apply Subtype.ext
  show (qubitPerm (Equiv.refl (Fin n))).permMatrix ℂ = 1
  simp [qubitPerm, Equiv.piCongrLeft_refl]

/-- Placing a Hadamard on the last qubit of an (n+1)-qubit register is the same as
    `I_n ⊗ H` (Hadamard acts on the last qubit, identity on the first n). -/
lemma hadamardAt_last_eq (n : ℕ) :
    hadamardAt (Fin.last n) = idTensorWith n hadamard := by
  -- `onQubit` pattern-matches on n+1; `show` does the kernel reduction to the succ branch.
  show permuteGate (Equiv.swap (Fin.last n) (Fin.last n)) (idTensorWith n hadamard) = _
  rw [Equiv.swap_self]
  have hinv : (Equiv.refl (Fin (n + 1)))⁻¹ = Equiv.refl (Fin (n + 1)) := rfl
  simp only [permuteGate, hinv, permuteQubits_refl, one_mul, mul_one]

/-- Placing a Hadamard on qubit `castSucc i` of an (n+1)-qubit register is the same as
    `(hadamardAt i) ⊗ I₁` (Hadamard acts on qubit i of the first n qubits, identity on the extra qubit).
    This is the key identity for shifting a gate away from the front of the circuit. -/
lemma hadamardAt_castSucc_eq (n : ℕ) (i : Fin n) :
    (hadamardAt (Fin.castSucc i) : QGate (n + 1)) = tensorWithId 1 (hadamardAt i) := by
  sorry

end AutoQuantum
