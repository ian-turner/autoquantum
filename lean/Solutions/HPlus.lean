import AutoQuantum.Core.Circuit
import AutoQuantum.Core.Gate
import AutoQuantum.Core.Tensor
import AutoQuantum.States.HPlus
import Mathlib.Algebra.BigOperators.Fin
import Mathlib.Tactic

open AutoQuantum Complex
open scoped InnerProductSpace Kronecker

private lemma matrix_reindex_mul {α β : Type} [Fintype α] [DecidableEq α]
    [Fintype β] [DecidableEq β] (e : α ≃ β) (A B : Matrix α α ℂ) :
    Matrix.reindex e e (A * B) = Matrix.reindex e e A * Matrix.reindex e e B := by
  ext i j
  change (A * B) (e.symm i) (e.symm j) =
    ∑ x : β, A (e.symm i) (e.symm x) * B (e.symm x) (e.symm j)
  rw [Matrix.mul_apply]
  exact (Fintype.sum_equiv e.symm
    (fun x : β => A (e.symm i) (e.symm x) * B (e.symm x) (e.symm j))
    (fun x : α => A (e.symm i) x * B x (e.symm j))
    (by intro x; simp)).symm

private lemma tensorWithId_one {k} (m : ℕ) : tensorWithId m (1 : QGate k) = 1 := by
  ext i j
  simp [tensorWithId, reindexUnitary, kroneckerUnitary]

private lemma tensorWithId_mul {k} (m : ℕ) (U V : QGate k) :
    tensorWithId m (U * V) = tensorWithId m U * tensorWithId m V := by
  ext i j
  simp [tensorWithId, reindexUnitary, kroneckerUnitary, Matrix.mul_apply]
  rw [Fintype.sum_prod_type]
  simp only [Matrix.one_apply]
  by_cases h : ((tensorIndexEquiv k m).symm i).2 = ((tensorIndexEquiv k m).symm j).2
  · simp [h, Finset.mul_sum, mul_comm]
  · simp [h]

private lemma hPlusVector_apply (n : ℕ) (i : Fin (2 ^ n)) :
    (hPlusState n).vec i = (1 / Real.sqrt (2 ^ n : ℝ) : ℂ) := by
  change (((1 / Real.sqrt (2 ^ n : ℝ) : ℂ) •
      ∑ k : Fin (2 ^ n), (basisState n k).vec) : QHilbert n) i =
    (1 / Real.sqrt (2 ^ n : ℝ) : ℂ)
  simp [basisState, QState.vec, PiLp.smul_apply]

namespace Goals.HPlus.HPlus

/-- Apply Hadamard to every qubit: H on qubit 0, then 1, …, then n−1. -/
noncomputable def hPlusCircuit : ∀ n, Circuit n
  | 0     => []
  | n + 1 => tensorWithIdCircuit 1 (hPlusCircuit n) ++ [hadamardAt (Fin.last n)]

end Goals.HPlus.HPlus

open Goals.HPlus.HPlus

/-! ## Sorryed primitive lemmas (hard — require matrix-level computation) -/

-- L3: circuitMatrix commutes with tensorWithIdCircuit
-- Proof sketch: tensorWithId m is a unitary group monoid hom via mul_kronecker_mul +
-- reindexLinearEquiv_mul; then List.prod_hom closes it.
private lemma circuitMatrix_tensorWithIdCircuit {k} (m : ℕ) (c : Circuit k) :
    circuitMatrix (tensorWithIdCircuit m c) = tensorWithId m (circuitMatrix c) := by
  have hfold : ∀ (A : QGate k),
      (tensorWithIdCircuit m c).foldl (fun acc U => U * acc) (tensorWithId m A) =
        tensorWithId m (c.foldl (fun acc U => U * acc) A) := by
    intro A
    induction c generalizing A with
    | nil => simp [tensorWithIdCircuit]
    | cons g cs ih =>
        simp [tensorWithIdCircuit]
        rw [← tensorWithId_mul]
        exact ih (g * A)
  calc
    circuitMatrix (tensorWithIdCircuit m c) =
        (tensorWithIdCircuit m c).foldl (fun acc U => U * acc) (tensorWithId m (1 : QGate k)) := by
          rw [tensorWithId_one]; rfl
    _ = tensorWithId m (c.foldl (fun acc U => U * acc) 1) := hfold 1
    _ = tensorWithId m (circuitMatrix c) := rfl

-- L4: tensorWithId U acts on the first factor of a tensor product state
-- Proof sketch: use ofLp_toEuclideanLin_apply to reduce to mulVec; then
-- (reindex e e (U ⊗ₖ I)) *ᵥ tensorVec ψ φ at e(i,j) = (U *ᵥ ψ)(i) * φ(j)
-- by kronecker_apply + tensorVec_apply.
private lemma applyGate_tensorWithId {k m} (U : QGate k) (ψ : QState k) (φ : QState m) :
    applyGate (tensorWithId m U) (tensorState ψ φ) = tensorState (applyGate U ψ) φ := by
  apply Subtype.ext
  change Matrix.toEuclideanLin
      (↑(tensorWithId m U) : Matrix (Fin (2 ^ (k + m))) (Fin (2 ^ (k + m))) ℂ)
      (tensorVec ψ.vec φ.vec) = tensorVec (Matrix.toEuclideanLin (↑U) ψ.vec) φ.vec
  ext i
  let e := tensorIndexEquiv k m
  let I : Matrix (Fin (2 ^ m)) (Fin (2 ^ m)) ℂ := 1
  let UM : Matrix (Fin (2 ^ k)) (Fin (2 ^ k)) ℂ := ↑U
  rcases h : e.symm i with ⟨a, b⟩
  have hi : i = e (a, b) := by simpa [h] using (e.apply_symm_apply i).symm
  rw [hi, tensorVec_apply]
  simp only [Matrix.toEuclideanLin_apply, PiLp.toLp_apply]
  change ((↑(tensorWithId m U) : Matrix (Fin (2 ^ (k + m))) (Fin (2 ^ (k + m))) ℂ).mulVec
      (tensorVec ψ.vec φ.vec).ofLp) (e (a, b)) =
    (((↑U : Matrix (Fin (2 ^ k)) (Fin (2 ^ k)) ℂ).mulVec ψ.vec.ofLp) a) * φ.vec b
  simp [tensorWithId, reindexUnitary, kroneckerUnitary, Matrix.mulVec, dotProduct, e]
  change (∑ x : Fin (2 ^ (k + m)),
      UM a ((tensorIndexEquiv k m).symm x).1 * I b ((tensorIndexEquiv k m).symm x).2 *
        (tensorVec ψ.vec φ.vec).ofLp x) =
    (∑ x : Fin (2 ^ k), UM a x * ψ.vec.ofLp x) * φ.vec.ofLp b
  calc
    (∑ x : Fin (2 ^ (k + m)),
        UM a ((tensorIndexEquiv k m).symm x).1 * I b ((tensorIndexEquiv k m).symm x).2 *
          (tensorVec ψ.vec φ.vec).ofLp x)
        = ∑ p : Fin (2 ^ k) × Fin (2 ^ m),
            UM a p.1 * I b p.2 * (tensorVec ψ.vec φ.vec).ofLp ((tensorIndexEquiv k m) p) := by
            exact (Fintype.sum_equiv (tensorIndexEquiv k m) _ _ (by intro p; simp)).symm
    _ = (∑ x : Fin (2 ^ k), UM a x * ψ.vec.ofLp x) * φ.vec.ofLp b := by
            rw [Fintype.sum_prod_type]
            simp [I, tensorVec_apply, Matrix.one_apply, Finset.mul_sum, mul_assoc, mul_comm]

-- L2: basisState (n+1) 0 factors as a tensor product
-- Proof sketch: EuclideanSpace.single at e(0,0) = tensorVec of singles at 0, 0.
private lemma basisState_tensor_zero (n : ℕ) :
    basisState (n + 1) 0 = tensorState (basisState n 0) (basisState 1 0) := by
  apply Subtype.ext
  change (basisState (n + 1) 0).vec = (tensorState (basisState n 0) (basisState 1 0)).vec
  ext i
  let e := tensorIndexEquiv n 1
  rcases h : e.symm i with ⟨a, b⟩
  have hi : i = e (a, b) := by
    simpa [h] using (e.apply_symm_apply i).symm
  rw [hi]
  change (EuclideanSpace.single (0 : Fin (2 ^ (n + 1))) (1 : ℂ)) (e (a, b)) =
      (tensorVec (EuclideanSpace.single (0 : Fin (2 ^ n)) (1 : ℂ))
        (EuclideanSpace.single (0 : Fin (2 ^ 1)) (1 : ℂ))) (e (a, b))
  rw [tensorVec_apply]
  simp [e, tensorIndexEquiv]
  fin_cases b <;> simp [finProdFinEquiv]

-- L6: idTensorWith U acts on the second factor of a tensor product state
-- Proof sketch: analogous to L4 with (I ⊗ U)(ψ⊗φ)(e(i,j)) = ψ(i) * (U *ᵥ φ)(j).
private lemma applyGate_idTensorWith {k m} (U : QGate m) (ψ : QState k) (φ : QState m) :
    applyGate (idTensorWith k U) (tensorState ψ φ) = tensorState ψ (applyGate U φ) := by
  apply Subtype.ext
  change Matrix.toEuclideanLin
      (↑(idTensorWith k U) : Matrix (Fin (2 ^ (k + m))) (Fin (2 ^ (k + m))) ℂ)
      (tensorVec ψ.vec φ.vec) = tensorVec ψ.vec (Matrix.toEuclideanLin (↑U) φ.vec)
  ext i
  let e := tensorIndexEquiv k m
  let I : Matrix (Fin (2 ^ k)) (Fin (2 ^ k)) ℂ := 1
  let UM : Matrix (Fin (2 ^ m)) (Fin (2 ^ m)) ℂ := ↑U
  rcases h : e.symm i with ⟨a, b⟩
  have hi : i = e (a, b) := by simpa [h] using (e.apply_symm_apply i).symm
  rw [hi, tensorVec_apply]
  simp only [Matrix.toEuclideanLin_apply, PiLp.toLp_apply]
  change ((↑(idTensorWith k U) : Matrix (Fin (2 ^ (k + m))) (Fin (2 ^ (k + m))) ℂ).mulVec
      (tensorVec ψ.vec φ.vec).ofLp) (e (a, b)) =
    ψ.vec a * (((↑U : Matrix (Fin (2 ^ m)) (Fin (2 ^ m)) ℂ).mulVec φ.vec.ofLp) b)
  simp [idTensorWith, reindexUnitary, kroneckerUnitary, Matrix.mulVec, dotProduct, e]
  change (∑ x : Fin (2 ^ (k + m)),
      I a ((tensorIndexEquiv k m).symm x).1 * UM b ((tensorIndexEquiv k m).symm x).2 *
        (tensorVec ψ.vec φ.vec).ofLp x) =
    ψ.vec.ofLp a * (∑ x : Fin (2 ^ m), UM b x * φ.vec.ofLp x)
  calc
    (∑ x : Fin (2 ^ (k + m)),
        I a ((tensorIndexEquiv k m).symm x).1 * UM b ((tensorIndexEquiv k m).symm x).2 *
          (tensorVec ψ.vec φ.vec).ofLp x)
        = ∑ p : Fin (2 ^ k) × Fin (2 ^ m),
            I a p.1 * UM b p.2 * (tensorVec ψ.vec φ.vec).ofLp ((tensorIndexEquiv k m) p) := by
            exact (Fintype.sum_equiv (tensorIndexEquiv k m) _ _ (by intro p; simp)).symm
    _ = ψ.vec.ofLp a * (∑ x : Fin (2 ^ m), UM b x * φ.vec.ofLp x) := by
            rw [Fintype.sum_prod_type]
            simp [I, tensorVec_apply, Matrix.one_apply]
            rw [Finset.mul_sum]
            simp [mul_left_comm]

-- L7: H|0⟩ = hPlusState 1
-- Proof sketch: 2×2 explicit matrix computation; hadamardMatrix * [1,0]ᵀ = [1/√2, 1/√2]ᵀ.
private lemma hadamard_basisState_zero :
    applyGate hadamard (basisState 1 0) = hPlusState 1 := by
  apply Subtype.ext
  -- (applyGate U ψ).val = Matrix.toEuclideanLin U ψ.val is rfl (definitional)
  change Matrix.toEuclideanLin (hadamardMatrix : Matrix (Fin (2^1)) (Fin (2^1)) ℂ)
         (EuclideanSpace.single (0 : Fin (2^1)) 1) = (hPlusState 1).val
  ext i
  fin_cases i <;>
    simp [hPlusState, hPlusVector, basisState, QState.mk, QState.vec,
          hadamardMatrix, Matrix.toEuclideanLin_apply, PiLp.toLp_apply,
          Fin.sum_univ_two, PiLp.smul_apply, pow_one, mul_one, mul_zero,
          add_zero, zero_add]

-- L8: tensor product of hPlusState n and hPlusState 1 equals hPlusState (n+1)
-- Proof sketch: distribute tensorVec over scalar and sum; reindex via tensorIndexEquiv;
-- use Real.sqrt_mul for 1/√(2^n) * 1/√2 = 1/√(2^(n+1)).
private lemma hPlusState_tensor (n : ℕ) :
    tensorState (hPlusState n) (hPlusState 1) = hPlusState (n + 1) := by
  apply Subtype.ext
  change tensorVec (hPlusState n).vec (hPlusState 1).vec = (hPlusState (n + 1)).vec
  ext i
  let e := tensorIndexEquiv n 1
  rcases h : e.symm i with ⟨a, b⟩
  have hi : i = e (a, b) := by
    simpa [h] using (e.apply_symm_apply i).symm
  rw [hi, tensorVec_apply, hPlusVector_apply, hPlusVector_apply, hPlusVector_apply]
  norm_num [pow_succ]
  ring

/-! ## Circuit composition lemmas -/

-- foldl with right-mult accumulator equals circuitMatrix × A
private lemma circuitMatrix_foldl {n} (c : Circuit n) (A : QGate n) :
    c.foldl (fun acc g => g * acc) A = circuitMatrix c * A := by
  induction c generalizing A with
  | nil => simp [circuitMatrix]
  | cons g cs ih =>
      rw [List.foldl_cons, ih (g * A)]
      -- Need: circuitMatrix cs * (g * A) = circuitMatrix (g :: cs) * A
      -- First show circuitMatrix (g :: cs) = circuitMatrix cs * g
      have hcm : circuitMatrix (g :: cs) = circuitMatrix cs * g := by
        show cs.foldl (fun acc h => h * acc) (g * 1) = circuitMatrix cs * g
        rw [mul_one]
        exact ih g
      rw [hcm, mul_assoc]

-- Circuit matrix of a concatenation: later gates appear on the left
private lemma circuitMatrix_append {n} (c₁ c₂ : Circuit n) :
    circuitMatrix (c₁ ++ c₂) = circuitMatrix c₂ * circuitMatrix c₁ := by
  show (c₁ ++ c₂).foldl (fun acc g => g * acc) 1 = circuitMatrix c₂ * circuitMatrix c₁
  rw [List.foldl_append, circuitMatrix_foldl]
  -- remaining: circuitMatrix c₂ * c₁.foldl ... 1 = circuitMatrix c₂ * circuitMatrix c₁
  -- c₁.foldl ... 1 is definitionally circuitMatrix c₁
  rfl

-- The underlying vector of applyGate U ψ is toEuclideanLin U ψ.vec
private lemma applyGate_val {k} (U : QGate k) (ψ : QState k) :
    (applyGate U ψ).val =
    Matrix.toEuclideanLin (U : Matrix (Fin (2 ^ k)) (Fin (2 ^ k)) ℂ) ψ.val := rfl

-- Gate application is functorial: applyGate (U * V) = applyGate U ∘ applyGate V
-- Key: toEuclideanLin (A*B) v = toLp (A *ᵥ B *ᵥ ofLp v) = toLp ((A*B) *ᵥ ofLp v)
private lemma applyGate_mul {n} (U V : QGate n) (ψ : QState n) :
    applyGate (U * V) ψ = applyGate U (applyGate V ψ) := by
  apply Subtype.ext
  simp only [applyGate_val,
             show (↑(U * V) : Matrix (Fin (2 ^ n)) (Fin (2 ^ n)) ℂ) = ↑U * ↑V from rfl,
             Matrix.toEuclideanLin_apply, WithLp.ofLp_toLp, Matrix.mulVec_mulVec]

-- runCircuit distributes over list append
private lemma runCircuit_append {n} (c₁ c₂ : Circuit n) (ψ : QState n) :
    runCircuit (c₁ ++ c₂) ψ = runCircuit c₂ (runCircuit c₁ ψ) := by
  simp only [runCircuit, circuitMatrix_append, applyGate_mul]

-- Running a single-gate circuit equals applying that gate
private lemma runCircuit_single {n} (U : QGate n) (ψ : QState n) :
    runCircuit [U] ψ = applyGate U ψ := by
  simp [runCircuit, circuitMatrix]

-- Running tensorWithIdCircuit on a tensor state reduces via the sub-circuit
private lemma runCircuit_tensorWithIdCircuit {k m} (c : Circuit k)
    (ψ : QState k) (φ : QState m) :
    runCircuit (tensorWithIdCircuit m c) (tensorState ψ φ) =
    tensorState (runCircuit c ψ) φ := by
  simp only [runCircuit, circuitMatrix_tensorWithIdCircuit]
  exact applyGate_tensorWithId _ _ _

/-! ## Permutation and gate placement lemmas -/

-- permuteQubits of the identity permutation is the identity gate
private lemma permuteQubits_refl (n : ℕ) :
    permuteQubits (n := n) (Equiv.refl _) = 1 := by
  apply Subtype.ext
  have hrevrev : (Fin.revPerm : Equiv.Perm (Fin n)) * Fin.revPerm = 1 := by
    apply Equiv.ext; intro i
    simp only [Equiv.Perm.coe_mul, Function.comp, Equiv.Perm.coe_one, id,
               Fin.revPerm_apply]
    exact Fin.rev_involutive i
  have hρ : Fin.revPerm * Equiv.refl (Fin n) * Fin.revPerm = Equiv.refl (Fin n) := by
    -- Equiv.refl _ = 1 : Equiv.Perm (Fin n) definitionally
    change Fin.revPerm * 1 * Fin.revPerm = 1
    simp [hrevrev]
  have hqubit : qubitPerm (n := n) (Equiv.refl _) = Equiv.refl _ := by
    unfold qubitPerm
    dsimp only []   -- beta-reduce the 'let ρ :=' binding
    rw [hρ, Equiv.piCongrLeft_refl, Equiv.trans_refl, Equiv.symm_trans_self]
  simp only [permuteQubits, hqubit, Matrix.permMatrix_refl]
  rfl

-- Conjugating a gate by the identity permutation is the identity
-- Key: permuteQubits (Equiv.refl _) = 1 by permuteQubits_refl, then 1*U*1⁻¹ = U
private lemma permuteGate_refl {n} (U : QGate n) :
    permuteGate (Equiv.refl _) U = U := by
  unfold permuteGate
  -- (Equiv.refl _)⁻¹ = Equiv.refl _ in Equiv.Perm
  have hrefl_inv : (Equiv.refl (Fin n))⁻¹ = Equiv.refl (Fin n) := inv_one
  rw [hrefl_inv]
  simp only [permuteQubits_refl, one_mul, mul_one]

-- L5: hadamardAt at the last qubit of (n+1) qubits equals idTensorWith n hadamard
-- Key: onQubit (Fin.last n) hadamard = permuteGate (Equiv.swap last last) (idTensorWith n hadamard)
--      = permuteGate (Equiv.refl _) (idTensorWith n hadamard) = idTensorWith n hadamard
private lemma hadamardAt_last (n : ℕ) :
    hadamardAt (Fin.last n) = (idTensorWith n hadamard : QGate (n + 1)) := by
  simp only [hadamardAt]
  -- onQubit (Fin.last n) hadamard definitionally = permuteGate (Equiv.swap _ _) _
  change permuteGate (Equiv.swap (Fin.last n) (Fin.last n)) (idTensorWith n hadamard) =
         idTensorWith n hadamard
  rw [Equiv.swap_self]
  exact permuteGate_refl _

/-! ## Main theorem -/

theorem hPlus_correct (n : ℕ) :
    runCircuit (hPlusCircuit n) (basisState n 0) = hPlusState n := by
  induction n with
  | zero =>
    -- Empty circuit is identity; both sides equal EuclideanSpace.single (0 : Fin 1) 1
    apply Subtype.ext
    -- LHS: runCircuit [] (basisState 0 0) is definitionally applyGate 1 (basisState 0 0)
    -- which has .val = Matrix.toEuclideanLin 1 (EuclideanSpace.single 0 1) = single 0 1
    change Matrix.toEuclideanLin (1 : Matrix (Fin 1) (Fin 1) ℂ)
           (EuclideanSpace.single (0 : Fin 1) 1) = (hPlusState 0).val
    simp [hPlusState, hPlusVector, basisState, QState.vec,
          pow_zero, Real.sqrt_one, Fin.sum_univ_one,
          Matrix.toEuclideanLin_apply, Matrix.one_mulVec, WithLp.toLp_ofLp]
    rfl
  | succ n ih =>
    -- Circuit = (H^⊗n on first n qubits) ++ [H on last qubit]
    -- Step 1: split circuit at the append
    rw [hPlusCircuit, runCircuit_append]
    -- Step 2: reduce the single-gate tail
    rw [runCircuit_single, hadamardAt_last]
    -- Step 3: factor the input state and run the first half
    rw [basisState_tensor_zero, runCircuit_tensorWithIdCircuit, ih]
    -- Step 4: the last gate acts on the second factor only
    rw [applyGate_idTensorWith, hadamard_basisState_zero]
    -- Step 5: tensor product of superpositions
    exact hPlusState_tensor n

attribute [irreducible] Goals.HPlus.HPlus.hPlusCircuit
