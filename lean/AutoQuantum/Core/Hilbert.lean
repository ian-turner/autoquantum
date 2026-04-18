import Mathlib.Analysis.InnerProductSpace.Basic
import Mathlib.Analysis.InnerProductSpace.PiL2
import Mathlib.Analysis.InnerProductSpace.Orthonormal
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Basic
import Mathlib.Analysis.Complex.Norm
import Mathlib.LinearAlgebra.Matrix.Hermitian
import Mathlib.LinearAlgebra.UnitaryGroup

/-!
# Hilbert Spaces for Quantum Computing [Core]

Defines the Hilbert space structure used throughout AutoQuantum.

An n-qubit system lives in C^(2^n), formalized as
`EuclideanSpace ℂ (Fin (2^n))`.

Quantum states are unit vectors in this space.

This file is part of the **Core** module and is intended for human review.
It contains only definitions and the minimal proofs required to construct them.
-/

namespace AutoQuantum

open scoped InnerProductSpace

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

/-- The inner product ⟨φ|ψ⟩ of two quantum states. -/
noncomputable def braket {n : ℕ} (phi psi : QState n) : ℂ :=
  @inner ℂ (QHilbert n) _ phi.vec psi.vec

end QState

/-! ## Computational Basis -/

/-- The k-th computational basis state |k⟩ in the n-qubit Hilbert space. -/
noncomputable def basisState (n : ℕ) (k : Fin (2 ^ n)) : QState n :=
  ⟨EuclideanSpace.single k 1, by simp [PiLp.norm_single]⟩

/-! ## Superposition -/

/-- A linear combination of two vectors (not necessarily normalized). -/
noncomputable def superpose {n : ℕ} (a b : ℂ) (u v : QHilbert n) : QHilbert n :=
  a • u + b • v

/-- Superposition of two orthonormal states with unit-norm coefficients is normalized.

    This lemma lives in Core because it is required to construct normalized superposition
    states such as |+⟩, |−⟩, and the Bloch sphere parameterization. -/
lemma superpose_norm_eq_one {n : ℕ} (a b : ℂ) (u v : QHilbert n)
    (hu : ‖u‖ = 1) (hv : ‖v‖ = 1)
    (horth : @inner ℂ (QHilbert n) _ u v = 0)
    (hnorm : Complex.normSq a + Complex.normSq b = 1) :
    ‖superpose a b u v‖ = 1 := by
  simp only [superpose]
  have hov : ⟪a • u, b • v⟫_ℂ = 0 := by
    rw [inner_smul_left, inner_smul_right, horth, mul_zero, mul_zero]
  have hsq : ‖a • u + b • v‖ ^ 2 = 1 := by
    have expand := @norm_add_sq ℂ (QHilbert n) _ _ _ (a • u) (b • v)
    rw [hov, map_zero, mul_zero, add_zero] at expand
    rw [expand]
    simp only [norm_smul, hu, hv, mul_one, Complex.sq_norm]
    exact hnorm
  calc ‖a • u + b • v‖
      = Real.sqrt (‖a • u + b • v‖ ^ 2) := (Real.sqrt_sq (norm_nonneg _)).symm
    _ = Real.sqrt 1                       := by rw [hsq]
    _ = 1                                 := Real.sqrt_one

end AutoQuantum
