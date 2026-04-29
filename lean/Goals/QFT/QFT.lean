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

## Circuit structure (n qubits)

For each qubit m:
  1. Apply H to qubit m
  2. Apply controlled-R_{j+1} for j = 1, …, n-1-m
Then apply the bit-reversal permutation.

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

/-- Package the QFT matrix as a gate. -/
noncomputable def qftGate (n : ℕ) : QGate n :=
  ⟨qftMatrix n, by sorry⟩

private noncomputable def qftControlledLayer (n : ℕ) (target : Fin n) : Circuit n :=
  (List.finRange (n - (target.val + 1))).map fun offset =>
    let control : Fin n := ⟨target.val + offset.val + 1, by
      have hoff : offset.val < n - (target.val + 1) := offset.is_lt
      omega⟩
    let hct : control ≠ target := by
      have hgt : target.val < control.val := by
        have hoff : offset.val < n - (target.val + 1) := offset.is_lt
        dsimp [control]
        omega
      intro hEq
      have : control.val = target.val := congrArg Fin.val hEq
      omega
    controlledPhaseAt control target hct (offset.val + 2)

private noncomputable def qftQubitLayer (n : ℕ) (target : Fin n) : Circuit n :=
  [hadamardAt target] ++ qftControlledLayer n target

private noncomputable def qftLayers (n : ℕ) : Circuit n :=
  (List.finRange n).foldr (fun target acc => qftQubitLayer n target ++ acc) []

noncomputable def qftCircuit (n : ℕ) : Circuit n :=
  qftLayers n ++ [bitReverse]

/-- The QFT circuit matrix equals the normalized DFT matrix. -/
theorem qft_correct (n : ℕ) :
    (circuitMatrix (qftCircuit n) : Matrix (Fin (2 ^ n)) (Fin (2 ^ n)) ℂ) = qftMatrix n := by
  sorry

end AutoQuantum.QFT
