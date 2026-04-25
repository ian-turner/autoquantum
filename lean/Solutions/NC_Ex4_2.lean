import Mathlib.Analysis.Normed.Algebra.MatrixExponential
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Series

open Complex NormedSpace
open scoped Matrix

section NCEx42

variable {n : ℕ}

/-- The even terms of the matrix exponential collapse to the identity when `A^2 = I`. -/
theorem expSeries_even_of_sq_eq_one (A : Matrix (Fin n) (Fin n) ℂ) (hA : A ^ 2 = 1) (z : ℂ)
    (k : ℕ) :
    expSeries ℂ (Matrix (Fin n) (Fin n) ℂ) (2 * k) (fun _ => z • A) =
      (z ^ (2 * k) / ↑(Nat.factorial (2 * k))) • (1 : Matrix (Fin n) (Fin n) ℂ) := by
  rw [expSeries_apply_eq]
  calc
    (((↑(Nat.factorial (2 * k)) : ℂ)⁻¹) • (z • A) ^ (2 * k))
      = (((↑(Nat.factorial (2 * k)) : ℂ)⁻¹) • (z ^ (2 * k) • A ^ (2 * k))) := by
          rw [smul_pow]
    _ = (((↑(Nat.factorial (2 * k)) : ℂ)⁻¹) • (z ^ (2 * k) • (1 : Matrix (Fin n) (Fin n) ℂ))) := by
          congr 2
          calc
            A ^ (2 * k) = (A ^ 2) ^ k := by rw [pow_mul]
            _ = (1 : Matrix (Fin n) (Fin n) ℂ) ^ k := by rw [hA]
            _ = 1 := one_pow k
    _ = (z ^ (2 * k) / ↑(Nat.factorial (2 * k))) • (1 : Matrix (Fin n) (Fin n) ℂ) := by
          rw [smul_smul, div_eq_mul_inv, mul_comm]

/-- The odd terms of the matrix exponential collapse to a scalar multiple of `A` when `A^2 = I`. -/
theorem expSeries_odd_of_sq_eq_one (A : Matrix (Fin n) (Fin n) ℂ) (hA : A ^ 2 = 1) (z : ℂ)
    (k : ℕ) :
    expSeries ℂ (Matrix (Fin n) (Fin n) ℂ) (2 * k + 1) (fun _ => z • A) =
      (z ^ (2 * k + 1) / ↑(Nat.factorial (2 * k + 1))) • A := by
  rw [expSeries_apply_eq]
  calc
    (((↑(Nat.factorial (2 * k + 1)) : ℂ)⁻¹) • (z • A) ^ (2 * k + 1))
      = (((↑(Nat.factorial (2 * k + 1)) : ℂ)⁻¹) • (z ^ (2 * k + 1) • A ^ (2 * k + 1))) := by
          rw [smul_pow]
    _ = (((↑(Nat.factorial (2 * k + 1)) : ℂ)⁻¹) • (z ^ (2 * k + 1) • A)) := by
          congr 2
          calc
            A ^ (2 * k + 1) = A ^ (2 * k) * A := by rw [pow_succ]
            _ = (A ^ 2) ^ k * A := by rw [pow_mul]
            _ = A := by rw [hA, one_pow, one_mul]
    _ = (z ^ (2 * k + 1) / ↑(Nat.factorial (2 * k + 1))) • A := by
          rw [smul_smul, div_eq_mul_inv, mul_comm]

/-- If `A^2 = I`, then `exp (zA) = cosh z • I + sinh z • A`. -/
theorem hasSum_expSeries_of_sq_eq_one (A : Matrix (Fin n) (Fin n) ℂ) (hA : A ^ 2 = 1) (z : ℂ) :
    HasSum (fun m => expSeries ℂ (Matrix (Fin n) (Fin n) ℂ) m fun _ => z • A)
      (Complex.cosh z • (1 : Matrix (Fin n) (Fin n) ℂ) + Complex.sinh z • A) := by
  refine HasSum.even_add_odd ?_ ?_
  · simpa [expSeries_even_of_sq_eq_one A hA z] using
      (Complex.hasSum_cosh z).smul_const (1 : Matrix (Fin n) (Fin n) ℂ)
  · simpa [expSeries_odd_of_sq_eq_one A hA z] using
      (Complex.hasSum_sinh z).smul_const A

/-- If `A^2 = I`, then `exp (zA) = cosh z • I + sinh z • A`. -/
theorem exp_smul_of_sq_eq_one (A : Matrix (Fin n) (Fin n) ℂ) (hA : A ^ 2 = 1) (z : ℂ) :
    exp (z • A) = Complex.cosh z • (1 : Matrix (Fin n) (Fin n) ℂ) + Complex.sinh z • A := by
  rw [exp_eq_tsum ℂ]
  refine HasSum.tsum_eq ?_
  simpa [expSeries_apply_eq] using hasSum_expSeries_of_sq_eq_one A hA z

/-- Nielsen & Chuang exercise 4.2: if `A^2 = I`, then `exp(i x A) = cos x • I + i sin x • A`. -/
theorem nc_ex4_2_goal (n : ℕ) (A : Matrix (Fin n) (Fin n) ℂ) (hA : A ^ 2 = 1) (x : ℝ) :
    exp (((x : ℂ) * Complex.I) • A) =
      (Real.cos x : ℂ) • (1 : Matrix (Fin n) (Fin n) ℂ) + (Real.sin x * Complex.I) • A := by
  simpa [Complex.cosh_mul_I, Complex.sinh_mul_I] using
    exp_smul_of_sq_eq_one A hA ((x : ℂ) * Complex.I)

end NCEx42
