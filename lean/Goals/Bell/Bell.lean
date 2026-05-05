import AutoQuantum.Core.Circuit
import AutoQuantum.Core.Tensor
import Mathlib.Algebra.BigOperators.Fin
import Mathlib.Tactic

/-!
# Bell State Preparation

The Bell_00 state is the entangled state:
  |Ψ⟩ = (|00⟩ + |11⟩) / √2

The preparation circuit is:
  1. Apply a Hadamard gate to the first qubit (qubit 0)
  2. Apply CNOT from qubit 0 to qubit 1
-/

namespace AutoQuantum.GHZ

open AutoQuantum Complex
open scoped InnerProductSpace

noncomputable def bellVector : QHilbert 2 :=
  superpose (1 / Real.sqrt 2 : ℂ) (1 / Real.sqrt 2 : ℂ) (basisState 2 0).vec (basisState 2 3).vec

noncomputable def bellState : QState 2 := QState.mk bellVector (by sorry)

noncomputable def bellCircuit : Circuit 2 := sorry

theorem bell_correct : runCircuit bellCircuit (basisState 2 0) = bellState := by
  sorry
