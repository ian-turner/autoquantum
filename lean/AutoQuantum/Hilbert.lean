/-!
# Hilbert Spaces for Quantum Computing

This module defines the Hilbert space structure used throughout AutoQuantum.

An n-qubit system lives in the space `ℂ^(2^n)`, formalized as
`EuclideanSpace ℂ (Fin (2^n))`.

Quantum states are unit vectors in this space.
-/

import Mathlib.Analysis.InnerProductSpace.Basic
import Mathlib.Analysis.InnerProductSpace.PiL2
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Basic
import Mathlib.LinearAlgebra.Matrix.Hermitian
import Mathlib.LinearAlgebra.UnitaryGroup

namespace AutoQuantum

/-! ## The n-qubit Hilbert space -/

/-- The Hilbert space for an n-qubit quantum system: ℂ^(2^n). -/
abbrev QHilbert (n : ℕ) := EuclideanSpace ℂ (Fin (2 ^ n))

/-- A quantum state: a unit vector in the n-qubit Hilbert space. -/
def QState (n : ℕ) := {v : QHilbert n // ‖v‖ = 1}

namespace QState

/-- The underlying vector of a quantum state. -/
def vec {n : ℕ} (ψ : QState n) : QHilbert n := ψ.val

@[simp]
lemma norm_eq_one {n : ℕ} (ψ : QState n) : ‖ψ.vec‖ = 1 := ψ.property

/-- Construct a quantum state from a vector, given a proof of normalization. -/
def mk {n : ℕ} (v : QHilbert n) (h : ‖v‖ = 1) : QState n := ⟨v, h⟩

/-- The inner product of two quantum states. -/
def inner {n : ℕ} (φ ψ : QState n) : ℂ :=
  @inner ℂ _ _ φ.vec ψ.vec

/-- The probability amplitude ⟨φ|ψ⟩ has absolute value ≤ 1 (Cauchy-Schwarz). -/
lemma inner_abs_le_one {n : ℕ} (φ ψ : QState n) : Complex.abs (inner φ ψ) ≤ 1 := by
  have h := @abs_inner_le_norm ℂ _ _ φ.vec ψ.vec
  simp [inner, φ.norm_eq_one, ψ.norm_eq_one] at h
  exact h

end QState

/-! ## Computational Basis -/

/-- The k-th computational basis state |k⟩ in the n-qubit Hilbert space. -/
def basisState (n : ℕ) (k : Fin (2 ^ n)) : QState n :=
  ⟨EuclideanSpace.single k 1, by simp [EuclideanSpace.norm_single]⟩

/-- Basis states are orthonormal. -/
lemma basisState_inner_eq {n : ℕ} (j k : Fin (2 ^ n)) :
    QState.inner (basisState n j) (basisState n k) = if j = k then 1 else 0 := by
  simp [QState.inner, basisState, EuclideanSpace.inner_single_left,
        EuclideanSpace.single, inner_apply]
  split_ifs with h
  · subst h; simp
  · simp [EuclideanSpace.single, h]

/-! ## Superposition -/

/-- A linear combination of states (not necessarily normalized). -/
def superpose {n : ℕ} (α β : ℂ) (ψ φ : QHilbert n) : QHilbert n :=
  α • ψ + β • φ

/-- The state resulting from applying a scalar multiple and sum of basis states,
    normalized when |α|² + |β|² = 1. -/
lemma superpose_norm_sq {n : ℕ} (α β : ℂ) (ψ φ : QHilbert n)
    (hψ : ‖ψ‖ = 1) (hφ : ‖φ‖ = 1) (horth : @inner ℂ _ _ ψ φ = 0)
    (hnorm : Complex.normSq α + Complex.normSq β = 1) :
    ‖superpose α β ψ φ‖ = 1 := by
  sorry
  -- Proof: ‖α•ψ + β•φ‖² = |α|²‖ψ‖² + 2·Re⟨α•ψ, β•φ⟩ + |β|²‖φ‖²
  --                      = |α|² + 0 + |β|² = 1

end AutoQuantum
