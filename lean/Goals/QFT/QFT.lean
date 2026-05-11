import AutoQuantum.Core.Circuit
import Mathlib.Analysis.SpecialFunctions.Complex.Circle
import Mathlib.RingTheory.RootsOfUnity.Basic
import Mathlib.RingTheory.RootsOfUnity.Complex
import Mathlib.RingTheory.RootsOfUnity.PrimitiveRoots
import Mathlib.Algebra.Ring.GeomSum

/-!
# Quantum Fourier Transform (QFT)

The QFT on n qubits is the unitary:
  QFT |j⟩ = (1/√(2^n)) ∑_{k=0}^{2^n-1} ω^{jk} |k⟩
where ω = exp(2πi / 2^n).

As a matrix:
  qftMatrix n j k = (1/√(2^n)) · ω^{j·k}

## References

- Nielsen & Chuang, §5.1
-/

namespace AutoQuantum.QFT

open AutoQuantum Matrix

/-- The primitive 2^n-th root of unity ω = exp(2πi / 2^n). -/
noncomputable def omega (n : ℕ) : ℂ :=
  Complex.exp (2 * Real.pi * Complex.I / (2 ^ n : ℂ))

/-- The normalized QFT matrix: `qftMatrix n j k = (1/√(2^n)) · ω^{j·k}`. -/
noncomputable def qftMatrix (n : ℕ) : Matrix (Fin (2 ^ n)) (Fin (2 ^ n)) ℂ :=
  fun j k => (1 / Real.sqrt (2 ^ n : ℝ) : ℂ) * (omega n) ^ (j.val * k.val)

noncomputable def qftCircuit (n : ℕ) : Circuit n := sorry

/-- The QFT circuit matrix equals the normalized DFT matrix. -/
theorem qft_correct (n : ℕ) :
    (circuitMatrix (qftCircuit n) : Matrix (Fin (2 ^ n)) (Fin (2 ^ n)) ℂ) = qftMatrix n := by
  sorry

end AutoQuantum.QFT
