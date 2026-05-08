import AutoQuantum.Core.Circuit
import AutoQuantum.Core.Gate
import AutoQuantum.Core.Tensor
import Mathlib.Algebra.BigOperators.Fin
import Mathlib.Tactic

/-!
# Greenberger–Horne–Zeilinger (GHZ) State Preparation

The GHZ state on n qubits is the entangled state:
  |GHZ⟩ = (|0…0⟩ + |1…1⟩) / √2
-/

open AutoQuantum Complex
open scoped InnerProductSpace

/-- The index of the all-ones computational basis state: |1…1⟩. -/
def allOnesIndex (n : ℕ) : Fin (2 ^ n) :=
  ⟨2 ^ n - 1, Nat.pred_lt (pow_pos (by norm_num : (0 : ℕ) < 2) n).ne'⟩

/-- The GHZ state vector (unnormalized): |0…0⟩ + |1…1⟩. -/
noncomputable def ghzVector (n : ℕ) : QHilbert n :=
  superpose (1 : ℂ) (1 : ℂ) (basisState n 0).vec (basisState n (allOnesIndex n)).vec

/-- The normalized GHZ state. -/
noncomputable def ghzState (n : ℕ) : QState n :=
  match n with
  | 0 => basisState 0 0
  | n + 1 => QState.mk ((1 / Real.sqrt 2 : ℂ) • ghzVector (n + 1)) (by sorry)
