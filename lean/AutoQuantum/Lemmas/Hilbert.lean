import AutoQuantum.Core.Hilbert
import Mathlib.Analysis.InnerProductSpace.PiL2
import Mathlib.Algebra.BigOperators.Fin

/-!
# Hilbert Space Lemmas

Mathematical properties of the Hilbert space, inner product, basis states, and
superposition operator defined in `AutoQuantum.Core.Hilbert`.

This file is part of the **Lemmas** module and may be generated or elaborated
by AI assistants. All definitions it depends on are in `Core.Hilbert`.
-/

namespace AutoQuantum

open scoped InnerProductSpace
open Complex

/-- The probability amplitude ⟨φ|ψ⟩ has norm ≤ 1 (Cauchy-Schwarz). -/
lemma QState.braket_norm_le_one {n : ℕ} (phi psi : QState n) : ‖braket phi psi‖ ≤ 1 := by
  have h := norm_inner_le_norm (𝕜 := ℂ) phi.vec psi.vec
  rw [phi.norm_eq_one, psi.norm_eq_one, mul_one] at h
  exact h

/-- Basis states are orthonormal: ⟨j|k⟩ = δ_{j,k}. -/
lemma basisState_braket {n : ℕ} (j k : Fin (2 ^ n)) :
    QState.braket (basisState n j) (basisState n k) = if j = k then 1 else 0 := by
  simp only [QState.braket, basisState, QState.vec]
  have h : Orthonormal ℂ (fun i : Fin (2 ^ n) => EuclideanSpace.single i (1 : ℂ)) :=
    EuclideanSpace.orthonormal_single
  rw [orthonormal_iff_ite] at h
  exact h j k

end AutoQuantum
