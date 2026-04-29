import AutoQuantum.Core.Circuit
import Mathlib.Tactic

/-!
# Nielsen--Chuang Figure 4.6 solution
-/

open AutoQuantum
open Complex Matrix
open scoped Kronecker

/-- The right-hand side circuit in Nielsen--Chuang Figure 4.6. -/
noncomputable def nc_fig4_6_circuit (α : ℝ) (A B C : QGate 1) : Circuit 2 :=
  [ idTensorWith 1 C
  , cnot
  , idTensorWith 1 B
  , cnot
  , idTensorWith 1 A
  , tensorWithId 1 (controlPhase α)
  ]

/-- Nielsen--Chuang Figure 4.6: the standard two-CNOT decomposition of a controlled unitary. -/
theorem nc_fig4_6_goal (U A B C : QGate 1) (α : ℝ)
    (hU : (U : Matrix (Fin 2) (Fin 2) ℂ) =
      Complex.exp (Complex.I * (α : ℂ)) •
        ((A * pauliX * B * pauliX * C : QGate 1) : Matrix (Fin 2) (Fin 2) ℂ))
    (hABC : A * B * C = 1) :
    Circuit.Implements (nc_fig4_6_circuit α A B C) (controlled U) := by
  let block2 (M00 M01 M10 M11 : Matrix (Fin 2) (Fin 2) ℂ) :
      Matrix (Fin 4) (Fin 4) ℂ :=
    (Matrix.fromBlocks M00 M01 M10 M11).submatrix
      (⇑(finSumFinEquiv : Fin 2 ⊕ Fin 2 ≃ Fin 4).symm)
      (⇑(finSumFinEquiv : Fin 2 ⊕ Fin 2 ≃ Fin 4).symm)
  have hidx0 : (tensorIndexEquiv 1 1).symm (0 : Fin 4) =
      ((0 : Fin 2), (0 : Fin 2)) := by decide
  have hidx1 : (tensorIndexEquiv 1 1).symm (1 : Fin 4) =
      ((0 : Fin 2), (1 : Fin 2)) := by decide
  have hidx2 : (tensorIndexEquiv 1 1).symm (2 : Fin 4) =
      ((1 : Fin 2), (0 : Fin 2)) := by decide
  have hidx3 : (tensorIndexEquiv 1 1).symm (3 : Fin 4) =
      ((1 : Fin 2), (1 : Fin 2)) := by decide
  have hsum0 : (finSumFinEquiv : Fin 2 ⊕ Fin 2 ≃ Fin 4).symm (0 : Fin 4) =
      Sum.inl (0 : Fin 2) := by decide
  have hsum1 : (finSumFinEquiv : Fin 2 ⊕ Fin 2 ≃ Fin 4).symm (1 : Fin 4) =
      Sum.inl (1 : Fin 2) := by decide
  have hsum2 : (finSumFinEquiv : Fin 2 ⊕ Fin 2 ≃ Fin 4).symm (2 : Fin 4) =
      Sum.inr (0 : Fin 2) := by decide
  have hsum3 : (finSumFinEquiv : Fin 2 ⊕ Fin 2 ≃ Fin 4).symm (3 : Fin 4) =
      Sum.inr (1 : Fin 2) := by decide

  have hid (V : QGate 1) :
      ((idTensorWith 1 V : QGate 2) : Matrix (Fin 4) (Fin 4) ℂ) =
        block2 (V : Matrix (Fin 2) (Fin 2) ℂ) 0 0
          (V : Matrix (Fin 2) (Fin 2) ℂ) := by
    ext i j
    fin_cases i <;> fin_cases j <;>
      simp [idTensorWith, block2, hidx0, hidx1, hidx2, hidx3,
        hsum0, hsum1, hsum2, hsum3]
  have hcnot : ((cnot : QGate 2) : Matrix (Fin 4) (Fin 4) ℂ) =
      block2 1 0 0 (pauliX : Matrix (Fin 2) (Fin 2) ℂ) := by
    ext i j
    fin_cases i <;> fin_cases j <;>
      simp [cnot, cnotMatrix, block2, pauliX, pauliXMatrix,
        hsum0, hsum1, hsum2, hsum3]
  have hphase :
      ((tensorWithId 1 (controlPhase α) : QGate 2) : Matrix (Fin 4) (Fin 4) ℂ) =
        block2 1 0 0
          ((Complex.exp (Complex.I * (α : ℂ))) • (1 : Matrix (Fin 2) (Fin 2) ℂ)) := by
    ext i j
    fin_cases i <;> fin_cases j <;>
      simp [tensorWithId, block2, controlPhase, controlPhaseMatrix,
        hidx0, hidx1, hidx2, hidx3, hsum0, hsum1, hsum2, hsum3]
  have hctrl : ((controlled U : QGate 2) : Matrix (Fin 4) (Fin 4) ℂ) =
      block2 1 0 0 (U : Matrix (Fin 2) (Fin 2) ℂ) := by
    ext i j
    fin_cases i <;> fin_cases j <;>
      simp [controlled, block2, hsum0, hsum1, hsum2, hsum3]

  have hABCm : ((A * B * C : QGate 1) : Matrix (Fin 2) (Fin 2) ℂ) = 1 := by
    simpa using congrArg Subtype.val hABC
  have hABC00 := congrFun (congrFun hABCm (0 : Fin 2)) (0 : Fin 2)
  have hABC01 := congrFun (congrFun hABCm (0 : Fin 2)) (1 : Fin 2)
  have hABC10 := congrFun (congrFun hABCm (1 : Fin 2)) (0 : Fin 2)
  have hABC11 := congrFun (congrFun hABCm (1 : Fin 2)) (1 : Fin 2)
  simp [Matrix.mul_apply, Fin.sum_univ_two] at hABC00 hABC01 hABC10 hABC11

  unfold Circuit.Implements
  apply Subtype.ext
  ext i j
  fin_cases i <;> fin_cases j <;>
    simp [nc_fig4_6_circuit, circuitMatrix, hid, hcnot, hphase, hctrl, block2,
      hsum0, hsum1, hsum2, hsum3, hU,
      Matrix.mul_apply, Matrix.smul_apply, Fin.sum_univ_four, Fin.sum_univ_two,
      pauliX, pauliXMatrix]
    <;> ring_nf at hABC00 hABC01 hABC10 hABC11 ⊢
    <;> assumption
