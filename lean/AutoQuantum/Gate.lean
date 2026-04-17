/-!
# Quantum Gates

This module defines quantum gates as unitary matrices and provides standard
single- and two-qubit gates with their key properties.

A gate on k qubits is a unitary matrix in `Matrix.unitaryGroup (Fin (2^k)) ℂ`.
-/

import AutoQuantum.Hilbert
import Mathlib.LinearAlgebra.UnitaryGroup
import Mathlib.LinearAlgebra.Matrix.Hermitian
import Mathlib.Data.Complex.Exponential
import Mathlib.Analysis.SpecialFunctions.Complex.Circle

namespace AutoQuantum

open Complex Matrix

/-! ## Gate type -/

/-- A k-qubit quantum gate: a unitary matrix acting on 2^k-dimensional space. -/
abbrev QGate (k : ℕ) := Matrix.unitaryGroup (Fin (2 ^ k)) ℂ

/-- Apply a gate to a quantum state, preserving normalization. -/
noncomputable def applyGate {k : ℕ} (U : QGate k) (ψ : QState k) : QState k :=
  ⟨(U : Matrix (Fin (2 ^ k)) (Fin (2 ^ k)) ℂ).mulVec ψ.vec,
   by
    sorry
    -- Proof: Unitary matrices are isometries — ‖U · v‖ = ‖v‖.
    -- Use Matrix.unitaryGroup.mem_iff and inner_product space isometry.
  ⟩

/-- The identity gate does nothing. -/
lemma applyGate_one {k : ℕ} (ψ : QState k) :
    applyGate (1 : QGate k) ψ = ψ := by
  simp [applyGate, QState.mk, QState.vec]
  ext i; simp [Matrix.one_mulVec]

/-- Composing gates corresponds to matrix multiplication. -/
lemma applyGate_mul {k : ℕ} (U V : QGate k) (ψ : QState k) :
    applyGate (U * V) ψ = applyGate U (applyGate V ψ) := by
  simp [applyGate, QState.mk, QState.vec, Matrix.mul_mulVec]

/-! ## Single-qubit gates -/

section SingleQubit

/-- Helper: construct a 2×2 complex matrix from four entries (row-major). -/
private def mat2 (a b c d : ℂ) : Matrix (Fin 2) (Fin 2) ℂ :=
  !![a, b; c, d]

/-- The Pauli X (NOT) gate: [[0,1],[1,0]]. -/
noncomputable def pauliXMatrix : Matrix (Fin 2) (Fin 2) ℂ := !![0, 1; 1, 0]

lemma pauliXMatrix_isUnitary : pauliXMatrix ∈ Matrix.unitaryGroup (Fin 2) ℂ := by
  rw [Matrix.mem_unitaryGroup_iff]
  ext i j
  fin_cases i <;> fin_cases j <;> simp [pauliXMatrix, Matrix.conjTranspose, Matrix.mul_apply]

/-- The Pauli X gate. -/
noncomputable def pauliX : QGate 1 := ⟨pauliXMatrix, pauliXMatrix_isUnitary⟩

/-- The Pauli Y gate: [[0,-i],[i,0]]. -/
noncomputable def pauliYMatrix : Matrix (Fin 2) (Fin 2) ℂ :=
  !![0, -Complex.I; Complex.I, 0]

lemma pauliYMatrix_isUnitary : pauliYMatrix ∈ Matrix.unitaryGroup (Fin 2) ℂ := by
  rw [Matrix.mem_unitaryGroup_iff]
  ext i j
  fin_cases i <;> fin_cases j <;>
    simp [pauliYMatrix, Matrix.conjTranspose, Matrix.mul_apply, Complex.I_sq]

/-- The Pauli Y gate. -/
noncomputable def pauliY : QGate 1 := ⟨pauliYMatrix, pauliYMatrix_isUnitary⟩

/-- The Pauli Z gate: [[1,0],[0,-1]]. -/
noncomputable def pauliZMatrix : Matrix (Fin 2) (Fin 2) ℂ := !![1, 0; 0, -1]

lemma pauliZMatrix_isUnitary : pauliZMatrix ∈ Matrix.unitaryGroup (Fin 2) ℂ := by
  rw [Matrix.mem_unitaryGroup_iff]
  ext i j
  fin_cases i <;> fin_cases j <;> simp [pauliZMatrix, Matrix.conjTranspose, Matrix.mul_apply]

/-- The Pauli Z gate. -/
noncomputable def pauliZ : QGate 1 := ⟨pauliZMatrix, pauliZMatrix_isUnitary⟩

/-- The Hadamard gate: (1/√2) [[1,1],[1,-1]]. -/
noncomputable def hadamardMatrix : Matrix (Fin 2) (Fin 2) ℂ :=
  let h := (1 : ℂ) / Real.sqrt 2
  !![h, h; h, -h]

lemma hadamardMatrix_isUnitary : hadamardMatrix ∈ Matrix.unitaryGroup (Fin 2) ℂ := by
  rw [Matrix.mem_unitaryGroup_iff]
  ext i j
  fin_cases i <;> fin_cases j <;>
    simp [hadamardMatrix, Matrix.conjTranspose, Matrix.mul_apply]
  all_goals {
    push_cast
    sorry
    -- Proof: Uses Real.sq_sqrt (by norm_num : (0:ℝ) ≤ 2) to get (1/√2)² = 1/2,
    -- then 1/2 + 1/2 = 1 and 1/2 - 1/2 = 0.
  }

/-- The Hadamard gate. -/
noncomputable def hadamard : QGate 1 := ⟨hadamardMatrix, hadamardMatrix_isUnitary⟩

/-- H² = I (Hadamard is self-inverse). -/
lemma hadamard_mul_self : hadamard * hadamard = (1 : QGate 1) := by
  ext i j
  fin_cases i <;> fin_cases j <;>
    simp [hadamard, hadamardMatrix, Matrix.mul_apply]
  all_goals sorry

/-- The phase rotation R_k gate: [[1, 0], [0, exp(2πi/2^k)]].
    Used in the QFT circuit. R_1 = Z, R_2 = S, R_3 = T, ... -/
noncomputable def phaseRotationMatrix (k : ℕ) : Matrix (Fin 2) (Fin 2) ℂ :=
  !![1, 0; 0, Complex.exp (2 * Real.pi * Complex.I / (2 ^ k : ℂ))]

lemma phaseRotationMatrix_isUnitary (k : ℕ) :
    phaseRotationMatrix k ∈ Matrix.unitaryGroup (Fin 2) ℂ := by
  rw [Matrix.mem_unitaryGroup_iff]
  ext i j
  fin_cases i <;> fin_cases j <;>
    simp [phaseRotationMatrix, Matrix.conjTranspose, Matrix.mul_apply,
          Complex.exp_conj, ← Complex.exp_add]
  · ring_nf; rw [Complex.add_re, Complex.mul_re]
    sorry
    -- Proof: |exp(iθ)|² = 1, so exp(-iθ) * exp(iθ) = 1.

/-- The phase rotation gate R_k. -/
noncomputable def phaseRotation (k : ℕ) : QGate 1 :=
  ⟨phaseRotationMatrix k, phaseRotationMatrix_isUnitary k⟩

/-- The S gate = R_2: [[1,0],[0,i]]. -/
noncomputable def sGate : QGate 1 := phaseRotation 2

/-- The T gate = R_3: [[1,0],[0,exp(iπ/4)]]. -/
noncomputable def tGate : QGate 1 := phaseRotation 3

end SingleQubit

/-! ## Two-qubit gates -/

section TwoQubit

/-- The CNOT (controlled-X) gate on 2 qubits.
    Acts as identity when control=|0⟩, Pauli-X when control=|1⟩. -/
noncomputable def cnotMatrix : Matrix (Fin 4) (Fin 4) ℂ :=
  -- Indexed as |00⟩=0, |01⟩=1, |10⟩=2, |11⟩=3
  !![1, 0, 0, 0;
     0, 1, 0, 0;
     0, 0, 0, 1;
     0, 0, 1, 0]

lemma cnotMatrix_isUnitary : cnotMatrix ∈ Matrix.unitaryGroup (Fin 4) ℂ := by
  rw [Matrix.mem_unitaryGroup_iff]
  ext i j
  fin_cases i <;> fin_cases j <;>
    simp [cnotMatrix, Matrix.conjTranspose, Matrix.mul_apply]

/-- The CNOT gate. -/
noncomputable def cnot : QGate 2 := ⟨cnotMatrix, cnotMatrix_isUnitary⟩

/-- The CNOT gate is self-inverse. -/
lemma cnot_mul_self : cnot * cnot = (1 : QGate 2) := by
  ext i j
  fin_cases i <;> fin_cases j <;>
    simp [cnot, cnotMatrix, Matrix.mul_apply]

/-- The SWAP gate on 2 qubits: exchanges the two qubits. -/
noncomputable def swapMatrix : Matrix (Fin 4) (Fin 4) ℂ :=
  !![1, 0, 0, 0;
     0, 0, 1, 0;
     0, 1, 0, 0;
     0, 0, 0, 1]

lemma swapMatrix_isUnitary : swapMatrix ∈ Matrix.unitaryGroup (Fin 4) ℂ := by
  rw [Matrix.mem_unitaryGroup_iff]
  ext i j
  fin_cases i <;> fin_cases j <;>
    simp [swapMatrix, Matrix.conjTranspose, Matrix.mul_apply]

/-- The SWAP gate. -/
noncomputable def swap : QGate 2 := ⟨swapMatrix, swapMatrix_isUnitary⟩

end TwoQubit

/-! ## Gate embeddings -/

/-- Embed a k-qubit gate on the first k qubits of an (k+m)-qubit system (as tensor product with identity). -/
noncomputable def tensorWithId {k : ℕ} (m : ℕ) (U : QGate k) : QGate (k + m) := by
  sorry
  -- Construction: the Kronecker product of U with the (2^m × 2^m) identity matrix,
  -- then reindex via Fin (2^k * 2^m) ≅ Fin (2^(k+m)).

/-- Embed a k-qubit gate on the last k qubits of an (m+k)-qubit system. -/
noncomputable def idTensorWith {k : ℕ} (m : ℕ) (U : QGate k) : QGate (m + k) := by
  sorry

/-- Build a controlled-U gate: apply U to target qubit iff control qubit is |1⟩. -/
noncomputable def controlled (U : Matrix (Fin 2) (Fin 2) ℂ)
    (hU : U ∈ Matrix.unitaryGroup (Fin 2) ℂ) : QGate 2 := by
  -- Matrix form: block-diagonal [[I_2, 0], [0, U]]
  sorry

end AutoQuantum
