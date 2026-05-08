import AutoQuantum.Core.Circuit
import AutoQuantum.Core.Gate
import AutoQuantum.Core.Tensor
import AutoQuantum.States.Bell
import Mathlib.Algebra.BigOperators.Fin
import Mathlib.Tactic

/-!
# Bell State Preparation

The Bell state is the entangled state:
  |Φ+⟩ = (|00⟩ + |11⟩) / √2
-/

open AutoQuantum Complex
open scoped InnerProductSpace

noncomputable def bellCircuit : Circuit 2 := sorry

theorem bell_correct : runCircuit bellCircuit (basisState 2 0) = bellState := by
  sorry
