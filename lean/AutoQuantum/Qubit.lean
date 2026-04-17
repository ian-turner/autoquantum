import AutoQuantum.Hilbert
import Mathlib.Analysis.Complex.Trigonometric
import Mathlib.Data.Complex.Basic
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Basic

/-!
# Single-Qubit Primitives

This module defines the basic single-qubit states and their properties.

A single qubit lives in C^2, which is `QHilbert 1 = EuclideanSpace ℂ (Fin 2)`.
-/

namespace AutoQuantum

/-! ## The single-qubit Hilbert space -/

/-- The single-qubit Hilbert space C^2. -/
abbrev Qubit := QHilbert 1

/-! ## Computational basis states -/

/-- The |0> state (qubit = 0). -/
noncomputable def ket0 : QState 1 := basisState 1 ⟨0, by norm_num⟩

/-- The |1> state (qubit = 1). -/
noncomputable def ket1 : QState 1 := basisState 1 ⟨1, by norm_num⟩

/-- |0> and |1> are orthogonal. -/
lemma ket0_braket_ket1 : QState.braket ket0 ket1 = 0 := by
  simp [ket0, ket1, basisState_braket]

/-- |0> is normalized. -/
lemma ket0_braket_ket0 : QState.braket ket0 ket0 = 1 := by
  simp [ket0, basisState_braket]

/-- |1> is normalized. -/
lemma ket1_braket_ket1 : QState.braket ket1 ket1 = 1 := by
  simp [ket1, basisState_braket]

/-! ## Plus and minus states -/

/-- The |+> = (|0> + |1>) / sqrt(2) state (eigenstate of X with eigenvalue +1). -/
noncomputable def ketPlus : QState 1 :=
  QState.mk
    (superpose ((1 : ℂ) / Real.sqrt 2) ((1 : ℂ) / Real.sqrt 2) ket0.vec ket1.vec)
    (by
      apply superpose_norm_eq_one
      · exact QState.norm_eq_one ket0
      · exact QState.norm_eq_one ket1
      · simpa [QState.braket] using ket0_braket_ket1
      · have hcoef : Complex.normSq (((1 : ℂ) / Real.sqrt 2)) = 1 / 2 := by
          rw [Complex.normSq_div]
          norm_num [Real.sq_sqrt (show (0 : ℝ) ≤ 2 by positivity)]
        nlinarith [hcoef]
    )

/-- The |-> = (|0> - |1>) / sqrt(2) state (eigenstate of X with eigenvalue -1). -/
noncomputable def ketMinus : QState 1 :=
  QState.mk
    (superpose ((1 : ℂ) / Real.sqrt 2) (-((1 : ℂ) / Real.sqrt 2)) ket0.vec ket1.vec)
    (by
      apply superpose_norm_eq_one
      · exact QState.norm_eq_one ket0
      · exact QState.norm_eq_one ket1
      · simpa [QState.braket] using ket0_braket_ket1
      · have hcoef : Complex.normSq (((1 : ℂ) / Real.sqrt 2)) = 1 / 2 := by
          rw [Complex.normSq_div]
          norm_num [Real.sq_sqrt (show (0 : ℝ) ≤ 2 by positivity)]
        have hneg : Complex.normSq (-((1 : ℂ) / Real.sqrt 2)) = 1 / 2 := by
          rw [Complex.normSq_neg]
          exact hcoef
        calc
          Complex.normSq (((1 : ℂ) / Real.sqrt 2)) +
              Complex.normSq (-((1 : ℂ) / Real.sqrt 2)) = 1 / 2 + 1 / 2 := by
                rw [hcoef, hneg]
          _ = 1 := by norm_num
    )

/-- |+> and |-> are orthogonal. -/
lemma ketPlus_braket_ketMinus : QState.braket ketPlus ketMinus = 0 := by
  simp [QState.braket, QState.vec, QState.mk, ketPlus, ketMinus, ket0, ket1, basisState,
    superpose, PiLp.inner_apply, Fin.sum_univ_two]

/-! ## Bloch sphere representation -/

/-- A general single-qubit pure state parameterized by Bloch sphere angles (theta, phi):
    cos(theta/2)|0> + exp(i*phi) sin(theta/2)|1>. -/
noncomputable def blochState (theta phi : ℝ) : QState 1 :=
  QState.mk
    (superpose (Real.cos (theta / 2) : ℂ)
      (Complex.exp (Complex.I * phi) * Real.sin (theta / 2)) ket0.vec ket1.vec)
    (by
      apply superpose_norm_eq_one
      · exact QState.norm_eq_one ket0
      · exact QState.norm_eq_one ket1
      · simpa [QState.braket] using ket0_braket_ket1
      · have hphase : Complex.normSq (Complex.exp (Complex.I * phi)) = 1 := by
          rw [Complex.normSq_eq_norm_sq, Complex.norm_exp_I_mul_ofReal]
          norm_num
        rw [Complex.normSq_ofReal, Complex.normSq_mul, hphase, one_mul, Complex.normSq_ofReal]
        nlinarith [Real.sin_sq_add_cos_sq (theta / 2)]
    )

/-- |0> is the north pole of the Bloch sphere: blochState 0 phi = |0> for any phi. -/
lemma blochState_zero_eq_ket0 (phi : ℝ) : (blochState 0 phi).vec = ket0.vec := by
  ext i
  fin_cases i <;> simp [QState.vec, QState.mk, blochState, superpose, ket0, ket1, basisState]

/-- |1> is the south pole: blochState pi phi = exp(i*phi)|1> (up to global phase). -/
lemma blochState_pi_eq_ket1 (phi : ℝ) :
    (blochState Real.pi phi).vec = Complex.exp (Complex.I * phi) • ket1.vec := by
  ext i
  fin_cases i <;> simp [QState.vec, QState.mk, blochState, superpose, ket0, ket1, basisState]

end AutoQuantum
