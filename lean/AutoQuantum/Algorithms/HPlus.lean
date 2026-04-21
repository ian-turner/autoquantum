import AutoQuantum.Core.Circuit
import AutoQuantum.Core.Qubit
import AutoQuantum.Core.Tensor
import AutoQuantum.Lemmas.Circuit
import AutoQuantum.Lemmas.Hilbert
import AutoQuantum.Lemmas.Tensor
import Mathlib.Algebra.BigOperators.Fin
import Mathlib.Tactic

/-!
# Uniform Superposition State |+⟩^⊗n

This module defines the n-qubit uniform superposition state and the circuit
that prepares it from |0…0⟩ by applying a Hadamard gate to each qubit.

The target state is:
  |+⟩^⊗n = H^⊗n |0…0⟩ = (1/√(2^n)) ∑_{k=0}^{2^n-1} |k⟩

The preparation circuit applies `hadamardAt i` for each i : Fin n.

## References

- Nielsen & Chuang, §1.3 (Hadamard gate and superposition)
-/

namespace AutoQuantum.HPlus

open Matrix AutoQuantum Complex
open scoped Kronecker InnerProductSpace

/-! ## The uniform superposition state -/

/-- The uniform superposition vector for n qubits: `(1/√(2^n)) ∑_k |k⟩`. -/
noncomputable def hPlusVector (n : ℕ) : QHilbert n :=
  (1 / Real.sqrt (2 ^ n : ℝ) : ℂ) • ∑ k : Fin (2 ^ n), (basisState n k).vec

/-- The uniform superposition vector has unit norm. -/
lemma hPlusVector_norm (n : ℕ) : ‖hPlusVector n‖ = 1 := by
  have hcoord : ∀ j : Fin (2 ^ n), hPlusVector n j = (1 / Real.sqrt (2 ^ n : ℝ) : ℂ) := by
    intro j
    simp [hPlusVector, basisState, QState.vec]
  have hsq : ‖hPlusVector n‖ ^ 2 = 1 := by
    rw [PiLp.norm_sq_eq_of_L2]
    calc
      ∑ j : Fin (2 ^ n), ‖hPlusVector n j‖ ^ 2
          = ∑ _j : Fin (2 ^ n), ‖(1 / Real.sqrt (2 ^ n : ℝ) : ℂ)‖ ^ 2 := by
              simp [hcoord]
      _ = (2 ^ n : ℝ) * ‖(1 / Real.sqrt (2 ^ n : ℝ) : ℂ)‖ ^ 2 := by
            simp [Nat.cast_pow]
      _ = (2 ^ n : ℝ) * ((1 / Real.sqrt (2 ^ n : ℝ)) ^ 2) := by
            simp
      _ = 1 := by
            rcases Nat.eq_zero_or_pos (2 ^ n) with hpow | hpow
            · exfalso
              exact pow_ne_zero n (by norm_num) hpow
            · have hpow' : (0 : ℝ) < (2 ^ n : ℝ) := by exact_mod_cast hpow
              have hsqrt : Real.sqrt (2 ^ n : ℝ) ≠ 0 := Real.sqrt_ne_zero'.mpr hpow'
              field_simp [hsqrt]
              rw [Real.sq_sqrt (show (0 : ℝ) ≤ (2 ^ n : ℝ) by positivity)]
  calc
    ‖hPlusVector n‖ = Real.sqrt (‖hPlusVector n‖ ^ 2) := (Real.sqrt_sq (norm_nonneg _)).symm
    _ = Real.sqrt 1 := by rw [hsq]
    _ = 1 := Real.sqrt_one

/-- The uniform superposition state |+⟩^⊗n: the equal-weight sum of all basis states.
    For n = 0 this is the unique 1-dimensional unit vector |∅⟩ = |0⟩. -/
noncomputable def hPlusState (n : ℕ) : QState n :=
  QState.mk (hPlusVector n) (hPlusVector_norm n)

/-! ## The uniform superposition circuit -/

/-- The circuit that produces |+⟩^⊗n: apply Hadamard to every qubit. -/
noncomputable def hPlusCircuit (n : ℕ) : Circuit n :=
  (List.finRange n).map fun i => hadamardAt i

/-! ## Correctness theorem -/

/-- The 1-qubit plus state equals the uniform superposition state for 1 qubit. -/
lemma ketPlus_eq_hPlusState_one : ketPlus = hPlusState 1 := by
  apply Subtype.ext
  ext i
  fin_cases i <;> simp [ketPlus, hPlusState, hPlusVector, ket0, ket1, basisState, superpose, QState.vec]

/-- The all-zero basis state in a (1+n)-qubit system equals the tensor product
    of the zero states in 1-qubit and n-qubit systems. -/
lemma basisState_zero_tensor (n : ℕ) :
    basisState (1 + n) 0 = tensorState (basisState 1 0) (basisState n 0) := by
  apply Subtype.ext
  let e := tensorIndexEquiv 1 n
  have he00 : e (0, 0) = (0 : Fin (2 ^ (1 + n))) := Fin.ext (by simp [e, tensorIndexEquiv])
  ext j; obtain ⟨⟨a, b⟩, rfl⟩ := e.surjective j
  -- Normalize to .vec form so rw can match
  change (basisState (1 + n) 0).vec (e (a, b)) =
      (tensorState (basisState 1 0) (basisState n 0)).vec (e (a, b))
  have hten : (tensorState (basisState 1 0) (basisState n 0)).vec (e (a, b)) =
      (basisState 1 0).vec a * (basisState n 0).vec b := by
    show tensorVec (basisState 1 0).vec (basisState n 0).vec (e (a, b)) = _
    exact tensorVec_apply _ _ a b
  rw [hten]
  simp only [QState.vec, basisState, PiLp.single_apply]
  by_cases ha : a = 0 <;> by_cases hb : b = 0
  · subst ha hb; simp [he00]
  · subst ha
    have : e (0, b) ≠ 0 :=
      fun h => hb (congrArg Prod.snd (e.injective (h.trans he00.symm)))
    simp [hb, this]
  · subst hb
    have : e (a, 0) ≠ 0 :=
      fun h => ha (congrArg Prod.fst (e.injective (h.trans he00.symm)))
    simp [ha, this]
  · have : e (a, b) ≠ 0 :=
      fun h => ha (congrArg Prod.fst (e.injective (h.trans he00.symm)))
    simp [ha, hb, this]

/-- The all-zero basis state in an (n+1)-qubit system equals the tensor product
    of the zero states in n-qubit and 1-qubit systems. -/
lemma basisState_zero_tensor' (n : ℕ) :
    basisState (n + 1) 0 = tensorState (basisState n 0) (basisState 1 0) := by
  apply Subtype.ext
  let e := tensorIndexEquiv n 1
  have he00 : e (0, 0) = (0 : Fin (2 ^ (n + 1))) := Fin.ext (by simp [e, tensorIndexEquiv])
  ext j; obtain ⟨⟨a, b⟩, rfl⟩ := e.surjective j
  change (basisState (n + 1) 0).vec (e (a, b)) =
      (tensorState (basisState n 0) (basisState 1 0)).vec (e (a, b))
  have hten : (tensorState (basisState n 0) (basisState 1 0)).vec (e (a, b)) =
      (basisState n 0).vec a * (basisState 1 0).vec b := by
    show tensorVec (basisState n 0).vec (basisState 1 0).vec (e (a, b)) = _
    exact tensorVec_apply _ _ a b
  rw [hten]
  simp only [QState.vec, basisState, PiLp.single_apply]
  by_cases ha : a = 0 <;> by_cases hb : b = 0
  · subst ha hb; simp [he00]
  · subst ha
    have : e (0, b) ≠ 0 :=
      fun h => hb (congrArg Prod.snd (e.injective (h.trans he00.symm)))
    simp [hb, this]
  · subst hb
    have : e (a, 0) ≠ 0 :=
      fun h => ha (congrArg Prod.fst (e.injective (h.trans he00.symm)))
    simp [ha, this]
  · have : e (a, b) ≠ 0 :=
      fun h => ha (congrArg Prod.fst (e.injective (h.trans he00.symm)))
    simp [ha, hb, this]

/-- The (1+n)-qubit uniform superposition vector equals the tensor product
    of the 1-qubit and n-qubit uniform superpositions. -/
lemma hPlusVector_succ (n : ℕ) :
    hPlusVector (1 + n) = (tensorState (hPlusState 1) (hPlusState n)).vec := by
  let e := tensorIndexEquiv 1 n
  ext j; obtain ⟨⟨a, b⟩, rfl⟩ := e.surjective j
  have hten : (tensorState (hPlusState 1) (hPlusState n)).vec (e (a, b)) =
      (hPlusState 1).vec a * (hPlusState n).vec b := by
    show tensorVec (hPlusState 1).vec (hPlusState n).vec (e (a, b)) = _
    exact tensorVec_apply _ _ a b
  -- Both sides are 1/√(2^(1+n))
  have hlhs : hPlusVector (1 + n) (e (a, b)) = (1 / Real.sqrt (2 ^ (1 + n) : ℝ) : ℂ) :=
    by simp [hPlusVector, basisState, QState.vec]
  have h1 : (hPlusState 1).vec a = (1 / Real.sqrt (2 ^ 1 : ℝ) : ℂ) := by
    simp [hPlusState, QState.mk, QState.vec, hPlusVector, basisState]
    fin_cases a <;> simp
  have hn : (hPlusState n).vec b = (1 / Real.sqrt (2 ^ n : ℝ) : ℂ) := by
    simp [hPlusState, QState.mk, QState.vec, hPlusVector, basisState]
  rw [hlhs, hten, h1, hn, pow_add, pow_one, Real.sqrt_mul (by norm_num : (0 : ℝ) ≤ 2)]
  push_cast; field_simp

/-- The (n+1)-qubit uniform superposition vector equals the tensor product
    of the n-qubit and 1-qubit uniform superpositions. -/
lemma hPlusVector_succ' (n : ℕ) :
    hPlusVector (n + 1) = (tensorState (hPlusState n) (hPlusState 1)).vec := by
  let e := tensorIndexEquiv n 1
  ext j; obtain ⟨⟨a, b⟩, rfl⟩ := e.surjective j
  have hten : (tensorState (hPlusState n) (hPlusState 1)).vec (e (a, b)) =
      (hPlusState n).vec a * (hPlusState 1).vec b := by
    show tensorVec (hPlusState n).vec (hPlusState 1).vec (e (a, b)) = _
    exact tensorVec_apply _ _ a b
  have hlhs : hPlusVector (n + 1) (e (a, b)) = (1 / Real.sqrt (2 ^ (n + 1) : ℝ) : ℂ) :=
    by simp [hPlusVector, basisState, QState.vec]
  have hn : (hPlusState n).vec a = (1 / Real.sqrt (2 ^ n : ℝ) : ℂ) := by
    simp [hPlusState, QState.mk, QState.vec, hPlusVector, basisState]
  have h1 : (hPlusState 1).vec b = (1 / Real.sqrt (2 ^ 1 : ℝ) : ℂ) := by
    simp [hPlusState, QState.mk, QState.vec, hPlusVector, basisState]
    fin_cases b <;> simp
  rw [hlhs, hten, hn, h1, pow_add, pow_one, Real.sqrt_mul (by positivity : (0 : ℝ) ≤ 2 ^ n)]
  push_cast; field_simp

/-- Applying a Hadamard to every qubit of |0…0⟩ yields the uniform superposition state. -/
theorem hPlus_correct (n : ℕ) :
    runCircuit (hPlusCircuit n) (basisState n 0) = hPlusState n := by
  induction n with
  | zero =>
    simp only [hPlusCircuit, List.finRange_zero, List.map_nil]
    rw [runCircuit, circuitMatrix_nil, applyGate_one]
    apply Subtype.ext
    ext i; fin_cases i
    simp [basisState, hPlusState, hPlusVector, QState.vec, QState.mk]
  | succ n ih =>
    -- Split circuit: last gate is hadamardAt (Fin.last n) = I_n ⊗ H
    have hcircuit : hPlusCircuit (n + 1) =
        ((List.finRange n).map fun i => (hadamardAt (Fin.castSucc i) : QGate (n + 1))) ++
        [hadamardAt (Fin.last n)] := by
      simp only [hPlusCircuit, List.finRange_succ_last, List.map_append, List.map_map,
        List.map_cons, List.map_nil, Function.comp_def]
    rw [hcircuit]
    simp only [runCircuit, circuitMatrix_append, circuitMatrix_singleton, applyGate_mul]
    -- Replace last gate by idTensorWith n hadamard
    rw [hadamardAt_last_eq]
    -- Split the input state: |0^(n+1)⟩ = |0^n⟩ ⊗ |0⟩
    rw [basisState_zero_tensor']
    -- Apply init circuit; blocked on hadamardAt_castSucc_eq
    have hinit : applyGate
        (circuitMatrix ((List.finRange n).map fun i => (hadamardAt (Fin.castSucc i) : QGate (n + 1))))
        (tensorState (basisState n 0) (basisState 1 0)) =
        tensorState (hPlusState n) (basisState 1 0) := by
      sorry  -- blocked on hadamardAt_castSucc_eq
    rw [hinit, idTensorWith_apply]
    -- H|0⟩ = |+⟩ = hPlusState 1
    rw [show applyGate hadamard (basisState 1 0) = hPlusState 1 from by
      rw [show (basisState 1 0 : QState 1) = ket0 from rfl,
          hadamard_apply_ket0, ketPlus_eq_hPlusState_one]]
    -- Conclude: |+⟩^n ⊗ |+⟩ = |+⟩^(n+1)
    apply Subtype.ext
    exact (hPlusVector_succ' n).symm

end AutoQuantum.HPlus
