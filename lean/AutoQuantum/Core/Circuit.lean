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

/-- A single step in a quantum circuit: an n-qubit unitary applied at one moment.
    The full embedded n-qubit unitary is stored directly; see `Gate.tensorWithId`
    for constructing embedded gate steps. -/
structure GateStep (n : ℕ) where
  /-- The n-qubit unitary matrix for this step. -/
  unitary : QGate n

/-- A quantum circuit on n qubits: an ordered list of gate steps. -/
abbrev Circuit (n : ℕ) := List (GateStep n)

/-! ## Circuit semantics -/

/-- The unitary matrix of a circuit (product of gate matrices, left-to-right).
    `circuitMatrix [U₁, U₂, …, Uₖ]` = Uₖ * … * U₂ * U₁
    (the first gate is applied first, so it appears rightmost in the product). -/
def circuitMatrix {n : ℕ} (c : Circuit n) : QGate n :=
  c.foldl (fun acc step => step.unitary * acc) 1

/-- Apply a circuit to a quantum state. -/
noncomputable def runCircuit {n : ℕ} (c : Circuit n) (ψ : QState n) : QState n :=
  applyGate (circuitMatrix c) ψ

/-! ## Circuit construction helpers -/

/-- Wrap a single gate as a one-step circuit. -/
def singleGate {n : ℕ} (U : QGate n) : Circuit n := [⟨U⟩]

/-- Sequential composition: run c₁ first, then c₂. -/
def seqComp {n : ℕ} (c₁ c₂ : Circuit n) : Circuit n := c₁ ++ c₂

/-! ## Correctness predicates -/

/-- A circuit `c` implements unitary `U` if their matrices are equal. -/
def Circuit.Implements {n : ℕ} (c : Circuit n) (U : QGate n) : Prop :=
  circuitMatrix c = U

/-- A circuit `c` is correct for target operator `T` (given as a plain matrix with
    a unitarity proof) if the circuit's matrix equals T. -/
def Circuit.CorrectFor {n : ℕ} (c : Circuit n)
    (T : Matrix (Fin (2 ^ n)) (Fin (2 ^ n)) ℂ)
    (_hT : T ∈ Matrix.unitaryGroup (Fin (2 ^ n)) ℂ) : Prop :=
  (circuitMatrix c : Matrix (Fin (2 ^ n)) (Fin (2 ^ n)) ℂ) = T

end AutoQuantum
