import AutoQuantum.Core.Gate

/-!
# Quantum Circuit Composition [Core]

Defines quantum circuits as ordered sequences of gate steps and their
denotational semantics as unitary matrix products.

This file is part of the **Core** module and is intended for human review.
It contains the circuit type definitions, the semantics function
`circuitMatrix`, the execution function `runCircuit`, and circuit
construction helpers. Mathematical properties of circuit composition
(nil/append/inversion lemmas) live in `AutoQuantum.Lemmas.Circuit`.
-/

namespace AutoQuantum

open Matrix

/-! ## Circuit types -/

/-- A quantum circuit on n qubits: an ordered list of gate steps. -/
abbrev Circuit (n : ℕ) := List (QGate n)

/-! ## Circuit semantics -/

/-- The unitary matrix of a circuit (product of gate matrices, left-to-right).
    `circuitMatrix [U₁, U₂, …, Uₖ]` = Uₖ * … * U₂ * U₁
    (the first gate is applied first, so it appears rightmost in the product). -/
def circuitMatrix {n : ℕ} (c : Circuit n) : QGate n :=
  c.foldl (fun acc U => U * acc) 1

/-- Apply a circuit to a quantum state. -/
noncomputable def runCircuit {n : ℕ} (c : Circuit n) (ψ : QState n) : QState n :=
  applyGate (circuitMatrix c) ψ

/-! ## Circuit construction helpers -/

/-- Wrap a single gate as a one-step circuit. -/
def singleGate {n : ℕ} (U : QGate n) : Circuit n := [U]

/-- Sequential composition: run c₁ first, then c₂. -/
def seqComp {n : ℕ} (c₁ c₂ : Circuit n) : Circuit n := c₁ ++ c₂

/-- Lift a circuit to the last k qubits of an (m+k)-qubit register by mapping each gate
    through `idTensorWith m`. -/
noncomputable def idTensorCircuit {k : ℕ} (m : ℕ) (c : Circuit k) : Circuit (m + k) :=
  c.map (idTensorWith m)

/-- Lift a circuit to the first k qubits of a (k+m)-qubit register by mapping each gate
    through `tensorWithId m`. -/
noncomputable def tensorWithIdCircuit {k : ℕ} (m : ℕ) (c : Circuit k) : Circuit (k + m) :=
  c.map (tensorWithId m)

/-! ## Correctness predicates -/

/-- A circuit `c` implements unitary `U` if their matrices are equal. -/
def Circuit.Implements {n : ℕ} (c : Circuit n) (U : QGate n) : Prop :=
  circuitMatrix c = U

end AutoQuantum
