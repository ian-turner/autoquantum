import AutoQuantum.Core.Circuit
import AutoQuantum.Core.Gate
import AutoQuantum.Core.Tensor
import Mathlib.Algebra.BigOperators.Fin
import Mathlib.Tactic

/-!
# Bell State

The Bell_00 state is the entangled state:
  |Ψ⟩ = (|00⟩ + |11⟩) / √2
-/

open AutoQuantum Complex
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
