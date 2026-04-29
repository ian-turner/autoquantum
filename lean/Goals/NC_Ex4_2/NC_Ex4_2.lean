import Mathlib.Analysis.Normed.Algebra.MatrixExponential
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Series

open Complex NormedSpace
open scoped Matrix

section NCEx42

variable {n : ℕ}


/-- Nielsen & Chuang exercise 4.2: if `A^2 = I`, then `exp(i x A) = cos x • I + i sin x • A`. -/
theorem nc_ex4_2_goal (n : ℕ) (A : Matrix (Fin n) (Fin n) ℂ) (hA : A ^ 2 = 1) (x : ℝ) :
    exp (((x : ℂ) * Complex.I) • A) =
      (Real.cos x : ℂ) • (1 : Matrix (Fin n) (Fin n) ℂ) + (Real.sin x * Complex.I) • A := by
  sorry

end NCEx42
