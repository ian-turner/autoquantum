import AutoQuantum.Core.Circuit
import AutoQuantum.Core.Tensor
import Mathlib.Algebra.BigOperators.Fin
import Mathlib.Tactic

/-!
# Uniform Superposition State |+⟩^⊗n

The n-qubit uniform superposition state is:
  |+⟩^⊗n = H^⊗n |0…0⟩ = (1/√(2^n)) ∑_{k=0}^{2^n-1} |k⟩
-/

open AutoQuantum Complex
open scoped InnerProductSpace

/-- The uniform superposition vector for n qubits: `(1/√(2^n)) ∑_k |k⟩`. -/
noncomputable def hPlusVector (n : ℕ) : QHilbert n :=
  (1 / Real.sqrt (2 ^ n : ℝ) : ℂ) • ∑ k : Fin (2 ^ n), (basisState n k).vec

/-- The uniform superposition state |+⟩^⊗n. -/
noncomputable def hPlusState (n : ℕ) : QState n :=
  QState.mk (hPlusVector n) (by sorry)
