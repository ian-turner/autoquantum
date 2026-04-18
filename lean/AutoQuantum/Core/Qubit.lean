import AutoQuantum.Core.Hilbert
import Mathlib.Analysis.Complex.Trigonometric
import Mathlib.Data.Complex.Basic
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Basic

/-!
# Single-Qubit Primitives [Core]

Defines the standard single-qubit states.

A single qubit lives in C^2, which is `QHilbert 1 = EuclideanSpace ℂ (Fin 2)`.

This file is part of the **Core** module and is intended for human review.
It contains definitions of the standard qubit states together with the
normalization proofs required to construct them as elements of `QState 1`.
Properties of these states (orthogonality, Bloch sphere lemmas, etc.) live in
`AutoQuantum.Lemmas.Qubit`.
-/

namespace AutoQuantum

/-! ## The single-qubit Hilbert space -/

/-- The single-qubit Hilbert space C^2. -/
abbrev Qubit := QHilbert 1

/-! ## Computational basis states -/

/-- The |0⟩ state. -/
noncomputable def ket0 : QState 1 := basisState 1 ⟨0, by norm_num⟩

/-- The |1⟩ state. -/
noncomputable def ket1 : QState 1 := basisState 1 ⟨1, by norm_num⟩

/-! ## Plus and minus states -/

/-- The |+⟩ = (|0⟩ + |1⟩) / √2 state (eigenstate of X with eigenvalue +1). -/
noncomputable def ketPlus : QState 1 :=
  QState.mk
    (superpose ((1 : ℂ) / Real.sqrt 2) ((1 : ℂ) / Real.sqrt 2) ket0.vec ket1.vec)
    (by
      apply superpose_norm_eq_one
      · exact QState.norm_eq_one ket0
      · exact QState.norm_eq_one ket1
      · simp [QState.vec, ket0, ket1, basisState, PiLp.inner_apply]
      · have hcoef : Complex.normSq (((1 : ℂ) / Real.sqrt 2)) = 1 / 2 := by
          rw [Complex.normSq_div]
          norm_num [Real.sq_sqrt (show (0 : ℝ) ≤ 2 by positivity)]
        nlinarith [hcoef]
    )

/-- The |−⟩ = (|0⟩ − |1⟩) / √2 state (eigenstate of X with eigenvalue −1). -/
noncomputable def ketMinus : QState 1 :=
  QState.mk
    (superpose ((1 : ℂ) / Real.sqrt 2) (-((1 : ℂ) / Real.sqrt 2)) ket0.vec ket1.vec)
    (by
      apply superpose_norm_eq_one
      · exact QState.norm_eq_one ket0
      · exact QState.norm_eq_one ket1
      · simp [QState.vec, ket0, ket1, basisState, PiLp.inner_apply]
      · have hcoef : Complex.normSq (((1 : ℂ) / Real.sqrt 2)) = 1 / 2 := by
          rw [Complex.normSq_div]
          norm_num [Real.sq_sqrt (show (0 : ℝ) ≤ 2 by positivity)]
        have hneg : Complex.normSq (-((1 : ℂ) / Real.sqrt 2)) = 1 / 2 := by
          rw [Complex.normSq_neg]; exact hcoef
        linarith [hcoef, hneg]
    )

/-! ## Bloch sphere representation -/

/-- A general single-qubit pure state parameterized by Bloch sphere angles (θ, φ):
    cos(θ/2)|0⟩ + exp(iφ) sin(θ/2)|1⟩. -/
noncomputable def blochState (theta phi : ℝ) : QState 1 :=
  QState.mk
    (superpose (Real.cos (theta / 2) : ℂ)
      (Complex.exp (Complex.I * phi) * Real.sin (theta / 2)) ket0.vec ket1.vec)
    (by
      apply superpose_norm_eq_one
      · exact QState.norm_eq_one ket0
      · exact QState.norm_eq_one ket1
      · simp [QState.vec, ket0, ket1, basisState, PiLp.inner_apply]
      · have hphase : Complex.normSq (Complex.exp (Complex.I * phi)) = 1 := by
          rw [Complex.normSq_eq_norm_sq, Complex.norm_exp_I_mul_ofReal]
          norm_num
        rw [Complex.normSq_ofReal, Complex.normSq_mul, hphase, one_mul, Complex.normSq_ofReal]
        nlinarith [Real.sin_sq_add_cos_sq (theta / 2)]
    )

end AutoQuantum
