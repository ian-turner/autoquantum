import AutoQuantum.Hilbert
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
    (EuclideanSpace.single ⟨0, by norm_num⟩ ((1 : ℂ) / Real.sqrt 2) +
     EuclideanSpace.single ⟨1, by norm_num⟩ ((1 : ℂ) / Real.sqrt 2))
    (by
      sorry
      -- Proof: ‖(1/sqrt 2)|0> + (1/sqrt 2)|1>‖ = sqrt(1/2 + 1/2) = 1
    )

/-- The |-> = (|0> - |1>) / sqrt(2) state (eigenstate of X with eigenvalue -1). -/
noncomputable def ketMinus : QState 1 :=
  QState.mk
    (EuclideanSpace.single ⟨0, by norm_num⟩ ((1 : ℂ) / Real.sqrt 2) +
     EuclideanSpace.single ⟨1, by norm_num⟩ (-(1 : ℂ) / Real.sqrt 2))
    (by sorry)

/-- |+> and |-> are orthogonal. -/
lemma ketPlus_braket_ketMinus : QState.braket ketPlus ketMinus = 0 := by
  sorry

/-! ## Bloch sphere representation -/

/-- A general single-qubit pure state parameterized by Bloch sphere angles (theta, phi):
    cos(theta/2)|0> + exp(i*phi) sin(theta/2)|1>. -/
noncomputable def blochState (theta phi : ℝ) : QState 1 :=
  QState.mk
    (EuclideanSpace.single ⟨0, by norm_num⟩ (Real.cos (theta / 2) : ℂ) +
     EuclideanSpace.single ⟨1, by norm_num⟩
       (Complex.exp (Complex.I * phi) * Real.sin (theta / 2)))
    (by
      sorry
      -- Proof: ‖v‖^2 = cos^2(theta/2) + |exp(i*phi)|^2 sin^2(theta/2) = cos^2(theta/2) + sin^2(theta/2) = 1
    )

/-- |0> is the north pole of the Bloch sphere: blochState 0 phi = |0> for any phi. -/
lemma blochState_zero_eq_ket0 (phi : ℝ) : (blochState 0 phi).vec = ket0.vec := by
  sorry

/-- |1> is the south pole: blochState pi phi = exp(i*phi)|1> (up to global phase). -/
lemma blochState_pi_eq_ket1 (phi : ℝ) :
    (blochState Real.pi phi).vec = Complex.exp (Complex.I * phi) • ket1.vec := by
  sorry

end AutoQuantum
