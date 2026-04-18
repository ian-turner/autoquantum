import AutoQuantum.Core.Circuit
import AutoQuantum.Lemmas.Circuit
import Mathlib.Analysis.SpecialFunctions.Complex.Circle
import Mathlib.RingTheory.RootsOfUnity.Basic
import Mathlib.RingTheory.RootsOfUnity.Complex
import Mathlib.RingTheory.RootsOfUnity.PrimitiveRoots
import Mathlib.Algebra.Ring.GeomSum

/-!
# Quantum Fourier Transform (QFT)

This module defines the Quantum Fourier Transform as a quantum circuit and
states the correctness theorem: the circuit matrix equals the DFT matrix.

## Mathematical Background

The QFT on n qubits is the unitary:
  QFT |j> = (1 / sqrt(2^n)) * sum_{k=0}^{2^n-1} omega^{jk} |k>
where omega = exp(2*pi*i / 2^n).

As a matrix:
  QFT[j, k] = (1 / sqrt(2^n)) * exp(2*pi*i * j * k / 2^n)

## Circuit Structure (n qubits, q0 = MSB)

For qubit m (0-indexed, m = 0 is MSB):
  1. Apply H to qubit m
  2. For j = 1, 2, ..., n-1-m:
     Apply controlled-R_{j+1} (control = qubit m+j, target = qubit m)
Then reverse the qubit order (bit-reversal via SWAP cascade).

## References

- Nielsen & Chuang, "Quantum Computation and Quantum Information", §5.1
- Govindankutty et al. 2023: https://arxiv.org/abs/2301.00737
- `notes/qft-formalization-plan.md` for full proof strategy
-/

namespace AutoQuantum.QFT

open Matrix AutoQuantum
open scoped Kronecker

/-! ## The QFT matrix (target) -/

/-- The primitive 2^n-th root of unity omega = exp(2*pi*i / 2^n). -/
noncomputable def omega (n : ℕ) : ℂ :=
  Complex.exp (2 * Real.pi * Complex.I / (2 ^ n : ℂ))

/-- The DFT matrix: `dftMatrix n j k = omega^(j*k)`. -/
noncomputable def dftMatrix (n : ℕ) : Matrix (Fin (2 ^ n)) (Fin (2 ^ n)) ℂ :=
  fun j k => (omega n) ^ (j.val * k.val)

/-- The QFT matrix: the normalized DFT matrix.
    `qftMatrix n j k = (1/sqrt(2^n)) * omega^(j*k)`. -/
noncomputable def qftMatrix (n : ℕ) : Matrix (Fin (2 ^ n)) (Fin (2 ^ n)) ℂ :=
  fun j k => (1 / Real.sqrt (2 ^ n : ℝ) : ℂ) * (omega n) ^ (j.val * k.val)

/-- The QFT matrix equals the DFT matrix scaled by 1/sqrt(2^n). -/
lemma qftMatrix_eq_scale_dft (n : ℕ) :
    qftMatrix n = (1 / Real.sqrt (2 ^ n : ℝ) : ℂ) • dftMatrix n := by
  ext j k
  simp [qftMatrix, dftMatrix, Matrix.smul_apply]

/-- Key identity: omega is a primitive 2^n-th root of unity. -/
lemma omega_pow_two_pow (n : ℕ) : (omega n) ^ (2 ^ n) = 1 := by
  unfold omega
  rw [← Complex.exp_nat_mul]
  change Complex.exp ((((2 ^ n : ℕ) : ℂ) * (2 * (Real.pi : ℂ) * Complex.I / ((2 : ℂ) ^ n)))) = 1
  have hpow : ((2 : ℂ) ^ n) ≠ 0 := by
    exact pow_ne_zero n (show (2 : ℂ) ≠ 0 by norm_num)
  have hcast : ((2 ^ n : ℕ) : ℂ) = (2 : ℂ) ^ n := by
    simp
  have harg : (((2 ^ n : ℕ) : ℂ) * (2 * (Real.pi : ℂ) * Complex.I / ((2 : ℂ) ^ n))) =
      2 * (Real.pi : ℂ) * Complex.I := by
    rw [hcast]
    field_simp [hpow]
  calc
    Complex.exp ((((2 ^ n : ℕ) : ℂ) * (2 * (Real.pi : ℂ) * Complex.I / ((2 : ℂ) ^ n))))
        = Complex.exp (2 * (Real.pi : ℂ) * Complex.I) := by rw [harg]
    _ = 1 := Complex.exp_two_pi_mul_I

/-- omega is on the unit circle: its complex norm-squared equals 1. -/
private lemma omega_normSq (n : ℕ) : Complex.normSq (omega n) = 1 := by
  unfold omega
  have harg : 2 * ↑Real.pi * Complex.I / (2 : ℂ) ^ n =
              ↑(2 * Real.pi / (2 : ℝ) ^ n) * Complex.I := by push_cast; ring
  have hre : (2 * ↑Real.pi * Complex.I / (2 : ℂ) ^ n).re = 0 := by
    rw [harg, Complex.mul_re, Complex.ofReal_re, Complex.ofReal_im, Complex.I_re, Complex.I_im]
    ring
  have him : (2 * ↑Real.pi * Complex.I / (2 : ℂ) ^ n).im = 2 * Real.pi / (2 : ℝ) ^ n := by
    rw [harg, Complex.mul_im, Complex.ofReal_re, Complex.ofReal_im, Complex.I_re, Complex.I_im]
    ring
  rw [Complex.normSq_apply, Complex.exp_re, Complex.exp_im, hre, him, Real.exp_zero,
      one_mul, one_mul]
  have := Real.cos_sq_add_sin_sq (2 * Real.pi / (2 : ℝ) ^ n)
  nlinarith [sq_nonneg (Real.cos (2 * Real.pi / (2 : ℝ) ^ n)),
             sq_nonneg (Real.sin (2 * Real.pi / (2 : ℝ) ^ n))]

/-- star(omega n) = (omega n)⁻¹ since omega lies on the unit circle. -/
private lemma omega_star (n : ℕ) : star (omega n) = (omega n)⁻¹ := by
  have hne : omega n ≠ 0 := Complex.exp_ne_zero _
  have hmul : omega n * star (omega n) = 1 := by
    rw [Complex.star_def, Complex.mul_conj]
    exact_mod_cast omega_normSq n
  exact mul_left_cancel₀ hne (hmul.trans (mul_inv_cancel₀ hne).symm)

/-- The DFT orthogonality relation (core of the unitarity proof):
    sum_k omega^{j*k} * conj(omega^{j'*k}) = 2^n * delta_{j,j'} -/
lemma dft_orthogonality (n : ℕ) (j j' : Fin (2 ^ n)) :
    ∑ k : Fin (2 ^ n), (omega n) ^ (j.val * k.val) * star ((omega n) ^ (j'.val * k.val)) =
    if j = j' then (2 ^ n : ℂ) else 0 := by
  have hωne : omega n ≠ 0 := Complex.exp_ne_zero _
  -- star(ω^m) = (ω⁻¹)^m
  have hstar_pow : ∀ m : ℕ, star ((omega n) ^ m) = (omega n)⁻¹ ^ m := by
    intro m; rw [star_pow, omega_star]
  simp_rw [hstar_pow]
  split_ifs with heq
  · -- Diagonal: each term is (ω * ω⁻¹)^{jk} = 1
    subst heq
    simp_rw [← mul_pow, mul_inv_cancel₀ hωne, one_pow,
             Finset.sum_const, Finset.card_univ, Fintype.card_fin]
    norm_num
  · -- Off-diagonal: geometric series with ratio r = ω^j * (ω⁻¹)^{j'}, r ≠ 1
    set r : ℂ := (omega n) ^ j.val * (omega n)⁻¹ ^ j'.val with hr_def
    have hterm : ∀ k : Fin (2 ^ n),
        (omega n) ^ (j.val * k.val) * (omega n)⁻¹ ^ (j'.val * k.val) = r ^ k.val := by
      intro k; simp only [hr_def, pow_mul, ← mul_pow]
    simp_rw [hterm]
    -- r^{2^n} = 1
    have hr_pow : r ^ (2 ^ n) = 1 := by
      have h1 : ((omega n) ^ j.val) ^ (2 ^ n) = 1 := by
        rw [← pow_mul, mul_comm, pow_mul, omega_pow_two_pow, one_pow]
      have h2 : ((omega n)⁻¹ ^ j'.val) ^ (2 ^ n) = 1 := by
        rw [← pow_mul, mul_comm, pow_mul, inv_pow, omega_pow_two_pow, inv_one, one_pow]
      simp only [hr_def, mul_pow]; rw [h1, h2, mul_one]
    -- r ≠ 1 by primitivity of omega and j ≠ j'
    have hr_ne : r ≠ 1 := by
      intro hr_eq
      apply heq
      have hprim : IsPrimitiveRoot (omega n) (2 ^ n) := by
        have h := Complex.isPrimitiveRoot_exp (2 ^ n) ((Nat.two_pow_pos n).ne')
        simp only [omega]; convert h using 1; congr 1; push_cast; ring
      -- r = 1 → ω^{j-j'} = 1 in zpow
      have hd : (omega n) ^ ((j.val : ℤ) - j'.val) = 1 := by
        simp only [hr_def, inv_pow] at hr_eq
        rw [zpow_sub₀ hωne, zpow_natCast, zpow_natCast, div_eq_mul_inv]
        exact hr_eq
      have hdvd := (hprim.zpow_eq_one_iff_dvd ((j.val : ℤ) - j'.val)).mp hd
      have hbound : |(j.val : ℤ) - j'.val| < (2 ^ n : ℤ) := by
        have hj : (j.val : ℤ) < 2 ^ n := by exact_mod_cast j.is_lt
        have hj' : (j'.val : ℤ) < 2 ^ n := by exact_mod_cast j'.is_lt
        rw [abs_lt]; constructor
        · linarith [Int.natCast_nonneg j'.val]
        · linarith [Int.natCast_nonneg j.val]
      have hzero := Int.eq_zero_of_abs_lt_dvd hdvd hbound
      exact Fin.ext (by exact_mod_cast sub_eq_zero.mp hzero)
    -- Geometric series = 0
    have hgeo : ∑ i ∈ Finset.range (2 ^ n), r ^ i = 0 := by
      have hmul := geom_sum_mul r (2 ^ n)
      rw [hr_pow, sub_self] at hmul
      exact (mul_eq_zero.mp hmul).resolve_right (sub_ne_zero.mpr hr_ne)
    rw [Fin.sum_univ_eq_sum_range (fun i => r ^ i) (2 ^ n)]
    exact hgeo

/-- The QFT matrix is unitary. -/
lemma qftMatrix_isUnitary (n : ℕ) : qftMatrix n ∈ Matrix.unitaryGroup (Fin (2 ^ n)) ℂ := by
  rw [Matrix.mem_unitaryGroup_iff]
  have hN_pos : (0 : ℝ) < 2 ^ n := by positivity
  have hsqN_sq : (Real.sqrt (2 ^ n : ℝ) : ℂ) ^ 2 = (2 ^ n : ℂ) := by
    exact_mod_cast Real.sq_sqrt hN_pos.le
  have hN_ne : (2 ^ n : ℂ) ≠ 0 := by exact_mod_cast (Nat.two_pow_pos n).ne'
  have hreal : star ((Real.sqrt (2 ^ n : ℝ) : ℂ)) = (Real.sqrt (2 ^ n : ℝ) : ℂ) :=
    Complex.conj_ofReal _
  have hstar_inv_sqrt : star (1 / (Real.sqrt (2 ^ n : ℝ) : ℂ)) =
      (1 / (Real.sqrt (2 ^ n : ℝ) : ℂ)) := by
    rw [one_div, star_inv₀, hreal]
  have h1N : (1 / (Real.sqrt (2 ^ n : ℝ) : ℂ)) * (1 / (Real.sqrt (2 ^ n : ℝ) : ℂ)) =
             1 / (2 ^ n : ℂ) := by
    rw [div_mul_div_comm, one_mul, ← sq, hsqN_sq]
  ext j j'
  simp only [Matrix.mul_apply, Matrix.star_apply, qftMatrix]
  -- Factor: (1/√N · ω^(j·k)) * star(1/√N · ω^(j'·k)) = (1/N) · (ω^(j·k) * star(ω^(j'·k)))
  have hterm : ∀ k : Fin (2 ^ n),
      ((1 / (Real.sqrt (2 ^ n : ℝ) : ℂ)) * (omega n) ^ (j.val * k.val)) *
        star ((1 / (Real.sqrt (2 ^ n : ℝ) : ℂ)) * (omega n) ^ (j'.val * k.val)) =
      (1 / (2 ^ n : ℂ)) *
        ((omega n) ^ (j.val * k.val) * star ((omega n) ^ (j'.val * k.val))) := by
    intro k
    calc
      ((1 / (Real.sqrt (2 ^ n : ℝ) : ℂ)) * (omega n) ^ (j.val * k.val)) *
          star ((1 / (Real.sqrt (2 ^ n : ℝ) : ℂ)) * (omega n) ^ (j'.val * k.val)) =
          ((1 / (Real.sqrt (2 ^ n : ℝ) : ℂ)) * (omega n) ^ (j.val * k.val)) *
            (star (1 / (Real.sqrt (2 ^ n : ℝ) : ℂ)) * star ((omega n) ^ (j'.val * k.val))) := by
            rw [star_mul']
      _ = ((1 / (Real.sqrt (2 ^ n : ℝ) : ℂ)) * (1 / (Real.sqrt (2 ^ n : ℝ) : ℂ))) *
            ((omega n) ^ (j.val * k.val) * star ((omega n) ^ (j'.val * k.val))) := by
            rw [hstar_inv_sqrt]
            ring
      _ = (1 / (2 ^ n : ℂ)) *
            ((omega n) ^ (j.val * k.val) * star ((omega n) ^ (j'.val * k.val))) := by
            rw [h1N]
  calc
    ∑ k : Fin (2 ^ n),
        ((1 / (Real.sqrt (2 ^ n : ℝ) : ℂ)) * (omega n) ^ (j.val * k.val)) *
          star ((1 / (Real.sqrt (2 ^ n : ℝ) : ℂ)) * (omega n) ^ (j'.val * k.val)) =
        ∑ k : Fin (2 ^ n),
          (1 / (2 ^ n : ℂ)) *
            ((omega n) ^ (j.val * k.val) * star ((omega n) ^ (j'.val * k.val))) := by
          apply Finset.sum_congr rfl
          intro k hk
          exact hterm k
    _ = (1 / (2 ^ n : ℂ)) *
          ∑ k : Fin (2 ^ n),
            ((omega n) ^ (j.val * k.val) * star ((omega n) ^ (j'.val * k.val))) := by
          rw [← Finset.mul_sum]
    _ = (1 / (2 ^ n : ℂ)) * (if j = j' then (2 ^ n : ℂ) else 0) := by
          rw [dft_orthogonality n j j']
  rw [Matrix.one_apply]
  split_ifs with h
  · simp [one_div, hN_ne]
  · simp

/-- Package the QFT matrix as a gate. -/
noncomputable def qftGate (n : ℕ) : QGate n :=
  ⟨qftMatrix n, qftMatrix_isUnitary n⟩

/-! ## The QFT circuit -/

/-- The QFT circuit on 1 qubit is just the Hadamard gate. -/
noncomputable def qftCircuit1 : Circuit 1 := singleGate hadamard

/-- Correctness of QFT on 1 qubit: H = QFT_2.
    Entry-wise: H[i,j] = (1/sqrt 2) * (-1)^{ij} = (1/sqrt 2) * omega^{ij} for omega = exp(pi*i). -/
theorem qft1_correct : qftCircuit1.CorrectFor (qftMatrix 1) (qftMatrix_isUnitary 1) := by
  change (circuitMatrix qftCircuit1 : Matrix (Fin 2) (Fin 2) ℂ) = qftMatrix 1
  ext i j
  fin_cases i <;> fin_cases j
  · simp [qftCircuit1, circuitMatrix, singleGate, qftMatrix, omega, hadamard, hadamardMatrix]
  · simp [qftCircuit1, circuitMatrix, singleGate, qftMatrix, omega, hadamard, hadamardMatrix]
  · simp [qftCircuit1, circuitMatrix, singleGate, qftMatrix, omega, hadamard, hadamardMatrix]
  · have hω : omega 1 = (-1 : ℂ) := by
      unfold omega
      have hpow : (2 ^ 1 : ℂ) = 2 := by norm_num
      have htwo : (2 : ℂ) ≠ 0 := by norm_num
      have harg : 2 * (Real.pi : ℂ) * Complex.I / (2 ^ 1 : ℂ) = (Real.pi : ℂ) * Complex.I := by
        rw [hpow]
        field_simp [htwo]
      rw [harg, Complex.exp_pi_mul_I]
    simp [qftCircuit1, circuitMatrix, singleGate, qftMatrix, hadamard, hadamardMatrix, hω]

/-- The QFT circuit on n qubits (general construction).

    For each qubit m = 0, ..., n-1:
      - Apply H to qubit m
      - Apply controlled-R_{j+1} for j = 1, ..., n-1-m
    Then apply the bit-reversal permutation (SWAP cascade). -/
private noncomputable def qftControlledLayer (n : ℕ) (target : Fin n) : Circuit n :=
  (List.finRange (n - (target.val + 1))).map fun offset =>
    let control : Fin n := ⟨target.val + offset.val + 1, by
      have hoff : offset.val < n - (target.val + 1) := offset.is_lt
      omega⟩
    let hct : control ≠ target := by
      have hgt : target.val < control.val := by
        have hoff : offset.val < n - (target.val + 1) := offset.is_lt
        dsimp [control]
        omega
      intro hEq
      have : control.val = target.val := congrArg Fin.val hEq
      omega
    ⟨controlledPhaseAt control target hct (offset.val + 2)⟩

private noncomputable def qftQubitLayer (n : ℕ) (target : Fin n) : Circuit n :=
  [⟨hadamardAt target⟩] ++ qftControlledLayer n target

noncomputable def qftCircuit (n : ℕ) : Circuit n :=
  (List.finRange n).foldr (fun target acc => qftQubitLayer n target ++ acc) [⟨bitReverse⟩]

/-! ## Infrastructure for the general correctness proof -/

/-- The canonical reindexing used to view `Fin 2 × Fin (2^n)` as `Fin (2^(n+1))`. -/
private def liftEquiv (n : ℕ) : Fin 2 × Fin (2 ^ n) ≃ Fin (2 ^ (n + 1)) :=
  finProdFinEquiv.trans <|
    finCongr (show 2 * 2 ^ n = 2 ^ (n + 1) by rw [pow_succ, Nat.mul_comm])

/-- Lift an `n`-qubit gate to the suffix qubits of an `(n+1)`-qubit register. -/
private noncomputable def liftGate {n : ℕ} (U : QGate n) : QGate (n + 1) := by
  refine ⟨
    Matrix.reindex (liftEquiv n) (liftEquiv n)
      (((1 : Matrix (Fin 2) (Fin 2) ℂ) ⊗ₖ (U : Matrix (Fin (2 ^ n)) (Fin (2 ^ n)) ℂ))),
    ?_⟩
  have hI : (1 : Matrix (Fin 2) (Fin 2) ℂ) ∈ Matrix.unitaryGroup (Fin 2) ℂ :=
    SetLike.coe_mem (1 : QGate 1)
  exact reindex_mem_unitaryGroup (liftEquiv n) <|
    Matrix.kronecker_mem_unitary hI (SetLike.coe_mem U)

/-- Lift every step of a circuit to the suffix qubits of an `(n+1)`-qubit register. -/
private noncomputable def liftCircuit {n : ℕ} (c : Circuit n) : Circuit (n + 1) :=
  c.map fun s => ⟨liftGate s.unitary⟩

/-- The underlying matrix of `liftGate` is the reindexed Kronecker product `I₂ ⊗ U`. -/
@[simp]
private lemma liftGate_coe {n : ℕ} (U : QGate n) :
    ((liftGate U : QGate (n + 1)) : Matrix (Fin (2 ^ (n + 1))) (Fin (2 ^ (n + 1))) ℂ) =
      Matrix.reindex (liftEquiv n) (liftEquiv n)
        (((1 : Matrix (Fin 2) (Fin 2) ℂ) ⊗ₖ (U : Matrix (Fin (2 ^ n)) (Fin (2 ^ n)) ℂ))) := rfl

/-- Lifting preserves multiplication: `I ⊗ (U * V) = (I ⊗ U) * (I ⊗ V)`. -/
private lemma liftGate_mul {n : ℕ} (U V : QGate n) :
    liftGate (U * V) = liftGate U * liftGate V := by
  apply Subtype.ext
  show ((liftGate (U * V) : QGate (n + 1)) :
      Matrix (Fin (2 ^ (n + 1))) (Fin (2 ^ (n + 1))) ℂ) =
    (((liftGate U : QGate (n + 1)) :
      Matrix (Fin (2 ^ (n + 1))) (Fin (2 ^ (n + 1))) ℂ) *
      ((liftGate V : QGate (n + 1)) :
        Matrix (Fin (2 ^ (n + 1))) (Fin (2 ^ (n + 1))) ℂ))
  have hkr :
      ((1 : Matrix (Fin 2) (Fin 2) ℂ) ⊗ₖ ((U * V : QGate n) :
        Matrix (Fin (2 ^ n)) (Fin (2 ^ n)) ℂ)) =
      (((1 : Matrix (Fin 2) (Fin 2) ℂ) ⊗ₖ (U : Matrix (Fin (2 ^ n)) (Fin (2 ^ n)) ℂ)) *
        ((1 : Matrix (Fin 2) (Fin 2) ℂ) ⊗ₖ (V : Matrix (Fin (2 ^ n)) (Fin (2 ^ n)) ℂ))) := by
    simpa using
      (Matrix.mul_kronecker_mul
        (1 : Matrix (Fin 2) (Fin 2) ℂ)
        (1 : Matrix (Fin 2) (Fin 2) ℂ)
        (U : Matrix (Fin (2 ^ n)) (Fin (2 ^ n)) ℂ)
        (V : Matrix (Fin (2 ^ n)) (Fin (2 ^ n)) ℂ))
  rw [liftGate_coe, liftGate_coe, liftGate_coe,
    ← Matrix.reindexAlgEquiv_apply (R := ℂ) (A := ℂ),
    ← Matrix.reindexAlgEquiv_apply (R := ℂ) (A := ℂ),
    ← Matrix.reindexAlgEquiv_apply (R := ℂ) (A := ℂ), hkr,
    Matrix.reindexAlgEquiv_mul (R := ℂ) (A := ℂ)]

/-- Lifting preserves the identity gate. -/
@[simp]
private lemma liftGate_one {n : ℕ} : liftGate (1 : QGate n) = 1 := by
  apply Subtype.ext
  show ((liftGate (1 : QGate n) : QGate (n + 1)) :
      Matrix (Fin (2 ^ (n + 1))) (Fin (2 ^ (n + 1))) ℂ) =
    (1 : Matrix (Fin (2 ^ (n + 1))) (Fin (2 ^ (n + 1))) ℂ)
  rw [liftGate_coe, ← Matrix.reindexAlgEquiv_apply (R := ℂ) (A := ℂ)]
  simp

/-- The matrix of a lifted circuit is the lifted matrix of the original circuit. -/
private lemma circuitMatrix_liftCircuit {n : ℕ} (c : Circuit n) :
    circuitMatrix (liftCircuit c) = liftGate (circuitMatrix c) := by
  induction c with
  | nil =>
      simp [liftCircuit]
  | cons s c ih =>
      rw [show liftCircuit (s :: c) = [⟨liftGate s.unitary⟩] ++ liftCircuit c by rfl,
        circuitMatrix_append, circuitMatrix_singleton, ih]
      rw [show circuitMatrix (s :: c) = circuitMatrix c * s.unitary by
        simpa using (circuitMatrix_append [s] c)]
      rw [← liftGate_mul]

/-- Embed a leading qubit bit `b` and an `n`-qubit suffix index `i` into `Fin (2^(n+1))`
    as `b * 2^n + i`. This matches the input-side decomposition used in the recursive QFT proof. -/
private def msbIndex (n : ℕ) (b : Fin 2) (i : Fin (2 ^ n)) : Fin (2 ^ (n + 1)) := by
  refine ⟨i.val + 2 ^ n * b.val, ?_⟩
  fin_cases b <;> simp [pow_succ] <;> omega

/-- Embed an `n`-qubit prefix index `i` and a trailing bit `b` into `Fin (2^(n+1))`
    as `b + 2 * i`. This matches the output-side decomposition after bit-reversal. -/
private def lsbIndex (n : ℕ) (i : Fin (2 ^ n)) (b : Fin 2) : Fin (2 ^ (n + 1)) := by
  refine ⟨b.val + 2 * i.val, ?_⟩
  fin_cases b <;> simp [pow_succ] <;> omega

/-- Arithmetic split for the exponent appearing in the `(n+1)`-qubit DFT entry
    with `j = b * 2^n + i` and `k = c + 2 * i'`. -/
private lemma msbIndex_mul_lsbIndex (n : ℕ) (b c : Fin 2)
    (i i' : Fin (2 ^ n)) :
    (msbIndex n b i).val * (lsbIndex n i' c).val =
      b.val * c.val * 2 ^ n + i.val * c.val + 2 * (i.val * i'.val) +
        2 ^ (n + 1) * (b.val * i'.val) := by
  fin_cases b <;> fin_cases c <;> simp [msbIndex, lsbIndex, pow_succ] <;> ring

/-- ω_{n+1}² = ω_n: squaring the root doubles the angle, stepping down one qubit. -/
lemma omega_sq_pred (n : ℕ) : (omega (n + 1)) ^ 2 = omega n := by
  simp only [omega, ← Complex.exp_nat_mul]
  congr 1
  have h2n : (2 : ℂ) ^ n ≠ 0 := pow_ne_zero n (by norm_num)
  push_cast
  have h2n1 : (2 : ℂ) ^ (n + 1) = 2 * (2 : ℂ) ^ n := by ring
  rw [h2n1]
  field_simp [h2n]

/-- Entrywise factorization of the DFT matrix at size `2^(n+1)`.

    The last term in the exponent contributes a full multiple of `2^(n+1)`, so it vanishes
    against `omega_pow_two_pow (n + 1)`. The remaining third factor is the `n`-qubit DFT term,
    expressed using `omega_sq_pred`. -/
private lemma dftMatrix_succ_entry (n : ℕ) (b c : Fin 2)
    (i i' : Fin (2 ^ n)) :
    dftMatrix (n + 1) (msbIndex n b i) (lsbIndex n i' c) =
      (omega (n + 1)) ^ (b.val * c.val * 2 ^ n) *
        (omega (n + 1)) ^ (i.val * c.val) *
        dftMatrix n i i' := by
  rw [dftMatrix, msbIndex_mul_lsbIndex, pow_add, pow_add, pow_add]
  have hfull :
      (omega (n + 1)) ^ (2 ^ (n + 1) * (b.val * i'.val)) =
        ((omega (n + 1)) ^ (2 ^ (n + 1))) ^ (b.val * i'.val) := by
    rw [pow_mul]
  rw [hfull, omega_pow_two_pow]
  simp only [one_pow, mul_assoc]
  have hrec :
      (omega (n + 1)) ^ (2 * (i.val * i'.val)) =
        ((omega (n + 1)) ^ 2) ^ (i.val * i'.val) := by
    rw [pow_mul]
  rw [hrec, dftMatrix, omega_sq_pred]
  simp

/-- The QFT matrix on 0 qubits is the 1×1 identity. -/
@[simp]
lemma qftMatrix_zero : (qftMatrix 0 : Matrix (Fin 1) (Fin 1) ℂ) = 1 := by
  ext j k; fin_cases j; fin_cases k
  simp [qftMatrix, Real.sqrt_one]

/-- qftCircuit 0 is just [bitReverse]. -/
@[simp]
lemma qftCircuit_zero : qftCircuit 0 = [⟨(bitReverse : QGate 0)⟩] := by
  simp [qftCircuit, List.finRange]

/-- The coercion of permuteQubits to a plain matrix gives the permutation matrix.
    Definitionally true from the `refine ⟨..., ?_⟩` construction of permuteQubits. -/
private lemma permuteQubits_coe {n : ℕ} (σ : Equiv.Perm (Fin n)) :
    (permuteQubits σ : Matrix (Fin (2 ^ n)) (Fin (2 ^ n)) ℂ) = (qubitPerm σ).permMatrix ℂ := rfl

/-- On a 0-qubit system (state space Fin 1), any permutation of the 1-element state space is
    trivial: both qubitPerm σ and the identity send the unique element to itself. -/
private lemma qubitPerm_zero (σ : Equiv.Perm (Fin 0)) :
    (qubitPerm σ : Equiv.Perm (Fin (2 ^ 0))) = 1 := by
  ext x
  fin_cases x
  rfl

/-- Qubit permutations preserve the identity permutation definitionally. -/
private lemma qubitPerm_refl (n : ℕ) :
    (qubitPerm (Equiv.refl (Fin n)) : Equiv.Perm (Fin (2 ^ n))) = 1 := by
  ext x
  simp [qubitPerm]

/-- Fin.revPerm on a 1-element type is the identity permutation. -/
private lemma Fin_revPerm_one : (Fin.revPerm : Equiv.Perm (Fin 1)) = Equiv.refl _ := by
  ext x; fin_cases x
  simp [Fin.revPerm, Fin.rev]

/-- On a 1-qubit system (state space Fin 2), the qubit-reversal permutation is trivial
    because there is only one qubit to reverse (Fin.revPerm on Fin 1 is the identity). -/
private lemma qubitPerm_revPerm_one :
    (qubitPerm (Fin.revPerm : Equiv.Perm (Fin 1)) : Equiv.Perm (Fin (2 ^ 1))) = 1 := by
  rw [Fin_revPerm_one]
  exact qubitPerm_refl 1

/-- bitReverse on 0 qubits is the identity gate. The proof uses that the unique
    qubit permutation on the 1-element state space is trivial. -/
lemma bitReverse_zero : (bitReverse : QGate 0) = 1 := by
  apply Subtype.ext
  show (qubitPerm (Fin.revPerm : Equiv.Perm (Fin 0))).permMatrix ℂ =
       (1 : Matrix (Fin (2 ^ 0)) (Fin (2 ^ 0)) ℂ)
  rw [qubitPerm_zero]; simp

/-- bitReverse on 1 qubit is the identity gate (only one qubit to reverse). -/
lemma bitReverse_one : (bitReverse : QGate 1) = 1 := by
  apply Subtype.ext
  show (qubitPerm (Fin.revPerm : Equiv.Perm (Fin 1))).permMatrix ℂ =
       (1 : Matrix (Fin (2 ^ 1)) (Fin (2 ^ 1)) ℂ)
  rw [qubitPerm_revPerm_one]; simp

/-- qft_correct for the base case n = 0. -/
theorem qft_correct_zero :
    (qftCircuit 0).CorrectFor (qftMatrix 0) (qftMatrix_isUnitary 0) := by
  show (circuitMatrix (qftCircuit 0) : Matrix (Fin (2 ^ 0)) (Fin (2 ^ 0)) ℂ) = qftMatrix 0
  simp only [qftCircuit_zero, circuitMatrix_singleton]
  simp [bitReverse_zero, qftMatrix_zero]

/-- Inductive step: if the n-qubit QFT circuit is correct, so is the (n+1)-qubit circuit.

    The proof proceeds by:
    1. Decompose `qftCircuit (n+1)` into:
       - the first layer on qubit `0`,
       - an embedding of `qftCircuit n` on the suffix qubits `1..n`,
       - one final swap moving qubit `0` to the end.
    2. Transport the induction hypothesis through that suffix embedding.
    3. Compute the matrix contributions of:
       - `hadamardAt 0`,
       - the controlled-phase stack targeting qubit `0`,
       - the final swap.
    4. Verify the resulting matrix product equals `qftMatrix (n+1)` entry-by-entry on the split
       indices `msbIndex n b i` and `lsbIndex n i' c`.

    The DFT-side factorization needed for the last step is already provided by
    `dftMatrix_succ_entry`. The missing work is entirely on the circuit-semantics side; see
    `notes/qft-general-proof-obligations.md` for the exact helper lemmas to prove. -/
private lemma qftCircuit_succ_matrix (n : ℕ)
    (ih : (circuitMatrix (qftCircuit n) : Matrix (Fin (2 ^ n)) (Fin (2 ^ n)) ℂ) = qftMatrix n) :
    (circuitMatrix (qftCircuit (n + 1)) : Matrix (Fin (2 ^ (n + 1))) (Fin (2 ^ (n + 1))) ℂ) =
    qftMatrix (n + 1) := by
  sorry

/-- Main correctness theorem: the QFT circuit implements the QFT unitary.

    Proved by induction on n: the base case (n = 0) is qft_correct_zero, and the
    inductive step is qftCircuit_succ_matrix (currently deferred). -/
theorem qft_correct (n : ℕ) :
    qftCircuit n |>.CorrectFor (qftMatrix n) (qftMatrix_isUnitary n) := by
  induction n with
  | zero => exact qft_correct_zero
  | succ n ih =>
    unfold Circuit.CorrectFor at *
    exact qftCircuit_succ_matrix n ih

/-! ## Small cases -/

/-- On two qubits, the QFT root of unity is `i`. -/
lemma omega_two : omega 2 = Complex.I := by
  unfold omega
  have hpow : (2 ^ 2 : ℂ) = 4 := by norm_num
  have hfour : (4 : ℂ) ≠ 0 := by norm_num
  have harg : 2 * (Real.pi : ℂ) * Complex.I / (2 ^ 2 : ℂ) =
      ((Real.pi : ℂ) / 2) * Complex.I := by
    rw [hpow]
    field_simp [hfour]
    ring
  rw [harg, Complex.exp_pi_div_two_mul_I]

/-- The 2-qubit QFT circuit has the textbook gate sequence
    `H₀ ; CR₂(1→0) ; H₁ ; bitReverse`. -/
lemma qftCircuit_two :
    qftCircuit 2 =
      [⟨hadamardAt 0⟩,
       ⟨controlledPhaseAt 1 0 (by decide) 2⟩,
       ⟨hadamardAt 1⟩,
       ⟨bitReverse⟩] := by
  simp [qftCircuit, qftQubitLayer, qftControlledLayer, List.finRange]

/-- The QFT normalization factor at `n = 2` is `1/2`. -/
private lemma qft_two_scale :
    (1 / (Real.sqrt (2 ^ 2 : ℝ) : ℂ)) = (1 / 2 : ℂ) := by
  have hsqrtR : Real.sqrt (2 ^ 2 : ℝ) = 2 := by
    rw [show (2 ^ 2 : ℝ) = (2 : ℝ) ^ 2 by norm_num]
    exact Real.sqrt_sq (by positivity)
  have hsqrt : (Real.sqrt (2 ^ 2 : ℝ) : ℂ) = 2 := by
    exact_mod_cast hsqrtR
  rw [hsqrt]

/-- The 2-qubit QFT target matrix is the normalized 4-point DFT matrix. -/
lemma qftMatrix_two :
    qftMatrix 2 =
      !![(1 / 2 : ℂ), (1 / 2 : ℂ), (1 / 2 : ℂ), (1 / 2 : ℂ);
         (1 / 2 : ℂ), Complex.I / 2, -(1 / 2 : ℂ), -(Complex.I / 2);
         (1 / 2 : ℂ), -(1 / 2 : ℂ), (1 / 2 : ℂ), -(1 / 2 : ℂ);
         (1 / 2 : ℂ), -(Complex.I / 2), -(1 / 2 : ℂ), Complex.I / 2] := by
  ext i j
  fin_cases i <;> fin_cases j <;>
    simp [qftMatrix, omega_two, Complex.I_pow_eq_pow_mod]
  all_goals
    try simp [Complex.I_sq, Complex.I_pow_three]
    try ring_nf

/-- The QFT on 2 qubits: (H tensor I), CR_2, (I tensor H), SWAP.
    Matrix identity: SWAP * (I tensor H) * CR_2 * (H tensor I) = QFT_4. -/
noncomputable def qftCircuit2 : Circuit 2 :=
  qftCircuit 2

theorem qft2_correct :
    qftCircuit2.CorrectFor (qftMatrix 2) (qftMatrix_isUnitary 2) := by
  sorry

end AutoQuantum.QFT
