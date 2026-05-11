import AutoQuantum.Core.Circuit
import AutoQuantum.Core.Gate
import AutoQuantum.Core.Tensor
import AutoQuantum.States.HPlus
import Mathlib.Algebra.BigOperators.Fin
import Mathlib.Tactic

open AutoQuantum Complex
open scoped InnerProductSpace

/-- Apply Hadamard to every qubit: H on qubit 0, then 1, …, then n−1. -/
noncomputable def hPlusCircuit : ∀ n, Circuit n
  | 0     => []
  | n + 1 => tensorWithIdCircuit 1 (hPlusCircuit n) ++ [hadamardAt (Fin.last n)]

theorem hPlus_correct (n : ℕ) :
    runCircuit (hPlusCircuit n) (basisState n 0) = hPlusState n := by
  sorry
