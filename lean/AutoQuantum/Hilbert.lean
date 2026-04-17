import Mathlib.Analysis.InnerProductSpace.Basic
import Mathlib.Analysis.InnerProductSpace.PiL2
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Basic
import Mathlib.LinearAlgebra.Matrix.Hermitian
import Mathlib.LinearAlgebra.UnitaryGroup

/-!
# Hilbert Spaces for Quantum Computing

This module defines the Hilbert space structure used throughout AutoQuantum.

An n-qubit system lives in the space C^(2^n), formalized as
`EuclideanSpace ℂ (Fin (2^n))`.

Quantum states are unit vectors in this space.
-/

namespace AutoQuantum

/-! ## The n-qubit Hilbert space -/

/-- The Hilbert space for an n-qubit quantum system: C^(2^n). -/
abbrev QHilbert (n : ℕ) := EuclideanSpace ℂ (Fin (2 ^ n))

/-- A quantum state: a unit vector in the n-qubit Hilbert space. -/
def QState (n : ℕ) := {v : QHilbert n // ‖v‖ = 1}

namespace QState

/-- The underlying vector of a quantum state. -/
def vec {n : ℕ} (psi : QState n) : QHilbert n := psi.val

@[simp]
lemma norm_eq_one {n : ℕ} (psi : QState n) : ‖psi.vec‖ = 1 := psi.property

/-- Construct a quantum state from a vector, given a proof of normalization. -/
def mk {n : ℕ} (v : QHilbert n) (h : ‖v‖ = 1) : QState n := ⟨v, h⟩

/-- The inner product <phi|psi> of two quantum states. -/
noncomputable def braket {n : ℕ} (phi psi : QState n) : ℂ :=
  @inner ℂ (QHilbert n) _ phi.vec psi.vec

/-- The probability amplitude <phi|psi> has norm <= 1 (Cauchy-Schwarz). -/
lemma braket_norm_le_one {n : ℕ} (phi psi : QState n) : ‖braket phi psi‖ ≤ 1 := by
  have h := norm_inner_le_norm (𝕜 := ℂ) phi.vec psi.vec
  rw [phi.norm_eq_one, psi.norm_eq_one, mul_one] at h
  exact h

end QState

/-! ## Computational Basis -/

/-- The k-th computational basis state |k> in the n-qubit Hilbert space. -/
noncomputable def basisState (n : ℕ) (k : Fin (2 ^ n)) : QState n :=
  ⟨EuclideanSpace.single k 1, by simp [PiLp.norm_single]⟩

/-- Basis states are orthonormal. -/
lemma basisState_braket {n : ℕ} (j k : Fin (2 ^ n)) :
    QState.braket (basisState n j) (basisState n k) = if j = k then 1 else 0 := by
  simp only [QState.braket, basisState, QState.vec]
  sorry
  -- Proof: inner(e_j, e_k) = sum_i conj((e_j)_i) * (e_k)_i = conj(delta_ji) * delta_ki = delta_jk

/-! ## Superposition -/

/-- A linear combination of two vectors (not necessarily normalized). -/
noncomputable def superpose {n : ℕ} (a b : ℂ) (u v : QHilbert n) : QHilbert n :=
  a • u + b • v

/-- Superposition of two orthonormal states with unit-norm coefficients is normalized. -/
lemma superpose_norm_eq_one {n : ℕ} (a b : ℂ) (u v : QHilbert n)
    (hu : ‖u‖ = 1) (hv : ‖v‖ = 1)
    (horth : @inner ℂ (QHilbert n) _ u v = 0)
    (hnorm : Complex.normSq a + Complex.normSq b = 1) :
    ‖superpose a b u v‖ = 1 := by
  sorry
  -- Proof: ‖a•u + b•v‖^2 = |a|^2 ‖u‖^2 + 2·Re(inner(a•u, b•v)) + |b|^2 ‖v‖^2
  --                      = |a|^2 + 0 + |b|^2 = 1

end AutoQuantum
