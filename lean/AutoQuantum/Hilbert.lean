import Mathlib.Analysis.InnerProductSpace.Basic
import Mathlib.Analysis.InnerProductSpace.PiL2
import Mathlib.Analysis.InnerProductSpace.Orthonormal
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Basic
import Mathlib.Analysis.Complex.Norm
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
  -- EuclideanSpace.single forms an orthonormal family; extract the (j,k) entry.
  have h : Orthonormal ℂ (fun i : Fin (2 ^ n) => EuclideanSpace.single i (1 : ℂ)) :=
    EuclideanSpace.orthonormal_single
  rw [orthonormal_iff_ite] at h
  exact h j k

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
  simp only [superpose]
  -- Step 1: the two summands are orthogonal
  have hov : ⟪a • u, b • v⟫_ℂ = 0 := by
    rw [inner_smul_left, inner_smul_right, horth, mul_zero, mul_zero]
  -- Step 2: expand ‖a•u + b•v‖² using norm_add_sq (𝕜 = ℂ must be given explicitly since
  -- the `re` in the RHS makes the field metavariable ambiguous to Lean's elaborator).
  have hsq : ‖a • u + b • v‖ ^ 2 = 1 := by
    have expand := @norm_add_sq ℂ (QHilbert n) _ _ _ (a • u) (b • v)
    -- expand : ‖a•u + b•v‖² = ‖a•u‖² + 2 * re⟪a•u, b•v⟫_ℂ + ‖b•v‖²
    rw [hov, map_zero, mul_zero, add_zero] at expand
    -- expand : ‖a•u + b•v‖² = ‖a•u‖² + ‖b•v‖²
    rw [expand]
    simp only [norm_smul, hu, hv, mul_one, Complex.sq_norm]
    exact hnorm
  -- Step 3: recover the norm from its square (norm ≥ 0, norm² = 1 → norm = 1)
  calc ‖a • u + b • v‖
      = Real.sqrt (‖a • u + b • v‖ ^ 2) := (Real.sqrt_sq (norm_nonneg _)).symm
    _ = Real.sqrt 1                       := by rw [hsq]
    _ = 1                                 := Real.sqrt_one

end AutoQuantum
