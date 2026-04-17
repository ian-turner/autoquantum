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
  c.foldl (fun acc step => step.unitary * acc) 1

-- Note: foldl accumulates left-to-right, prepending each gate on the left:
--   init = 1
--   after U1: U1 * 1 = U1
--   after U2: U2 * U1
--   ...
--   after Uk: Uk * ... * U2 * U1
-- so circuitMatrix [U1,...,Uk] = Uk * ... * U1, with U1 rightmost (applied first).

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

/-! ## Auxiliary lemma for foldl -/

/-- Running foldl with a non-identity initial accumulator is the same as
    multiplying the circuit matrix on the right by that accumulator. -/
private lemma foldl_unitary_mul {n : ℕ} (c : Circuit n) (init : QGate n) :
    c.foldl (fun acc step => step.unitary * acc) init = circuitMatrix c * init := by
  induction c generalizing init with
  | nil => simp [circuitMatrix]
  | cons s c ih =>
    simp only [List.foldl_cons]
    rw [ih]
    -- Goal: circuitMatrix c * (s.unitary * init) = circuitMatrix (s :: c) * init
    have hcons : circuitMatrix (s :: c) = circuitMatrix c * s.unitary := by
      simp only [circuitMatrix, List.foldl_cons, mul_one]
      exact ih s.unitary
    rw [hcons, mul_assoc]

/-! ## Concatenation -/

/-- The matrix of a concatenated circuit: c₂'s gates act first (c₂ is rightmost).
    This is the correct matrix-composition law for sequential application:
    running c₁ then c₂ gives `circuitMatrix c₂ * circuitMatrix c₁`. -/
lemma circuitMatrix_append {n : ℕ} (c₁ c₂ : Circuit n) :
    circuitMatrix (c₁ ++ c₂) = circuitMatrix c₂ * circuitMatrix c₁ := by
  simp only [circuitMatrix, List.foldl_append]
  exact foldl_unitary_mul c₂ _

/-! ## Circuit construction helpers -/

/-- A single-gate circuit. -/
def singleGate {n : ℕ} (U : QGate n) : Circuit n := [⟨U⟩]

/-- Sequential composition of two circuits (c₁ first, then c₂). -/
def seqComp {n : ℕ} (c₁ c₂ : Circuit n) : Circuit n := c₁ ++ c₂

/-- The matrix of c₁ followed by c₂: c₁'s matrix is on the right (applied first),
    c₂'s is on the left (applied second). -/
lemma seqComp_matrix {n : ℕ} (c₁ c₂ : Circuit n) :
    circuitMatrix (seqComp c₁ c₂) = circuitMatrix c₂ * circuitMatrix c₁ :=
  circuitMatrix_append c₁ c₂

/-- The inverse circuit: reverse the gate order and invert each gate.
    `circuitMatrix (c.reverse.map (fun s => ⟨s.unitary⁻¹⟩))` undoes `circuitMatrix c`. -/
lemma circuitMatrix_inv {n : ℕ} (c : Circuit n) :
    circuitMatrix (c.reverse.map (fun s => ⟨s.unitary⁻¹⟩)) = (circuitMatrix c)⁻¹ := by
  induction c with
  | nil => simp [circuitMatrix]
  | cons s c ih =>
    -- (s :: c).reverse.map inv = (c.reverse.map inv) ++ [⟨s⁻¹⟩]
    simp only [List.reverse_cons, List.map_append, List.map_cons, List.map_nil]
    rw [circuitMatrix_append]
    -- Goal: circuitMatrix [⟨s.unitary⁻¹⟩] * circuitMatrix (c.reverse.map (fun s => ⟨s.unitary⁻¹⟩))
    --       = (circuitMatrix (s :: c))⁻¹
    rw [ih, circuitMatrix_singleton]
    -- Now: s.unitary⁻¹ * (circuitMatrix c)⁻¹ = (circuitMatrix (s :: c))⁻¹
    have hcons : circuitMatrix (s :: c) = circuitMatrix c * s.unitary := by
      simp only [circuitMatrix, List.foldl_cons, mul_one]
      exact foldl_unitary_mul c s.unitary
    rw [hcons, _root_.mul_inv_rev]

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
