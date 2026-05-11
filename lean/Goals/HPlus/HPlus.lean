import AutoQuantum.States.HPlus
import Mathlib.Tactic

/-!
# Uniform Superposition State |+⟩^⊗n

The preparation circuit applies `hadamardAt i` for each i : Fin n.

## References

- Nielsen & Chuang, §1.3
-/

open AutoQuantum Complex
open scoped InnerProductSpace

/-- The circuit that produces |+⟩^⊗n: apply Hadamard to every qubit. -/
noncomputable def hPlusCircuit (n : ℕ) : Circuit n := sorry

/-- Applying Hadamard to every qubit of |0…0⟩ yields the uniform superposition state. -/
theorem hPlus_correct (n : ℕ) :
    runCircuit (hPlusCircuit n) (basisState n 0) = hPlusState n := by
  sorry
