import AutoQuantum.Core.Circuit
import Mathlib.Tactic

/-!
# Nielsen--Chuang Figure 4.8 solution
-/

open AutoQuantum
open Complex Matrix

set_option linter.unusedSimpArgs false
set_option linter.unnecessarySimpa false
set_option maxHeartbeats 2000000

private noncomputable def cv02Matrix (V : QGate 1) : Matrix (Fin 8) (Fin 8) ℂ :=
  !![1, 0, 0, 0, 0, 0, 0, 0;
     0, 1, 0, 0, 0, 0, 0, 0;
     0, 0, 1, 0, 0, 0, 0, 0;
     0, 0, 0, 1, 0, 0, 0, 0;
     0, 0, 0, 0, (V : Matrix (Fin 2) (Fin 2) ℂ) 0 0,
       (V : Matrix (Fin 2) (Fin 2) ℂ) 0 1, 0, 0;
     0, 0, 0, 0, (V : Matrix (Fin 2) (Fin 2) ℂ) 1 0,
       (V : Matrix (Fin 2) (Fin 2) ℂ) 1 1, 0, 0;
     0, 0, 0, 0, 0, 0, (V : Matrix (Fin 2) (Fin 2) ℂ) 0 0,
       (V : Matrix (Fin 2) (Fin 2) ℂ) 0 1;
     0, 0, 0, 0, 0, 0, (V : Matrix (Fin 2) (Fin 2) ℂ) 1 0,
       (V : Matrix (Fin 2) (Fin 2) ℂ) 1 1]

private noncomputable def cv12Matrix (V : QGate 1) : Matrix (Fin 8) (Fin 8) ℂ :=
  !![1, 0, 0, 0, 0, 0, 0, 0;
     0, 1, 0, 0, 0, 0, 0, 0;
     0, 0, (V : Matrix (Fin 2) (Fin 2) ℂ) 0 0,
       (V : Matrix (Fin 2) (Fin 2) ℂ) 0 1, 0, 0, 0, 0;
     0, 0, (V : Matrix (Fin 2) (Fin 2) ℂ) 1 0,
       (V : Matrix (Fin 2) (Fin 2) ℂ) 1 1, 0, 0, 0, 0;
     0, 0, 0, 0, 1, 0, 0, 0;
     0, 0, 0, 0, 0, 1, 0, 0;
     0, 0, 0, 0, 0, 0, (V : Matrix (Fin 2) (Fin 2) ℂ) 0 0,
       (V : Matrix (Fin 2) (Fin 2) ℂ) 0 1;
     0, 0, 0, 0, 0, 0, (V : Matrix (Fin 2) (Fin 2) ℂ) 1 0,
       (V : Matrix (Fin 2) (Fin 2) ℂ) 1 1]

private noncomputable def cx01Matrix : Matrix (Fin 8) (Fin 8) ℂ :=
  !![1, 0, 0, 0, 0, 0, 0, 0;
     0, 1, 0, 0, 0, 0, 0, 0;
     0, 0, 1, 0, 0, 0, 0, 0;
     0, 0, 0, 1, 0, 0, 0, 0;
     0, 0, 0, 0, 0, 0, 1, 0;
     0, 0, 0, 0, 0, 0, 0, 1;
     0, 0, 0, 0, 1, 0, 0, 0;
     0, 0, 0, 0, 0, 1, 0, 0]

private noncomputable def ccMatrix (U : QGate 1) : Matrix (Fin 8) (Fin 8) ℂ :=
  !![1, 0, 0, 0, 0, 0, 0, 0;
     0, 1, 0, 0, 0, 0, 0, 0;
     0, 0, 1, 0, 0, 0, 0, 0;
     0, 0, 0, 1, 0, 0, 0, 0;
     0, 0, 0, 0, 1, 0, 0, 0;
     0, 0, 0, 0, 0, 1, 0, 0;
     0, 0, 0, 0, 0, 0, (U : Matrix (Fin 2) (Fin 2) ℂ) 0 0,
       (U : Matrix (Fin 2) (Fin 2) ℂ) 0 1;
     0, 0, 0, 0, 0, 0, (U : Matrix (Fin 2) (Fin 2) ℂ) 1 0,
       (U : Matrix (Fin 2) (Fin 2) ℂ) 1 1]

private lemma controlledAt_0_2_matrix (V : QGate 1) :
    ((controlledAt 0 2 (by decide) V : QGate 3) :
      Matrix (Fin 8) (Fin 8) ℂ) = cv02Matrix V := by
  have hq0 : qubitPerm (Equiv.swap (1 : Fin 3) (0 : Fin 3)) (0 : Fin 8) = 0 := by
    decide
  have hq1 : qubitPerm (Equiv.swap (1 : Fin 3) (0 : Fin 3)) (1 : Fin 8) = 1 := by
    decide
  have hq2 : qubitPerm (Equiv.swap (1 : Fin 3) (0 : Fin 3)) (2 : Fin 8) = 4 := by
    decide
  have hq3 : qubitPerm (Equiv.swap (1 : Fin 3) (0 : Fin 3)) (3 : Fin 8) = 5 := by
    decide
  have hq4 : qubitPerm (Equiv.swap (1 : Fin 3) (0 : Fin 3)) (4 : Fin 8) = 2 := by
    decide
  have hq5 : qubitPerm (Equiv.swap (1 : Fin 3) (0 : Fin 3)) (5 : Fin 8) = 3 := by
    decide
  have hq6 : qubitPerm (Equiv.swap (1 : Fin 3) (0 : Fin 3)) (6 : Fin 8) = 6 := by
    decide
  have hq7 : qubitPerm (Equiv.swap (1 : Fin 3) (0 : Fin 3)) (7 : Fin 8) = 7 := by
    decide
  have hidx0 : (tensorIndexEquiv 1 2).symm (0 : Fin 8) =
      ((0 : Fin 2), (0 : Fin 4)) := by decide
  have hidx1 : (tensorIndexEquiv 1 2).symm (1 : Fin 8) =
      ((0 : Fin 2), (1 : Fin 4)) := by decide
  have hidx2 : (tensorIndexEquiv 1 2).symm (2 : Fin 8) =
      ((0 : Fin 2), (2 : Fin 4)) := by decide
  have hidx3 : (tensorIndexEquiv 1 2).symm (3 : Fin 8) =
      ((0 : Fin 2), (3 : Fin 4)) := by decide
  have hidx4 : (tensorIndexEquiv 1 2).symm (4 : Fin 8) =
      ((1 : Fin 2), (0 : Fin 4)) := by decide
  have hidx5 : (tensorIndexEquiv 1 2).symm (5 : Fin 8) =
      ((1 : Fin 2), (1 : Fin 4)) := by decide
  have hidx6 : (tensorIndexEquiv 1 2).symm (6 : Fin 8) =
      ((1 : Fin 2), (2 : Fin 4)) := by decide
  have hidx7 : (tensorIndexEquiv 1 2).symm (7 : Fin 8) =
      ((1 : Fin 2), (3 : Fin 4)) := by decide
  have hsum0 : (finSumFinEquiv : Fin 2 ⊕ Fin 2 ≃ Fin 4).symm (0 : Fin 4) =
      Sum.inl (0 : Fin 2) := by decide
  have hsum1 : (finSumFinEquiv : Fin 2 ⊕ Fin 2 ≃ Fin 4).symm (1 : Fin 4) =
      Sum.inl (1 : Fin 2) := by decide
  have hsum2 : (finSumFinEquiv : Fin 2 ⊕ Fin 2 ≃ Fin 4).symm (2 : Fin 4) =
      Sum.inr (0 : Fin 2) := by decide
  have hsum3 : (finSumFinEquiv : Fin 2 ⊕ Fin 2 ≃ Fin 4).symm (3 : Fin 4) =
      Sum.inr (1 : Fin 2) := by decide
  ext i j
  fin_cases i <;> fin_cases j <;>
    simp [cv02Matrix, controlledAt, onQubits, controlled, permuteGate, permuteQubits,
      idTensorWith, reindexUnitary, kroneckerUnitary, Nat.casesAuxOn_succ,
      Matrix.mul_apply, Fin.sum_univ_eight, hq0, hq1, hq2, hq3, hq4, hq5, hq6,
      hq7, hidx0, hidx1, hidx2, hidx3, hidx4, hidx5, hidx6, hidx7, hsum0, hsum1,
      hsum2, hsum3] <;>
    (repeat first
      | rw [hidx0]
      | rw [hidx1]
      | rw [hidx2]
      | rw [hidx3]
      | rw [hidx4]
      | rw [hidx5]
      | rw [hidx6]
      | rw [hidx7]
      | rw [hsum0]
      | rw [hsum1]
      | rw [hsum2]
      | rw [hsum3]) <;>
    simp

private lemma controlledAt_1_2_matrix (V : QGate 1) :
    ((controlledAt 1 2 (by decide) V : QGate 3) :
      Matrix (Fin 8) (Fin 8) ℂ) = cv12Matrix V := by
  have hq0 : qubitPerm (Equiv.refl (Fin 3)) (0 : Fin 8) = 0 := by decide
  have hq1 : qubitPerm (Equiv.refl (Fin 3)) (1 : Fin 8) = 1 := by decide
  have hq2 : qubitPerm (Equiv.refl (Fin 3)) (2 : Fin 8) = 2 := by decide
  have hq3 : qubitPerm (Equiv.refl (Fin 3)) (3 : Fin 8) = 3 := by decide
  have hq4 : qubitPerm (Equiv.refl (Fin 3)) (4 : Fin 8) = 4 := by decide
  have hq5 : qubitPerm (Equiv.refl (Fin 3)) (5 : Fin 8) = 5 := by decide
  have hq6 : qubitPerm (Equiv.refl (Fin 3)) (6 : Fin 8) = 6 := by decide
  have hq7 : qubitPerm (Equiv.refl (Fin 3)) (7 : Fin 8) = 7 := by decide
  have hidx0 : (tensorIndexEquiv 1 2).symm (0 : Fin 8) =
      ((0 : Fin 2), (0 : Fin 4)) := by decide
  have hidx1 : (tensorIndexEquiv 1 2).symm (1 : Fin 8) =
      ((0 : Fin 2), (1 : Fin 4)) := by decide
  have hidx2 : (tensorIndexEquiv 1 2).symm (2 : Fin 8) =
      ((0 : Fin 2), (2 : Fin 4)) := by decide
  have hidx3 : (tensorIndexEquiv 1 2).symm (3 : Fin 8) =
      ((0 : Fin 2), (3 : Fin 4)) := by decide
  have hidx4 : (tensorIndexEquiv 1 2).symm (4 : Fin 8) =
      ((1 : Fin 2), (0 : Fin 4)) := by decide
  have hidx5 : (tensorIndexEquiv 1 2).symm (5 : Fin 8) =
      ((1 : Fin 2), (1 : Fin 4)) := by decide
  have hidx6 : (tensorIndexEquiv 1 2).symm (6 : Fin 8) =
      ((1 : Fin 2), (2 : Fin 4)) := by decide
  have hidx7 : (tensorIndexEquiv 1 2).symm (7 : Fin 8) =
      ((1 : Fin 2), (3 : Fin 4)) := by decide
  have hsum0 : (finSumFinEquiv : Fin 2 ⊕ Fin 2 ≃ Fin 4).symm (0 : Fin 4) =
      Sum.inl (0 : Fin 2) := by decide
  have hsum1 : (finSumFinEquiv : Fin 2 ⊕ Fin 2 ≃ Fin 4).symm (1 : Fin 4) =
      Sum.inl (1 : Fin 2) := by decide
  have hsum2 : (finSumFinEquiv : Fin 2 ⊕ Fin 2 ≃ Fin 4).symm (2 : Fin 4) =
      Sum.inr (0 : Fin 2) := by decide
  have hsum3 : (finSumFinEquiv : Fin 2 ⊕ Fin 2 ≃ Fin 4).symm (3 : Fin 4) =
      Sum.inr (1 : Fin 2) := by decide
  ext i j
  fin_cases i <;> fin_cases j <;>
    simp [cv12Matrix, controlledAt, onQubits, controlled, permuteGate, permuteQubits,
      idTensorWith, reindexUnitary, kroneckerUnitary, Nat.casesAuxOn_succ,
      Matrix.mul_apply, Fin.sum_univ_eight, hq0, hq1, hq2, hq3, hq4, hq5, hq6,
      hq7, hidx0, hidx1, hidx2, hidx3, hidx4, hidx5, hidx6, hidx7, hsum0, hsum1,
      hsum2, hsum3] <;>
    (repeat first
      | rw [hidx0]
      | rw [hidx1]
      | rw [hidx2]
      | rw [hidx3]
      | rw [hidx4]
      | rw [hidx5]
      | rw [hidx6]
      | rw [hidx7]
      | rw [hsum0]
      | rw [hsum1]
      | rw [hsum2]
      | rw [hsum3]) <;>
    simp

private lemma controlledAt_0_1_pauliX_matrix :
    ((controlledAt 0 1 (by decide) pauliX : QGate 3) :
      Matrix (Fin 8) (Fin 8) ℂ) = cx01Matrix := by
  have hswap : (Equiv.swap (2 : Fin 3) (1 : Fin 3)) (0 : Fin 3) = 0 := by
    decide
  have hr0 : qubitPerm (Equiv.swap (1 : Fin 3) (0 : Fin 3) *
      Equiv.swap (2 : Fin 3) (1 : Fin 3)) (0 : Fin 8) = 0 := by decide
  have hr1 : qubitPerm (Equiv.swap (1 : Fin 3) (0 : Fin 3) *
      Equiv.swap (2 : Fin 3) (1 : Fin 3)) (1 : Fin 8) = 4 := by decide
  have hr2 : qubitPerm (Equiv.swap (1 : Fin 3) (0 : Fin 3) *
      Equiv.swap (2 : Fin 3) (1 : Fin 3)) (2 : Fin 8) = 1 := by decide
  have hr3 : qubitPerm (Equiv.swap (1 : Fin 3) (0 : Fin 3) *
      Equiv.swap (2 : Fin 3) (1 : Fin 3)) (3 : Fin 8) = 5 := by decide
  have hr4 : qubitPerm (Equiv.swap (1 : Fin 3) (0 : Fin 3) *
      Equiv.swap (2 : Fin 3) (1 : Fin 3)) (4 : Fin 8) = 2 := by decide
  have hr5 : qubitPerm (Equiv.swap (1 : Fin 3) (0 : Fin 3) *
      Equiv.swap (2 : Fin 3) (1 : Fin 3)) (5 : Fin 8) = 6 := by decide
  have hr6 : qubitPerm (Equiv.swap (1 : Fin 3) (0 : Fin 3) *
      Equiv.swap (2 : Fin 3) (1 : Fin 3)) (6 : Fin 8) = 3 := by decide
  have hr7 : qubitPerm (Equiv.swap (1 : Fin 3) (0 : Fin 3) *
      Equiv.swap (2 : Fin 3) (1 : Fin 3)) (7 : Fin 8) = 7 := by decide
  have hl0 : qubitPerm (Equiv.swap (2 : Fin 3) (1 : Fin 3) *
      Equiv.swap (1 : Fin 3) (0 : Fin 3)) (0 : Fin 8) = 0 := by decide
  have hl1 : qubitPerm (Equiv.swap (2 : Fin 3) (1 : Fin 3) *
      Equiv.swap (1 : Fin 3) (0 : Fin 3)) (1 : Fin 8) = 2 := by decide
  have hl2 : qubitPerm (Equiv.swap (2 : Fin 3) (1 : Fin 3) *
      Equiv.swap (1 : Fin 3) (0 : Fin 3)) (2 : Fin 8) = 4 := by decide
  have hl3 : qubitPerm (Equiv.swap (2 : Fin 3) (1 : Fin 3) *
      Equiv.swap (1 : Fin 3) (0 : Fin 3)) (3 : Fin 8) = 6 := by decide
  have hl4 : qubitPerm (Equiv.swap (2 : Fin 3) (1 : Fin 3) *
      Equiv.swap (1 : Fin 3) (0 : Fin 3)) (4 : Fin 8) = 1 := by decide
  have hl5 : qubitPerm (Equiv.swap (2 : Fin 3) (1 : Fin 3) *
      Equiv.swap (1 : Fin 3) (0 : Fin 3)) (5 : Fin 8) = 3 := by decide
  have hl6 : qubitPerm (Equiv.swap (2 : Fin 3) (1 : Fin 3) *
      Equiv.swap (1 : Fin 3) (0 : Fin 3)) (6 : Fin 8) = 5 := by decide
  have hl7 : qubitPerm (Equiv.swap (2 : Fin 3) (1 : Fin 3) *
      Equiv.swap (1 : Fin 3) (0 : Fin 3)) (7 : Fin 8) = 7 := by decide
  have hidx0 : (tensorIndexEquiv 1 2).symm (0 : Fin 8) =
      ((0 : Fin 2), (0 : Fin 4)) := by decide
  have hidx1 : (tensorIndexEquiv 1 2).symm (1 : Fin 8) =
      ((0 : Fin 2), (1 : Fin 4)) := by decide
  have hidx2 : (tensorIndexEquiv 1 2).symm (2 : Fin 8) =
      ((0 : Fin 2), (2 : Fin 4)) := by decide
  have hidx3 : (tensorIndexEquiv 1 2).symm (3 : Fin 8) =
      ((0 : Fin 2), (3 : Fin 4)) := by decide
  have hidx4 : (tensorIndexEquiv 1 2).symm (4 : Fin 8) =
      ((1 : Fin 2), (0 : Fin 4)) := by decide
  have hidx5 : (tensorIndexEquiv 1 2).symm (5 : Fin 8) =
      ((1 : Fin 2), (1 : Fin 4)) := by decide
  have hidx6 : (tensorIndexEquiv 1 2).symm (6 : Fin 8) =
      ((1 : Fin 2), (2 : Fin 4)) := by decide
  have hidx7 : (tensorIndexEquiv 1 2).symm (7 : Fin 8) =
      ((1 : Fin 2), (3 : Fin 4)) := by decide
  have hsum0 : (finSumFinEquiv : Fin 2 ⊕ Fin 2 ≃ Fin 4).symm (0 : Fin 4) =
      Sum.inl (0 : Fin 2) := by decide
  have hsum1 : (finSumFinEquiv : Fin 2 ⊕ Fin 2 ≃ Fin 4).symm (1 : Fin 4) =
      Sum.inl (1 : Fin 2) := by decide
  have hsum2 : (finSumFinEquiv : Fin 2 ⊕ Fin 2 ≃ Fin 4).symm (2 : Fin 4) =
      Sum.inr (0 : Fin 2) := by decide
  have hsum3 : (finSumFinEquiv : Fin 2 ⊕ Fin 2 ≃ Fin 4).symm (3 : Fin 4) =
      Sum.inr (1 : Fin 2) := by decide
  ext i j
  fin_cases i <;> fin_cases j <;>
    simp [cx01Matrix, controlledAt, onQubits, controlled, permuteGate, permuteQubits,
      idTensorWith, reindexUnitary, kroneckerUnitary, pauliX, pauliXMatrix,
      Nat.casesAuxOn_succ, Matrix.mul_apply, Fin.sum_univ_eight, hswap, hr0, hr1,
      hr2, hr3, hr4, hr5, hr6, hr7, hl0, hl1, hl2, hl3, hl4, hl5, hl6, hl7,
      hidx0, hidx1, hidx2, hidx3, hidx4, hidx5, hidx6, hidx7, hsum0, hsum1,
      hsum2, hsum3] <;>
    (repeat first
      | rw [hidx0]
      | rw [hidx1]
      | rw [hidx2]
      | rw [hidx3]
      | rw [hidx4]
      | rw [hidx5]
      | rw [hidx6]
      | rw [hidx7]
      | rw [hsum0]
      | rw [hsum1]
      | rw [hsum2]
      | rw [hsum3]) <;>
    simp

private lemma controlled_controlled_matrix (U : QGate 1) :
    ((controlled (controlled U) : QGate 3) :
      Matrix (Fin 8) (Fin 8) ℂ) = ccMatrix U := by
  have hsum0 : (finSumFinEquiv : Fin 4 ⊕ Fin 4 ≃ Fin 8).symm (0 : Fin 8) =
      Sum.inl (0 : Fin 4) := by decide
  have hsum1 : (finSumFinEquiv : Fin 4 ⊕ Fin 4 ≃ Fin 8).symm (1 : Fin 8) =
      Sum.inl (1 : Fin 4) := by decide
  have hsum2 : (finSumFinEquiv : Fin 4 ⊕ Fin 4 ≃ Fin 8).symm (2 : Fin 8) =
      Sum.inl (2 : Fin 4) := by decide
  have hsum3 : (finSumFinEquiv : Fin 4 ⊕ Fin 4 ≃ Fin 8).symm (3 : Fin 8) =
      Sum.inl (3 : Fin 4) := by decide
  have hsum4 : (finSumFinEquiv : Fin 4 ⊕ Fin 4 ≃ Fin 8).symm (4 : Fin 8) =
      Sum.inr (0 : Fin 4) := by decide
  have hsum5 : (finSumFinEquiv : Fin 4 ⊕ Fin 4 ≃ Fin 8).symm (5 : Fin 8) =
      Sum.inr (1 : Fin 4) := by decide
  have hsum6 : (finSumFinEquiv : Fin 4 ⊕ Fin 4 ≃ Fin 8).symm (6 : Fin 8) =
      Sum.inr (2 : Fin 4) := by decide
  have hsum7 : (finSumFinEquiv : Fin 4 ⊕ Fin 4 ≃ Fin 8).symm (7 : Fin 8) =
      Sum.inr (3 : Fin 4) := by decide
  have hsum0' : (finSumFinEquiv : Fin 2 ⊕ Fin 2 ≃ Fin 4).symm (0 : Fin 4) =
      Sum.inl (0 : Fin 2) := by decide
  have hsum1' : (finSumFinEquiv : Fin 2 ⊕ Fin 2 ≃ Fin 4).symm (1 : Fin 4) =
      Sum.inl (1 : Fin 2) := by decide
  have hsum2' : (finSumFinEquiv : Fin 2 ⊕ Fin 2 ≃ Fin 4).symm (2 : Fin 4) =
      Sum.inr (0 : Fin 2) := by decide
  have hsum3' : (finSumFinEquiv : Fin 2 ⊕ Fin 2 ≃ Fin 4).symm (3 : Fin 4) =
      Sum.inr (1 : Fin 2) := by decide
  ext i j
  fin_cases i <;> fin_cases j <;>
    simp [ccMatrix, controlled, hsum0, hsum1, hsum2, hsum3, hsum4, hsum5, hsum6,
      hsum7, hsum0', hsum1', hsum2', hsum3']

/-- Nielsen--Chuang Figure 4.8 circuit identity. -/
theorem nc_fig4_8_goal (U : QGate 1) (V : QGate 1) (hv : V ^ 2 = U) :
    (controlledAt 0 2 (by decide) V                : QGate 3) *
    (controlledAt 0 1 (by decide) pauliX           : QGate 3) *
    (controlledAt 1 2 (by decide) (QGate.dagger V) : QGate 3) *
    (controlledAt 0 1 (by decide) pauliX           : QGate 3) *
    (controlledAt 1 2 (by decide) V                : QGate 3) =
    controlled (controlled U) := by
  have hV_mul_dagger :
      (V : Matrix (Fin 2) (Fin 2) ℂ) *
        ((QGate.dagger V : QGate 1) : Matrix (Fin 2) (Fin 2) ℂ) = 1 := by
    simpa [QGate.dagger] using Matrix.mem_unitaryGroup_iff.mp (SetLike.coe_mem V)
  have hdagger_mul_V :
      ((QGate.dagger V : QGate 1) : Matrix (Fin 2) (Fin 2) ℂ) *
        (V : Matrix (Fin 2) (Fin 2) ℂ) = 1 := by
    simpa [QGate.dagger, Matrix.star_eq_conjTranspose] using
      Matrix.UnitaryGroup.star_mul_self V
  have hVV :
      ((V * V : QGate 1) : Matrix (Fin 2) (Fin 2) ℂ) =
        (U : Matrix (Fin 2) (Fin 2) ℂ) := by
    simpa [pow_two] using congrArg Subtype.val hv
  have hV_mul_dagger00 :=
    congrFun (congrFun hV_mul_dagger (0 : Fin 2)) (0 : Fin 2)
  have hV_mul_dagger01 :=
    congrFun (congrFun hV_mul_dagger (0 : Fin 2)) (1 : Fin 2)
  have hV_mul_dagger10 :=
    congrFun (congrFun hV_mul_dagger (1 : Fin 2)) (0 : Fin 2)
  have hV_mul_dagger11 :=
    congrFun (congrFun hV_mul_dagger (1 : Fin 2)) (1 : Fin 2)
  have hdagger_mul_V00 :=
    congrFun (congrFun hdagger_mul_V (0 : Fin 2)) (0 : Fin 2)
  have hdagger_mul_V01 :=
    congrFun (congrFun hdagger_mul_V (0 : Fin 2)) (1 : Fin 2)
  have hdagger_mul_V10 :=
    congrFun (congrFun hdagger_mul_V (1 : Fin 2)) (0 : Fin 2)
  have hdagger_mul_V11 :=
    congrFun (congrFun hdagger_mul_V (1 : Fin 2)) (1 : Fin 2)
  have hVV00 := congrFun (congrFun hVV (0 : Fin 2)) (0 : Fin 2)
  have hVV01 := congrFun (congrFun hVV (0 : Fin 2)) (1 : Fin 2)
  have hVV10 := congrFun (congrFun hVV (1 : Fin 2)) (0 : Fin 2)
  have hVV11 := congrFun (congrFun hVV (1 : Fin 2)) (1 : Fin 2)
  simp [Matrix.mul_apply, Fin.sum_univ_two] at hV_mul_dagger00
  simp [Matrix.mul_apply, Fin.sum_univ_two] at hV_mul_dagger01
  simp [Matrix.mul_apply, Fin.sum_univ_two] at hV_mul_dagger10
  simp [Matrix.mul_apply, Fin.sum_univ_two] at hV_mul_dagger11
  simp [Matrix.mul_apply, Fin.sum_univ_two] at hdagger_mul_V00
  simp [Matrix.mul_apply, Fin.sum_univ_two] at hdagger_mul_V01
  simp [Matrix.mul_apply, Fin.sum_univ_two] at hdagger_mul_V10
  simp [Matrix.mul_apply, Fin.sum_univ_two] at hdagger_mul_V11
  simp [Matrix.mul_apply, Fin.sum_univ_two] at hVV00
  simp [Matrix.mul_apply, Fin.sum_univ_two] at hVV01
  simp [Matrix.mul_apply, Fin.sum_univ_two] at hVV10
  simp [Matrix.mul_apply, Fin.sum_univ_two] at hVV11
  apply Subtype.ext
  ext i j
  fin_cases i <;> fin_cases j <;>
    simp [controlledAt_0_2_matrix, controlledAt_1_2_matrix,
      controlledAt_0_1_pauliX_matrix, controlled_controlled_matrix, cv02Matrix, cv12Matrix,
      cx01Matrix, ccMatrix, Matrix.mul_apply, Fin.sum_univ_eight, hV_mul_dagger00,
      hV_mul_dagger01, hV_mul_dagger10, hV_mul_dagger11, hdagger_mul_V00, hdagger_mul_V01,
      hdagger_mul_V10, hdagger_mul_V11, hVV00, hVV01, hVV10, hVV11]
