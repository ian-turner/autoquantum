import AutoQuantum.Core.Circuit
import AutoQuantum.Lemmas.Gate

/-!
# Circuit Composition Lemmas

Mathematical properties of the circuit semantics defined in
`AutoQuantum.Core.Circuit`: nil/singleton/append identities, sequential
composition, and circuit inversion.

This file is part of the **Lemmas** module and may be generated or elaborated
by AI assistants.
-/

namespace AutoQuantum

open Matrix

/-! ## Basic identities -/

/-- The empty circuit is the identity. -/
@[simp]
lemma circuitMatrix_nil {n : ℕ} : circuitMatrix ([] : Circuit n) = 1 := by
  simp [circuitMatrix]

/-- A single-gate circuit has matrix equal to that gate. -/
@[simp]
lemma circuitMatrix_singleton {n : ℕ} (U : QGate n) :
    circuitMatrix [U] = U := by
  simp [circuitMatrix]

/-! ## Auxiliary lemma for foldl -/

/-- Running foldl with a non-identity initial accumulator equals multiplying the
     circuit matrix on the right by that accumulator. -/
private lemma foldl_unitary_mul {n : ℕ} (c : Circuit n) (init : QGate n) :
    c.foldl (fun acc U => U * acc) init = circuitMatrix c * init := by
  induction c generalizing init with
  | nil => simp [circuitMatrix]
  | cons U c ih =>
    simp only [List.foldl_cons]
    rw [ih]
    have hcons : circuitMatrix (U :: c) = circuitMatrix c * U := by
      simp only [circuitMatrix, List.foldl_cons, mul_one]
      exact ih U
    rw [hcons, mul_assoc]

/-! ## Concatenation -/

/-- The matrix of a concatenated circuit: running c₁ then c₂ gives
    `circuitMatrix c₂ * circuitMatrix c₁`. -/
lemma circuitMatrix_append {n : ℕ} (c₁ c₂ : Circuit n) :
    circuitMatrix (c₁ ++ c₂) = circuitMatrix c₂ * circuitMatrix c₁ := by
  simp only [circuitMatrix, List.foldl_append]
  exact foldl_unitary_mul c₂ _

/-- The matrix of `seqComp c₁ c₂`: c₁ applied first (rightmost), c₂ second. -/
lemma seqComp_matrix {n : ℕ} (c₁ c₂ : Circuit n) :
    circuitMatrix (seqComp c₁ c₂) = circuitMatrix c₂ * circuitMatrix c₁ :=
  circuitMatrix_append c₁ c₂

/-! ## Circuit inversion -/

/-- Reversing gate order and inverting each gate undoes the original circuit. -/
lemma circuitMatrix_inv {n : ℕ} (c : Circuit n) :
    circuitMatrix (c.reverse.map (fun U => U⁻¹)) = (circuitMatrix c)⁻¹ := by
  induction c with
  | nil => simp [circuitMatrix]
  | cons U c ih =>
    simp only [List.reverse_cons, List.map_append, List.map_cons, List.map_nil]
    rw [circuitMatrix_append]
    rw [ih, circuitMatrix_singleton]
    have hcons : circuitMatrix (U :: c) = circuitMatrix c * U := by
      simp only [circuitMatrix, List.foldl_cons, mul_one]
      exact foldl_unitary_mul c U
    rw [hcons, _root_.mul_inv_rev]

/-! ## Lifted circuits -/

/-- Lifting every gate in a circuit through `tensorWithId m` lifts the circuit matrix through
    the same embedding. -/
lemma circuitMatrix_tensorWithIdCircuit {k : ℕ} (m : ℕ) (c : Circuit k) :
    circuitMatrix (tensorWithIdCircuit m c) = tensorWithId m (circuitMatrix c) := by
  induction c with
  | nil =>
      simp [tensorWithIdCircuit, circuitMatrix]
  | cons U c ih =>
      rw [show tensorWithIdCircuit m (U :: c) = [tensorWithId m U] ++ tensorWithIdCircuit m c by rfl,
        circuitMatrix_append, circuitMatrix_singleton, ih]
      rw [show circuitMatrix (U :: c) = circuitMatrix c * U by
        simpa using (circuitMatrix_append [U] c)]
      rw [tensorWithId_mul]

/-- Lifting every gate in a circuit through `idTensorWith m` lifts the circuit matrix through
    the same embedding. -/
lemma circuitMatrix_idTensorCircuit {k : ℕ} (m : ℕ) (c : Circuit k) :
    circuitMatrix (idTensorCircuit m c) = idTensorWith m (circuitMatrix c) := by
  induction c with
  | nil =>
      simp [idTensorCircuit, circuitMatrix]
  | cons U c ih =>
      rw [show idTensorCircuit m (U :: c) = [idTensorWith m U] ++ idTensorCircuit m c by rfl,
        circuitMatrix_append, circuitMatrix_singleton, ih]
      rw [show circuitMatrix (U :: c) = circuitMatrix c * U by
        simpa using (circuitMatrix_append [U] c)]
      rw [idTensorWith_mul]

end AutoQuantum
