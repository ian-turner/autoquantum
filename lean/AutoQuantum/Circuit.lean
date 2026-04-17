import AutoQuantum.Gate

/-!
# Quantum Circuit Composition

This module defines quantum circuits as sequences of gate applications
and provides their semantics (as unitary matrix products).

A circuit on n qubits is represented as a list of `GateStep n` values.
The circuit's matrix is the product of the step matrices in order.
-/

namespace AutoQuantum

open Matrix

/-! ## Circuit steps -/

/-- A single step in a quantum circuit: a gate applied to a subset of qubits.
    For simplicity in this scaffold, we represent the full embedded n-qubit unitary
    directly. See `Gate.tensorWithId` for constructing embedded gates. -/
structure GateStep (n : ℕ) where
  /-- The n-qubit unitary matrix for this step. -/
  unitary : QGate n

/-- A quantum circuit on n qubits: an ordered list of gate steps. -/
abbrev Circuit (n : ℕ) := List (GateStep n)

/-! ## Circuit semantics -/

/-- The unitary matrix of a circuit (product of gate matrices, left-to-right).
    `circuitMatrix [U1, U2, ..., Uk]` = Uk * ... * U2 * U1
    (i.e., the first gate is applied first, so it appears rightmost in the product). -/
def circuitMatrix {n : ℕ} (c : Circuit n) : QGate n :=
  c.foldr (fun step acc => step.unitary * acc) 1

-- Note: foldr with initial value 1 and operation U * acc gives
-- U1 * (U2 * (... * (Uk * 1))) = U1 * U2 * ... * Uk
-- which means U1 is applied first (rightmost in conventional matrix notation).

/-- Apply a circuit to a quantum state. -/
noncomputable def runCircuit {n : ℕ} (c : Circuit n) (ψ : QState n) : QState n :=
  applyGate (circuitMatrix c) ψ

/-- The empty circuit is the identity. -/
@[simp]
lemma circuitMatrix_nil {n : ℕ} : circuitMatrix ([] : Circuit n) = 1 := by
  simp [circuitMatrix]

/-- A single-gate circuit has matrix equal to that gate. -/
@[simp]
lemma circuitMatrix_singleton {n : ℕ} (s : GateStep n) :
    circuitMatrix [s] = s.unitary := by
  simp [circuitMatrix]

/-- The matrix of a concatenated circuit is the product of the matrices. -/
lemma circuitMatrix_append {n : ℕ} (c₁ c₂ : Circuit n) :
    circuitMatrix (c₁ ++ c₂) = circuitMatrix c₁ * circuitMatrix c₂ := by
  induction c₁ with
  | nil => simp [circuitMatrix]
  | cons s c ih =>
    show s.unitary * circuitMatrix (c ++ c₂) = s.unitary * circuitMatrix c * circuitMatrix c₂
    rw [ih, mul_assoc]

/-! ## Circuit construction helpers -/

/-- A single-gate circuit. -/
def singleGate {n : ℕ} (U : QGate n) : Circuit n := [⟨U⟩]

/-- Sequential composition of two circuits. -/
def seqComp {n : ℕ} (c₁ c₂ : Circuit n) : Circuit n := c₁ ++ c₂

/-- Apply gate U then gate V: V after U (U first). -/
lemma seqComp_matrix {n : ℕ} (c₁ c₂ : Circuit n) :
    circuitMatrix (seqComp c₁ c₂) = circuitMatrix c₁ * circuitMatrix c₂ :=
  circuitMatrix_append c₁ c₂

/-- The circuit resulting from reversing a list of gates is the inverse circuit. -/
lemma circuitMatrix_reverse {n : ℕ} (c : Circuit n) :
    circuitMatrix c.reverse = (circuitMatrix c)⁻¹ := by
  sorry
  -- Proof: By induction. (U1 * U2 * ... * Uk)^(-1) = Uk^(-1) * ... * U2^(-1) * U1^(-1)
  -- and reversing the list gives Uk * ... * U1, each of which equals its own inverse
  -- in the unitary group.

/-! ## Circuit correctness statement template -/

/-- A circuit `c` implements unitary `U` if their matrices are equal. -/
def Circuit.Implements {n : ℕ} (c : Circuit n) (U : QGate n) : Prop :=
  circuitMatrix c = U

/-- A circuit `c` is correct for target operator `T` (given as a plain matrix with
    a proof of unitarity) if the circuit's matrix equals T. -/
def Circuit.CorrectFor {n : ℕ} (c : Circuit n)
    (T : Matrix (Fin (2 ^ n)) (Fin (2 ^ n)) ℂ)
    (hT : T ∈ Matrix.unitaryGroup (Fin (2 ^ n)) ℂ) : Prop :=
  (circuitMatrix c : Matrix (Fin (2 ^ n)) (Fin (2 ^ n)) ℂ) = T

end AutoQuantum
