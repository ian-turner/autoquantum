import AutoQuantum.Core.Circuit
import AutoQuantum.Core.Gate
import AutoQuantum.Core.Tensor
import Mathlib.Algebra.BigOperators.Fin
import Mathlib.Tactic

/-!
# Bell State Preparation Solution
-/

open AutoQuantum Complex Matrix
open scoped InnerProductSpace

noncomputable def bellVector : QHilbert 2 :=
  superpose (1 / Real.sqrt 2 : ℂ) (1 / Real.sqrt 2 : ℂ)
    (basisState 2 0).vec (basisState 2 3).vec

noncomputable def bellState : QState 2 :=
  QState.mk bellVector (by
    apply superpose_norm_eq_one
    · exact (basisState 2 0).norm_eq_one
    · exact (basisState 2 3).norm_eq_one
    · change ⟪EuclideanSpace.single (0 : Fin 4) (1 : ℂ),
          EuclideanSpace.single (3 : Fin 4) (1 : ℂ)⟫_ℂ = 0
      rw [EuclideanSpace.inner_single_left]
      simp
    · norm_num [Complex.normSq, Complex.ext_iff, sq])

/-- Prepare the Bell state by applying H to the first qubit, then CNOT. -/
noncomputable def bellCircuit : Circuit 2 :=
  [tensorWithId 1 hadamard, cnot]

theorem bell_correct : runCircuit bellCircuit (basisState 2 0) = bellState := by
  let h : ℂ := (1 : ℝ) / Real.sqrt 2
  have hidx0 : (tensorIndexEquiv 1 1).symm (0 : Fin 4) =
      ((0 : Fin 2), (0 : Fin 2)) := by decide
  have hidx1 : (tensorIndexEquiv 1 1).symm (1 : Fin 4) =
      ((0 : Fin 2), (1 : Fin 2)) := by decide
  have hidx2 : (tensorIndexEquiv 1 1).symm (2 : Fin 4) =
      ((1 : Fin 2), (0 : Fin 2)) := by decide
  have hidx3 : (tensorIndexEquiv 1 1).symm (3 : Fin 4) =
      ((1 : Fin 2), (1 : Fin 2)) := by decide
  have hpidx0 : (finProdFinEquiv : Fin 2 × Fin 2 ≃ Fin 4).symm (0 : Fin 4) =
      ((0 : Fin 2), (0 : Fin 2)) := by decide
  have hpidx1 : (finProdFinEquiv : Fin 2 × Fin 2 ≃ Fin 4).symm (1 : Fin 4) =
      ((0 : Fin 2), (1 : Fin 2)) := by decide
  have hpidx2 : (finProdFinEquiv : Fin 2 × Fin 2 ≃ Fin 4).symm (2 : Fin 4) =
      ((1 : Fin 2), (0 : Fin 2)) := by decide
  have hpidx3 : (finProdFinEquiv : Fin 2 × Fin 2 ≃ Fin 4).symm (3 : Fin 4) =
      ((1 : Fin 2), (1 : Fin 2)) := by decide
  have hH :
      ((tensorWithId 1 hadamard : QGate 2) : Matrix (Fin 4) (Fin 4) ℂ) =
        !![h, 0, h, 0;
           0, h, 0, h;
           h, 0, -h, 0;
           0, h, 0, -h] := by
    ext i j
    fin_cases i <;> fin_cases j <;>
      simp [h, tensorWithId, tensorIndexEquiv, hadamard, hadamardMatrix,
        reindexUnitary, kroneckerUnitary, hpidx0, hpidx1, hpidx2, hpidx3]
  have hC :
      ((cnot : QGate 2) : Matrix (Fin 4) (Fin 4) ℂ) =
        !![1, 0, 0, 0;
           0, 1, 0, 0;
           0, 0, 0, 1;
           0, 0, 1, 0] := by
    ext i j
    fin_cases i <;> fin_cases j <;>
      simp [cnot, cnotMatrix]
  have hmat :
      ((circuitMatrix bellCircuit : QGate 2) : Matrix (Fin 4) (Fin 4) ℂ) =
        !![h, 0, h, 0;
           0, h, 0, h;
           0, h, 0, -h;
           h, 0, -h, 0] := by
    ext i j
    fin_cases i <;> fin_cases j <;>
      simp [bellCircuit, circuitMatrix, hH, hC, Matrix.mul_apply, Fin.sum_univ_four]
  apply Subtype.ext
  ext i
  fin_cases i <;>
    simp [runCircuit, applyGate, circuitMatrix, bellCircuit, bellState, bellVector,
      superpose, basisState, QState.mk, QState.vec, hH, hC,
      Matrix.toEuclideanLin_apply, h]
