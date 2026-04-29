import AutoQuantum.Core.Circuit
import AutoQuantum.Core.Qubit
import AutoQuantum.Core.Tensor
import Mathlib.Algebra.BigOperators.Fin
import Mathlib.Tactic

/-!
# Uniform Superposition State |+⟩^⊗n

The n-qubit uniform superposition state is:
  |+⟩^⊗n = H^⊗n |0…0⟩ = (1/√(2^n)) ∑_{k=0}^{2^n-1} |k⟩

The preparation circuit applies `hadamardAt i` for each i : Fin n.

## References

- Nielsen & Chuang, §1.3
-/

namespace AutoQuantum.HPlus

open AutoQuantum Complex
open scoped InnerProductSpace

/-- The uniform superposition vector for n qubits: `(1/√(2^n)) ∑_k |k⟩`. -/
noncomputable def hPlusVector (n : ℕ) : QHilbert n :=
  (1 / Real.sqrt (2 ^ n : ℝ) : ℂ) • ∑ k : Fin (2 ^ n), (basisState n k).vec

/-- The uniform superposition state |+⟩^⊗n. -/
noncomputable def hPlusState (n : ℕ) : QState n :=
  QState.mk (hPlusVector n) (by sorry)

/-- The circuit that produces |+⟩^⊗n: apply Hadamard to every qubit. -/
noncomputable def hPlusCircuit (n : ℕ) : Circuit n :=
  (List.finRange n).map fun i => hadamardAt i

/-- Applying Hadamard to every qubit of |0…0⟩ yields the uniform superposition state. -/
theorem hPlus_correct (n : ℕ) :
    runCircuit (hPlusCircuit n) (basisState n 0) = hPlusState n := by
  sorry

end AutoQuantum.HPlus
