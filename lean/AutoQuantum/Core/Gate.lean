import AutoQuantum.Core.Hilbert
import AutoQuantum.Core.Tensor
import Mathlib.Algebra.BigOperators.Fin
import Mathlib.Data.Fin.Rev
import Mathlib.Data.Fin.SuccPred
import Mathlib.Data.Matrix.Block
import Mathlib.Analysis.InnerProductSpace.Adjoint
import Mathlib.LinearAlgebra.UnitaryGroup
import Mathlib.LinearAlgebra.Matrix.Hermitian
import Mathlib.LinearAlgebra.Matrix.Kronecker
import Mathlib.LinearAlgebra.Matrix.Permutation
import Mathlib.LinearAlgebra.Matrix.Reindex
import Mathlib.Analysis.SpecialFunctions.Complex.Circle
import Mathlib.Analysis.SpecialFunctions.Exp

/-!
# Quantum Gates [Core]

Defines quantum gates as unitary matrices and the standard single- and
two-qubit gates used throughout AutoQuantum.

A gate on k qubits is a unitary matrix in `Matrix.unitaryGroup (Fin (2^k)) ℂ`.

This file is part of the **Core** module and is intended for human review.
It contains gate type definitions, gate matrix entries, unitarity witnesses
(the proofs required to package a matrix as a `QGate`), and gate embedding
constructions. Derived properties (e.g. H² = I, applyGate composition laws) live in
`AutoQuantum.Lemmas.Gate`.
-/

namespace AutoQuantum

open Complex Matrix
open scoped InnerProductSpace Kronecker

/-! ## Unitarity tactic -/

/-- Prove a matrix is unitary by exhaustive entry-level case analysis.
    Works for any finite matrix whose entries are in {0, 1, -1, i, -i}. -/
macro "fin_unitary" M:ident : tactic =>
  `(tactic| (
    rw [Matrix.mem_unitaryGroup_iff]
    ext i j
    fin_cases i <;> fin_cases j <;>
      (unfold $M; simp [Matrix.mul_apply, Fin.sum_univ_two, Fin.sum_univ_four])))

/-! ## Gate type -/

/-- A k-qubit quantum gate: a unitary matrix acting on 2^k-dimensional space. -/
abbrev QGate (k : ℕ) := Matrix.unitaryGroup (Fin (2 ^ k)) ℂ

/-- Apply a gate to a quantum state, preserving normalization.

    Implementation note: `QHilbert k = EuclideanSpace ℂ (Fin (2^k))` is a `PiLp`
    wrapper type, so gate application is routed through `Matrix.toEuclideanLin`. -/
noncomputable def applyGate {k : ℕ} (U : QGate k) (ψ : QState k) : QState k := by
  let Ulin : QHilbert k →ₗ[ℂ] QHilbert k :=
    Matrix.toEuclideanLin (U : Matrix (Fin (2 ^ k)) (Fin (2 ^ k)) ℂ)
  let Uiso : QHilbert k →ₗᵢ[ℂ] QHilbert k :=
    Ulin.isometryOfInner <| by
      have hUadj : Ulin.adjoint ∘ₗ Ulin = LinearMap.id := by
        have hU :
            ((U : Matrix (Fin (2 ^ k)) (Fin (2 ^ k)) ℂ)).conjTranspose *
              (U : Matrix (Fin (2 ^ k)) (Fin (2 ^ k)) ℂ) = 1 := by
          simpa [Matrix.star_eq_conjTranspose] using Matrix.UnitaryGroup.star_mul_self U
        calc
          Ulin.adjoint ∘ₗ Ulin
              = Matrix.toEuclideanLin
                  (((U : Matrix (Fin (2 ^ k)) (Fin (2 ^ k)) ℂ)).conjTranspose *
                    (U : Matrix (Fin (2 ^ k)) (Fin (2 ^ k)) ℂ)) := by
                  simp [Ulin, Matrix.toEuclideanLin_conjTranspose_eq_adjoint]
          _ = LinearMap.id := by simp [hU]
      intro x y
      calc
        ⟪Ulin x, Ulin y⟫_ℂ = ⟪x, Ulin.adjoint (Ulin y)⟫_ℂ := by
          rw [LinearMap.adjoint_inner_right]
        _ = ⟪x, y⟫_ℂ := by
          have hy : Ulin.adjoint (Ulin y) = y := by
            simp at hUadj
            simpa using
              congrArg (fun f : QHilbert k →ₗ[ℂ] QHilbert k => f y) hUadj
          rw [hy]
  exact QState.mk (Ulin ψ.vec) <| by
    rw [← ψ.norm_eq_one]
    exact Uiso.norm_map ψ.vec

/-! ## Single-qubit gates -/

section SingleQubit

/-- The Pauli X (NOT) gate matrix: [[0, 1], [1, 0]]. -/
noncomputable def pauliXMatrix : Matrix (Fin 2) (Fin 2) ℂ := !![0, 1; 1, 0]

lemma pauliXMatrix_isUnitary : pauliXMatrix ∈ Matrix.unitaryGroup (Fin 2) ℂ := by
  fin_unitary pauliXMatrix

/-- The Pauli X gate. -/
noncomputable def pauliX : QGate 1 := ⟨pauliXMatrix, pauliXMatrix_isUnitary⟩

/-- The Pauli Y gate matrix: [[0, −i], [i, 0]]. -/
noncomputable def pauliYMatrix : Matrix (Fin 2) (Fin 2) ℂ :=
  !![0, -Complex.I; Complex.I, 0]

lemma pauliYMatrix_isUnitary : pauliYMatrix ∈ Matrix.unitaryGroup (Fin 2) ℂ := by
  fin_unitary pauliYMatrix

/-- The Pauli Y gate. -/
noncomputable def pauliY : QGate 1 := ⟨pauliYMatrix, pauliYMatrix_isUnitary⟩

/-- The Pauli Z gate matrix: [[1, 0], [0, −1]]. -/
noncomputable def pauliZMatrix : Matrix (Fin 2) (Fin 2) ℂ := !![1, 0; 0, -1]

lemma pauliZMatrix_isUnitary : pauliZMatrix ∈ Matrix.unitaryGroup (Fin 2) ℂ := by
  fin_unitary pauliZMatrix

/-- The Pauli Z gate. -/
noncomputable def pauliZ : QGate 1 := ⟨pauliZMatrix, pauliZMatrix_isUnitary⟩

/-- The Hadamard gate matrix: (1/√2) [[1, 1], [1, −1]]. -/
noncomputable def hadamardMatrix : Matrix (Fin 2) (Fin 2) ℂ :=
  let h : ℂ := (1 : ℝ) / Real.sqrt 2
  !![h, h; h, -h]

lemma sqrt2_sq_cast : (Real.sqrt 2 : ℂ) ^ 2 = 2 :=
  by exact_mod_cast Real.sq_sqrt (show (0 : ℝ) ≤ 2 by norm_num)

lemma hadamardMatrix_isUnitary : hadamardMatrix ∈ Matrix.unitaryGroup (Fin 2) ℂ := by
  rw [Matrix.mem_unitaryGroup_iff]
  have hne : Real.sqrt 2 ≠ 0 := Real.sqrt_ne_zero'.mpr (by norm_num)
  ext i j
  fin_cases i <;> fin_cases j <;>
    simp [hadamardMatrix, Matrix.mul_apply, Fin.sum_univ_two]
  all_goals
    have hneC : (Real.sqrt 2 : ℂ) ≠ 0 := by exact_mod_cast hne
    field_simp [hneC]; ring_nf; simpa using sqrt2_sq_cast.symm

/-- The Hadamard gate. -/
noncomputable def hadamard : QGate 1 := ⟨hadamardMatrix, hadamardMatrix_isUnitary⟩

/-- The phase rotation R_k gate matrix: [[1, 0], [0, exp(2πi/2^k)]].
    R_1 = Z, R_2 = S, R_3 = T. -/
noncomputable def phaseRotationMatrix (k : ℕ) : Matrix (Fin 2) (Fin 2) ℂ :=
  !![1, 0; 0, Complex.exp (2 * Real.pi * Complex.I / (2 ^ k : ℂ))]

lemma phaseRotationMatrix_isUnitary (k : ℕ) :
    phaseRotationMatrix k ∈ Matrix.unitaryGroup (Fin 2) ℂ := by
  rw [Matrix.mem_unitaryGroup_iff]
  ext i j
  fin_cases i <;> fin_cases j <;>
    simp [phaseRotationMatrix, Matrix.mul_apply]
  · rw [mul_comm, ← Complex.exp_conj, ← Complex.exp_add]
    have hθ : (starRingEnd ℂ) (2 * (Real.pi : ℂ) * Complex.I / (2 : ℂ) ^ k) +
        2 * (Real.pi : ℂ) * Complex.I / (2 : ℂ) ^ k = 0 := by
      simp only [map_mul, map_div₀, map_pow, map_ofNat,
        Complex.conj_I, Complex.conj_ofReal]
      ring
    simpa using congrArg Complex.exp hθ

/-- The phase rotation gate R_k. -/
noncomputable def phaseRotation (k : ℕ) : QGate 1 :=
  ⟨phaseRotationMatrix k, phaseRotationMatrix_isUnitary k⟩

/-- The S gate = R_2: [[1, 0], [0, i]]. -/
noncomputable def sGate : QGate 1 := phaseRotation 2

/-- The T gate = R_3: [[1, 0], [0, exp(iπ/4)]]. -/
noncomputable def tGate : QGate 1 := phaseRotation 3

end SingleQubit

/-! ## Two-qubit gates -/

section TwoQubit

/-- The CNOT (controlled-X) gate matrix on 2 qubits.
    Basis order: |00⟩ = 0, |01⟩ = 1, |10⟩ = 2, |11⟩ = 3. -/
noncomputable def cnotMatrix : Matrix (Fin 4) (Fin 4) ℂ :=
  !![1, 0, 0, 0;
     0, 1, 0, 0;
     0, 0, 0, 1;
     0, 0, 1, 0]

lemma cnotMatrix_isUnitary : cnotMatrix ∈ Matrix.unitaryGroup (Fin 4) ℂ := by
  fin_unitary cnotMatrix

/-- The CNOT gate. -/
noncomputable def cnot : QGate 2 := ⟨cnotMatrix, cnotMatrix_isUnitary⟩

/-- The SWAP gate matrix on 2 qubits. -/
noncomputable def swapMatrix : Matrix (Fin 4) (Fin 4) ℂ :=
  !![1, 0, 0, 0;
     0, 0, 1, 0;
     0, 1, 0, 0;
     0, 0, 0, 1]

lemma swapMatrix_isUnitary : swapMatrix ∈ Matrix.unitaryGroup (Fin 4) ℂ := by
  fin_unitary swapMatrix

/-- The SWAP gate. -/
noncomputable def swap : QGate 2 := ⟨swapMatrix, swapMatrix_isUnitary⟩

end TwoQubit

/-! ## Gate embeddings -/

/-- Lift a permutation of qubit positions to a permutation of computational-basis indices.

    The basis index `Fin (2^n)` is identified with bitstrings `Fin n → Fin 2`; the qubit
    permutation acts by reindexing that bitstring. -/
noncomputable def qubitPerm {n : ℕ} (σ : Equiv.Perm (Fin n)) : Equiv.Perm (Fin (2 ^ n)) :=
  ((finFunctionFinEquiv (m := 2) (n := n)).symm.trans
      (Equiv.piCongrLeft (fun _ : Fin n => Fin 2) σ)).trans
    (finFunctionFinEquiv (m := 2) (n := n))

/-- The unitary gate that permutes qubit positions according to `σ`. -/
noncomputable def permuteQubits {n : ℕ} (σ : Equiv.Perm (Fin n)) : QGate n := by
  let τ : Equiv.Perm (Fin (2 ^ n)) := qubitPerm σ
  refine ⟨τ.permMatrix ℂ, ?_⟩
  rw [Matrix.mem_unitaryGroup_iff]
  calc
    τ.permMatrix ℂ * star (τ.permMatrix ℂ)
        = τ.permMatrix ℂ * (τ⁻¹).permMatrix ℂ := by
            simp [Matrix.star_eq_conjTranspose]
    _ = ((τ⁻¹) * τ).permMatrix ℂ := by
          rw [← Matrix.permMatrix_mul (R := ℂ) (σ := τ⁻¹) (τ := τ)]
    _ = 1 := by simp

/-- Conjugate a gate by a qubit permutation. This is the basic transport operation used to move
    gates away from the ends of the register. -/
noncomputable def permuteGate {n : ℕ} (σ : Equiv.Perm (Fin n)) (U : QGate n) : QGate n :=
  permuteQubits σ⁻¹ * U * permuteQubits σ

/-- Reindexing a unitary matrix along an equivalence preserves unitarity. -/
lemma reindex_mem_unitaryGroup {n m : Type*} [DecidableEq n] [Fintype n]
    [DecidableEq m] [Fintype m] (e : n ≃ m) {A : Matrix n n ℂ}
    (hA : A ∈ Matrix.unitaryGroup n ℂ) :
    Matrix.reindex e e A ∈ Matrix.unitaryGroup m ℂ := by
  rw [Matrix.mem_unitaryGroup_iff]
  have hA' : A * star A = 1 := Matrix.mem_unitaryGroup_iff.mp hA
  simpa [Matrix.star_eq_conjTranspose, Matrix.conjTranspose_reindex] using
    congrArg (Matrix.reindex e e) hA'

/-- Embed a k-qubit gate on the first k qubits of a (k+m)-qubit system (U ⊗ I_{2^m}). -/
noncomputable def tensorWithId {k : ℕ} (m : ℕ) (U : QGate k) : QGate (k + m) := by
  let e := tensorIndexEquiv k m
  let Im : Matrix (Fin (2 ^ m)) (Fin (2 ^ m)) ℂ :=
    ((1 : QGate m) : Matrix (Fin (2 ^ m)) (Fin (2 ^ m)) ℂ)
  refine ⟨Matrix.reindex e e ((U : Matrix (Fin (2 ^ k)) (Fin (2 ^ k)) ℂ) ⊗ₖ Im), ?_⟩
  have hIm : Im ∈ Matrix.unitaryGroup (Fin (2 ^ m)) ℂ := SetLike.coe_mem (1 : QGate m)
  exact reindex_mem_unitaryGroup e <|
    Matrix.kronecker_mem_unitary (SetLike.coe_mem U) hIm

/-- Embed a k-qubit gate on the last k qubits of an (m+k)-qubit system (I_{2^m} ⊗ U). -/
noncomputable def idTensorWith {k : ℕ} (m : ℕ) (U : QGate k) : QGate (m + k) := by
  let e := tensorIndexEquiv m k
  let Im : Matrix (Fin (2 ^ m)) (Fin (2 ^ m)) ℂ :=
    ((1 : QGate m) : Matrix (Fin (2 ^ m)) (Fin (2 ^ m)) ℂ)
  refine ⟨Matrix.reindex e e (Im ⊗ₖ (U : Matrix (Fin (2 ^ k)) (Fin (2 ^ k)) ℂ)), ?_⟩
  have hIm : Im ∈ Matrix.unitaryGroup (Fin (2 ^ m)) ℂ := SetLike.coe_mem (1 : QGate m)
  exact reindex_mem_unitaryGroup e <|
    Matrix.kronecker_mem_unitary hIm (SetLike.coe_mem U)

/-- Build a controlled version of a k-qubit gate as `diag(I, U)`.

    The output acts on `k + 1` qubits: the new leading control qubit leaves the target register
    unchanged on `|0⟩` and applies `U` on `|1⟩`. -/
noncomputable def controlled {k : ℕ} (U : QGate k) : QGate (k + 1) := by
  let e : Fin (2 ^ k) ⊕ Fin (2 ^ k) ≃ Fin (2 ^ (k + 1)) :=
    finSumFinEquiv.trans <| finCongr <| by
      calc
        2 ^ k + 2 ^ k = 2 * 2 ^ k := by rw [two_mul]
        _ = 2 ^ k * 2 := by rw [Nat.mul_comm]
        _ = 2 ^ (k + 1) := by simpa using (pow_succ 2 k).symm
  let CU : Matrix (Fin (2 ^ k) ⊕ Fin (2 ^ k)) (Fin (2 ^ k) ⊕ Fin (2 ^ k)) ℂ :=
    Matrix.fromBlocks (1 : Matrix (Fin (2 ^ k)) (Fin (2 ^ k)) ℂ) 0 0
      (U : Matrix (Fin (2 ^ k)) (Fin (2 ^ k)) ℂ)
  refine ⟨Matrix.reindex e e CU, ?_⟩
  have hCU : CU ∈ Matrix.unitaryGroup (Fin (2 ^ k) ⊕ Fin (2 ^ k)) ℂ := by
    rw [Matrix.mem_unitaryGroup_iff]
    have hU' :
        (U : Matrix (Fin (2 ^ k)) (Fin (2 ^ k)) ℂ) *
            star (U : Matrix (Fin (2 ^ k)) (Fin (2 ^ k)) ℂ) = 1 :=
      Matrix.mem_unitaryGroup_iff.mp (SetLike.coe_mem U)
    have hU'' :
        (U : Matrix (Fin (2 ^ k)) (Fin (2 ^ k)) ℂ) *
            (U : Matrix (Fin (2 ^ k)) (Fin (2 ^ k)) ℂ)ᴴ = 1 := by
      simpa [Matrix.star_eq_conjTranspose] using hU'
    change Matrix.fromBlocks (1 : Matrix (Fin (2 ^ k)) (Fin (2 ^ k)) ℂ) 0 0
          (U : Matrix (Fin (2 ^ k)) (Fin (2 ^ k)) ℂ) *
        star
          (Matrix.fromBlocks (1 : Matrix (Fin (2 ^ k)) (Fin (2 ^ k)) ℂ) 0 0
            (U : Matrix (Fin (2 ^ k)) (Fin (2 ^ k)) ℂ)) = 1
    rw [Matrix.star_eq_conjTranspose, Matrix.fromBlocks_conjTranspose,
      Matrix.fromBlocks_multiply]
    simp [hU'', Matrix.fromBlocks_one]
  exact reindex_mem_unitaryGroup e hCU

/-- Place a single-qubit gate on an arbitrary qubit by swapping that qubit to the end,
    applying `I ⊗ U`, and swapping back. -/
noncomputable def onQubit {n : ℕ} (q : Fin n) (U : QGate 1) : QGate n := by
  cases n with
  | zero => exact q.elim0
  | succ m =>
      exact permuteGate (Equiv.swap (Fin.last m) q) (idTensorWith m U)

/-- The Hadamard gate placed on qubit `q`. -/
noncomputable def hadamardAt {n : ℕ} (q : Fin n) : QGate n :=
  onQubit q hadamard

/-- The phase-rotation gate `R_k` placed on qubit `q`. -/
noncomputable def phaseRotationAt {n : ℕ} (q : Fin n) (k : ℕ) : QGate n :=
  onQubit q (phaseRotation k)

/-- Place a 2-qubit gate on an arbitrary ordered pair of qubits by moving that pair to the front,
    applying `U ⊗ I`, and moving the pair back. The order matters: `q₁` is the first input qubit
    of `U`, and `q₂` is the second. -/
noncomputable def onQubits {n : ℕ} (q₁ q₂ : Fin n) (h : q₁ ≠ q₂) (U : QGate 2) : QGate n := by
  cases n with
  | zero => exact q₁.elim0
  | succ n =>
      cases n with
      | zero =>
          have h' : q₁ = q₂ := by
            fin_cases q₁
            fin_cases q₂
            rfl
          exact (False.elim (h h'))
      | succ m =>
          let last : Fin (Nat.succ (Nat.succ m)) := Fin.last (Nat.succ m)
          let secondLast : Fin (Nat.succ (Nat.succ m)) := Fin.castSucc (Fin.last m)
          let τ₁ : Equiv.Perm (Fin (Nat.succ (Nat.succ m))) := Equiv.swap last q₂
          let σ : Equiv.Perm (Fin (Nat.succ (Nat.succ m))) := Equiv.swap secondLast (τ₁ q₁) * τ₁
          let V : QGate (Nat.succ (Nat.succ m)) := idTensorWith m U
          show QGate (Nat.succ (Nat.succ m))
          exact permuteGate σ V

/-- Place a controlled single-qubit gate on an arbitrary ordered pair of qubits.
    `control` is the control qubit and `target` is the target qubit. -/
noncomputable def controlledAt {n : ℕ} (control target : Fin n) (h : control ≠ target)
    (U : QGate 1) : QGate n :=
  onQubits control target h (controlled U)

/-- Place a controlled phase-rotation `R_k` on an arbitrary control/target pair. -/
noncomputable def controlledPhaseAt {n : ℕ} (control target : Fin n)
    (h : control ≠ target) (k : ℕ) : QGate n :=
  controlledAt control target h (phaseRotation k)

/-- Swap two arbitrary qubits in an `n`-qubit register. -/
noncomputable def swapAt {n : ℕ} (i j : Fin n) : QGate n :=
  permuteQubits (Equiv.swap i j)

/-- Reverse the order of the qubits in the register. This is the final permutation used in the
    standard decomposed QFT circuit. -/
noncomputable def bitReverse {n : ℕ} : QGate n :=
  permuteQubits Fin.revPerm

end AutoQuantum
