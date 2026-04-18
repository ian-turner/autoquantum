import AutoQuantum.Core.Hilbert
import Mathlib.Analysis.InnerProductSpace.Adjoint
import Mathlib.LinearAlgebra.UnitaryGroup
import Mathlib.LinearAlgebra.Matrix.Hermitian
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
stubs. Derived properties (e.g. H² = I, applyGate composition laws) live in
`AutoQuantum.Lemmas.Gate`.
-/

namespace AutoQuantum

open Complex Matrix
open scoped InnerProductSpace

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
  rw [Matrix.mem_unitaryGroup_iff]
  ext i j
  fin_cases i <;> fin_cases j <;>
    simp [pauliXMatrix, Matrix.conjTranspose, Matrix.mul_apply, Matrix.one_apply]

/-- The Pauli X gate. -/
noncomputable def pauliX : QGate 1 := ⟨pauliXMatrix, pauliXMatrix_isUnitary⟩

/-- The Pauli Y gate matrix: [[0, −i], [i, 0]]. -/
noncomputable def pauliYMatrix : Matrix (Fin 2) (Fin 2) ℂ :=
  !![0, -Complex.I; Complex.I, 0]

lemma pauliYMatrix_isUnitary : pauliYMatrix ∈ Matrix.unitaryGroup (Fin 2) ℂ := by
  rw [Matrix.mem_unitaryGroup_iff]
  ext i j
  fin_cases i <;> fin_cases j <;>
    simp [pauliYMatrix, Matrix.conjTranspose, Matrix.mul_apply, Matrix.one_apply, Complex.I_sq]
  all_goals simp [Complex.ext_iff, Complex.I_re, Complex.I_im, mul_comm]

/-- The Pauli Y gate. -/
noncomputable def pauliY : QGate 1 := ⟨pauliYMatrix, pauliYMatrix_isUnitary⟩

/-- The Pauli Z gate matrix: [[1, 0], [0, −1]]. -/
noncomputable def pauliZMatrix : Matrix (Fin 2) (Fin 2) ℂ := !![1, 0; 0, -1]

lemma pauliZMatrix_isUnitary : pauliZMatrix ∈ Matrix.unitaryGroup (Fin 2) ℂ := by
  rw [Matrix.mem_unitaryGroup_iff]
  ext i j
  fin_cases i <;> fin_cases j <;>
    simp [pauliZMatrix, Matrix.conjTranspose, Matrix.mul_apply, Matrix.one_apply]

/-- The Pauli Z gate. -/
noncomputable def pauliZ : QGate 1 := ⟨pauliZMatrix, pauliZMatrix_isUnitary⟩

/-- The Hadamard gate matrix: (1/√2) [[1, 1], [1, −1]]. -/
noncomputable def hadamardMatrix : Matrix (Fin 2) (Fin 2) ℂ :=
  let h : ℂ := (1 : ℝ) / Real.sqrt 2
  !![h, h; h, -h]

lemma hadamardMatrix_isUnitary : hadamardMatrix ∈ Matrix.unitaryGroup (Fin 2) ℂ := by
  rw [Matrix.mem_unitaryGroup_iff]
  have hne : Real.sqrt 2 ≠ 0 := Real.sqrt_ne_zero'.mpr (by norm_num)
  ext i j
  fin_cases i <;> fin_cases j <;>
    simp [hadamardMatrix, Matrix.mul_apply, Fin.sum_univ_two]
  all_goals
    have hneC : (Real.sqrt 2 : ℂ) ≠ 0 := by
      exact_mod_cast hne
    field_simp [hneC]
    ring_nf
    have hsq : ((Real.sqrt 2 : ℂ) ^ 2) = 2 := by
      exact_mod_cast Real.sq_sqrt (show (0 : ℝ) ≤ 2 by norm_num)
    simpa using hsq.symm

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
  rw [Matrix.mem_unitaryGroup_iff]
  ext i j
  fin_cases i <;> fin_cases j <;>
    simp [cnotMatrix, Matrix.conjTranspose, Matrix.mul_apply, Matrix.one_apply,
          Fin.sum_univ_four]

/-- The CNOT gate. -/
noncomputable def cnot : QGate 2 := ⟨cnotMatrix, cnotMatrix_isUnitary⟩

/-- The SWAP gate matrix on 2 qubits. -/
noncomputable def swapMatrix : Matrix (Fin 4) (Fin 4) ℂ :=
  !![1, 0, 0, 0;
     0, 0, 1, 0;
     0, 1, 0, 0;
     0, 0, 0, 1]

lemma swapMatrix_isUnitary : swapMatrix ∈ Matrix.unitaryGroup (Fin 4) ℂ := by
  rw [Matrix.mem_unitaryGroup_iff]
  ext i j
  fin_cases i <;> fin_cases j <;>
    simp [swapMatrix, Matrix.conjTranspose, Matrix.mul_apply, Matrix.one_apply,
          Fin.sum_univ_four]

/-- The SWAP gate. -/
noncomputable def swap : QGate 2 := ⟨swapMatrix, swapMatrix_isUnitary⟩

end TwoQubit

/-! ## Gate embeddings (deferred) -/

/-- Embed a k-qubit gate on the first k qubits of a (k+m)-qubit system (U ⊗ I_{2^m}). -/
noncomputable def tensorWithId {k : ℕ} (m : ℕ) (U : QGate k) : QGate (k + m) := by
  exact sorry

/-- Embed a k-qubit gate on the last k qubits of an (m+k)-qubit system (I_{2^m} ⊗ U). -/
noncomputable def idTensorWith {k : ℕ} (m : ℕ) (U : QGate k) : QGate (m + k) := by
  exact sorry

/-- Build a controlled-U gate from a single-qubit unitary: [[I₂, 0], [0, U]]. -/
noncomputable def controlled (U : Matrix (Fin 2) (Fin 2) ℂ)
    (hU : U ∈ Matrix.unitaryGroup (Fin 2) ℂ) : QGate 2 := by
  exact sorry

end AutoQuantum
