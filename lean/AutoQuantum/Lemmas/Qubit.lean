import AutoQuantum.Core.Qubit
import AutoQuantum.Lemmas.Hilbert

/-!
# Single-Qubit Lemmas

Properties of the standard qubit states defined in `AutoQuantum.Core.Qubit`:
orthogonality/normalization of the computational basis, orthogonality of |+⟩
and |−⟩, and Bloch sphere identities.

This file is part of the **Lemmas** module and may be generated or elaborated
by AI assistants.
-/

namespace AutoQuantum

/-! ## Computational basis orthonormality -/

/-- |0⟩ and |1⟩ are orthogonal. -/
lemma ket0_braket_ket1 : QState.braket ket0 ket1 = 0 := by
  simp [ket0, ket1, basisState_braket]

/-- |0⟩ is normalized. -/
lemma ket0_braket_ket0 : QState.braket ket0 ket0 = 1 := by
  simp [ket0, basisState_braket]

/-- |1⟩ is normalized. -/
lemma ket1_braket_ket1 : QState.braket ket1 ket1 = 1 := by
  simp [ket1, basisState_braket]

/-! ## Plus/minus orthogonality -/

/-- |+⟩ and |−⟩ are orthogonal. -/
lemma ketPlus_braket_ketMinus : QState.braket ketPlus ketMinus = 0 := by
  simp [QState.braket, QState.vec, QState.mk, ketPlus, ketMinus, ket0, ket1, basisState,
    superpose, PiLp.inner_apply, Fin.sum_univ_two]

/-! ## Bloch sphere identities -/

/-- |0⟩ is the north pole of the Bloch sphere: blochState 0 φ = |0⟩. -/
lemma blochState_zero_eq_ket0 (phi : ℝ) : (blochState 0 phi).vec = ket0.vec := by
  ext i
  fin_cases i <;> simp [QState.vec, QState.mk, blochState, superpose, ket0, ket1, basisState]

/-- |1⟩ is the south pole (up to global phase): blochState π φ = exp(iφ)|1⟩. -/
lemma blochState_pi_eq_ket1 (phi : ℝ) :
    (blochState Real.pi phi).vec = Complex.exp (Complex.I * phi) • ket1.vec := by
  ext i
  fin_cases i <;> simp [QState.vec, QState.mk, blochState, superpose, ket0, ket1, basisState]

end AutoQuantum
