import AutoQuantum.Core.Circuit
import AutoQuantum.Lemmas.Circuit
import AutoQuantum.Lemmas.Hilbert
import Mathlib.Algebra.BigOperators.Fin
import Mathlib.Tactic

/-!
# Uniform Superposition State |+⟩^⊗n

This module defines the n-qubit uniform superposition state and the circuit
that prepares it from |0…0⟩ by applying a Hadamard gate to each qubit.

The target state is:
  |+⟩^⊗n = H^⊗n |0…0⟩ = (1/√(2^n)) ∑_{k=0}^{2^n-1} |k⟩

The preparation circuit applies `hadamardAt i` for each i : Fin n.

## References

- Nielsen & Chuang, §1.3 (Hadamard gate and superposition)
-/

namespace AutoQuantum.HPlus

open Matrix AutoQuantum Complex
open scoped Kronecker InnerProductSpace

/-! ## The uniform superposition state -/

-- `hPlusVector` is defined in `Core.Hilbert`; re-exported here for local convenience.

/-- The uniform superposition state |+⟩^⊗n: the equal-weight sum of all basis states.
    For n = 0 this is the unique 1-dimensional unit vector |∅⟩ = |0⟩.
    Normalization is proved in `Lemmas.Hilbert.hPlusVector_norm`. -/
noncomputable def hPlusState (n : ℕ) : QState n :=
  QState.mk (hPlusVector n) (hPlusVector_norm n)

/-! ## The uniform superposition circuit -/

/-- The circuit that produces |+⟩^⊗n: apply Hadamard to every qubit. -/
noncomputable def hPlusCircuit (n : ℕ) : Circuit n :=
  (List.finRange n).map fun i => ⟨hadamardAt i⟩

/-! ## Correctness theorem -/

/-- Applying a Hadamard to every qubit of |0…0⟩ yields the uniform superposition state. -/
theorem hPlus_correct (n : ℕ) :
    runCircuit (hPlusCircuit n) (basisState n 0) = hPlusState n := by
  sorry

end AutoQuantum.HPlus
