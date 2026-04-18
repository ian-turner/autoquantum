import AutoQuantum.Core.Gate

/-!
# Gate Lemmas

Derived properties of the quantum gates defined in `AutoQuantum.Core.Gate`:
the `applyGate` composition laws and self-inverse identities.

This file is part of the **Lemmas** module and may be generated or elaborated
by AI assistants.
-/

namespace AutoQuantum

/-! ## applyGate laws -/

/-- The identity gate leaves every state unchanged. -/
lemma applyGate_one {k : ℕ} (ψ : QState k) :
    applyGate (1 : QGate k) ψ = ψ := by
  apply Subtype.ext
  change Matrix.toEuclideanLin
      ((1 : QGate k) : Matrix (Fin (2 ^ k)) (Fin (2 ^ k)) ℂ) ψ.vec = ψ.vec
  simp

/-- Composing gates corresponds to sequential application. -/
lemma applyGate_mul {k : ℕ} (U V : QGate k) (ψ : QState k) :
    applyGate (U * V) ψ = applyGate U (applyGate V ψ) := by
  apply Subtype.ext
  change Matrix.toEuclideanLin
      (((U * V : QGate k) : Matrix (Fin (2 ^ k)) (Fin (2 ^ k)) ℂ)) ψ.vec
      = Matrix.toEuclideanLin (U : Matrix (Fin (2 ^ k)) (Fin (2 ^ k)) ℂ)
          (Matrix.toEuclideanLin (V : Matrix (Fin (2 ^ k)) (Fin (2 ^ k)) ℂ) ψ.vec)
  simp

/-! ## Gate self-inverse identities -/

/-- H² = I (Hadamard is self-inverse). -/
lemma hadamard_mul_self : hadamard * hadamard = (1 : QGate 1) := by
  apply Subtype.ext
  have hne : Real.sqrt 2 ≠ 0 := Real.sqrt_ne_zero'.mpr (by norm_num)
  ext i j
  fin_cases i <;> fin_cases j <;>
    simp [hadamard, hadamardMatrix]
  all_goals
    have hneC : (Real.sqrt 2 : ℂ) ≠ 0 := by
      exact_mod_cast hne
    field_simp [hneC]
    ring_nf
    have hsq : ((Real.sqrt 2 : ℂ) ^ 2) = 2 := by
      exact_mod_cast Real.sq_sqrt (show (0 : ℝ) ≤ 2 by norm_num)
    simpa using hsq.symm

/-- CNOT² = I (CNOT is self-inverse). -/
lemma cnot_mul_self : cnot * cnot = (1 : QGate 2) := by
  apply Subtype.ext
  ext i j
  fin_cases i <;> fin_cases j <;>
    simp [cnot, cnotMatrix]

end AutoQuantum
