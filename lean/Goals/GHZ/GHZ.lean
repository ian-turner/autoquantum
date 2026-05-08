import AutoQuantum.Core.Circuit
import AutoQuantum.Core.Tensor
import AutoQuantum.States.GHZ
import Mathlib.Algebra.BigOperators.Fin
import Mathlib.Tactic

/-!
# Greenberger–Horne–Zeilinger (GHZ) State Preparation

The GHZ state on n qubits is the entangled state:
  |GHZ⟩ = (|0…0⟩ + |1…1⟩) / √2
-/

open AutoQuantum Complex
open scoped InnerProductSpace

/-- The GHZ circuit on n qubits (requires n ≥ 1). -/
noncomputable def ghzCircuit (n : ℕ) (hn : n ≥ 1) : Circuit n := sorry

/-- The GHZ circuit applied to |0…0⟩ yields the GHZ state. -/
theorem ghz_correct (n : ℕ) (hn : n ≥ 1) :
    runCircuit (ghzCircuit n hn) (basisState n 0) = ghzState n := by
  sorry
