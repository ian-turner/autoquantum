import AutoQuantum.Core.Circuit
import AutoQuantum.Core.Tensor
import Mathlib.Algebra.BigOperators.Fin
import Mathlib.Tactic

/-!
# Greenberger–Horne–Zeilinger (GHZ) State Preparation

The GHZ state on n qubits is the entangled state:
  |GHZ⟩ = (|0…0⟩ + |1…1⟩) / √2

The preparation circuit is:
  1. Apply a Hadamard gate to the first qubit (qubit 0)
  2. Apply CNOT from qubit 0 to each of qubits 1, 2, …, n-1

## References

- Nielsen & Chuang, §1.3.6
-/

namespace AutoQuantum.GHZ

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

/-- The GHZ circuit on n qubits (requires n ≥ 1).
    Hadamard on qubit 0, then CNOT from qubit 0 to each qubit i.succ. -/
noncomputable def ghzCircuit (n : ℕ) (hn : n ≥ 1) : Circuit n :=
  match n, hn with
  | 0, h => by exfalso; omega
  | n + 1, _ =>
      [hadamardAt 0] ++
      (List.finRange n).map fun i =>
        controlledAt 0 i.succ (Ne.symm (Fin.succ_ne_zero i)) pauliX

/-- The GHZ circuit applied to |0…0⟩ yields the GHZ state. -/
theorem ghz_correct (n : ℕ) (hn : n ≥ 1) :
    runCircuit (ghzCircuit n hn) (basisState n 0) = ghzState n := by
  sorry

end AutoQuantum.GHZ
