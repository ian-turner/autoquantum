import AutoQuantum.Core.Gate

open AutoQuantum
open Complex Matrix

private lemma unitary_first_column_norm (U : QGate 1) :
    star ((U : Matrix (Fin 2) (Fin 2) ℂ) 0 0) * ((U : Matrix (Fin 2) (Fin 2) ℂ) 0 0) +
      star ((U : Matrix (Fin 2) (Fin 2) ℂ) 1 0) * ((U : Matrix (Fin 2) (Fin 2) ℂ) 1 0) = 1 := by
  have h := Matrix.UnitaryGroup.star_mul_self U
  have h00 := congr_fun (congr_fun h 0) 0
  simpa [Matrix.mul_apply, Fin.sum_univ_two] using h00

private lemma unitary_first_column_norm_real (U : QGate 1) :
    ‖((U : Matrix (Fin 2) (Fin 2) ℂ) 0 0)‖ ^ 2 +
      ‖((U : Matrix (Fin 2) (Fin 2) ℂ) 1 0)‖ ^ 2 = (1 : ℝ) := by
  have h := unitary_first_column_norm U
  have hc : ((‖((U : Matrix (Fin 2) (Fin 2) ℂ) 0 0)‖ ^ 2 +
      ‖((U : Matrix (Fin 2) (Fin 2) ℂ) 1 0)‖ ^ 2 : ℝ) : ℂ) = 1 := by
    simpa [Complex.conj_mul'] using h
  exact_mod_cast hc

private lemma unitary_first_entry_norm_le_one (U : QGate 1) :
    ‖((U : Matrix (Fin 2) (Fin 2) ℂ) 0 0)‖ ≤ (1 : ℝ) := by
  have hsum := unitary_first_column_norm_real U
  have hnonneg : 0 ≤ ‖((U : Matrix (Fin 2) (Fin 2) ℂ) 1 0)‖ ^ 2 := sq_nonneg _
  have hsq : ‖((U : Matrix (Fin 2) (Fin 2) ℂ) 0 0)‖ ^ 2 ≤ (1 : ℝ) := by
    nlinarith
  have hn : 0 ≤ ‖((U : Matrix (Fin 2) (Fin 2) ℂ) 0 0)‖ := norm_nonneg _
  nlinarith [sq_nonneg (‖((U : Matrix (Fin 2) (Fin 2) ℂ) 0 0)‖ + 1)]

private lemma unitary_det_norm_eq_one (U : QGate 1) :
    ‖((U : Matrix (Fin 2) (Fin 2) ℂ).det)‖ = (1 : ℝ) := by
  exact CStarRing.norm_of_mem_unitary (Matrix.det_of_mem_unitary (SetLike.coe_mem U))

private lemma exp_arg_mul_I_of_norm_eq_one {z : ℂ} (hz : ‖z‖ = (1 : ℝ)) :
    Complex.exp (Complex.I * (Complex.arg z : ℂ)) = z := by
  have h := Complex.norm_mul_exp_arg_mul_I z
  rw [hz] at h
  simpa [one_mul, mul_comm] using h

private lemma polar_exp_mul_norm (z : ℂ) :
    Complex.exp (Complex.I * (Complex.arg z : ℂ)) * (‖z‖ : ℂ) = z := by
  simpa [mul_comm, mul_left_comm, mul_assoc] using Complex.norm_mul_exp_arg_mul_I z

private lemma norm_mul_exp_neg_arg (z : ℂ) :
    (‖z‖ : ℂ) * Complex.exp (-Complex.I * (Complex.arg z : ℂ)) = star z := by
  have hce : star (Complex.exp (Complex.I * (Complex.arg z : ℂ))) =
      Complex.exp (-Complex.I * (Complex.arg z : ℂ)) := by
    simpa [Complex.conj_I, Complex.conj_ofReal] using
      (Complex.exp_conj (Complex.I * (Complex.arg z : ℂ))).symm
  calc
    (‖z‖ : ℂ) * Complex.exp (-Complex.I * (Complex.arg z : ℂ))
        = star (Complex.exp (Complex.I * (Complex.arg z : ℂ)) * (‖z‖ : ℂ)) := by
          simp [hce, mul_comm]
    _ = star z := by rw [polar_exp_mul_norm]

private lemma cos_arccos_first_entry_norm (U : QGate 1) :
    Real.cos (Real.arccos ‖((U : Matrix (Fin 2) (Fin 2) ℂ) 0 0)‖) =
      ‖((U : Matrix (Fin 2) (Fin 2) ℂ) 0 0)‖ := by
  exact Real.cos_arccos (by nlinarith [norm_nonneg ((U : Matrix (Fin 2) (Fin 2) ℂ) 0 0)])
    (unitary_first_entry_norm_le_one U)

private lemma sin_arccos_first_entry_norm (U : QGate 1) :
    Real.sin (Real.arccos ‖((U : Matrix (Fin 2) (Fin 2) ℂ) 0 0)‖) =
      ‖((U : Matrix (Fin 2) (Fin 2) ℂ) 1 0)‖ := by
  rw [Real.sin_arccos]
  have hsum := unitary_first_column_norm_real U
  have hrad : 1 - ‖((U : Matrix (Fin 2) (Fin 2) ℂ) 0 0)‖ ^ 2 =
      ‖((U : Matrix (Fin 2) (Fin 2) ℂ) 1 0)‖ ^ 2 := by
    nlinarith
  rw [hrad]
  exact Real.sqrt_sq_eq_abs _ |>.trans (abs_of_nonneg (norm_nonneg _))

private lemma second_column_from_first_aux (a b c d : ℂ)
    (hn : star a * a + star c * c = 1)
    (ho : star a * b + star c * d = 0) :
    b = -((a * d - b * c) * star c) ∧ d = (a * d - b * c) * star a := by
  constructor
  · calc
      b = b * (star a * a + star c * c) := by rw [hn]; ring
      _ = -((a * d - b * c) * star c) := by
        have h1 : star a * b = - star c * d := by
          simpa [eq_neg_iff_add_eq_zero] using ho
        ring_nf at h1 ⊢
        rw [h1]
        ring
  · calc
      d = d * (star a * a + star c * c) := by rw [hn]; ring
      _ = (a * d - b * c) * star a := by
        have h1 : star c * d = - star a * b := by
          simpa [add_comm, eq_neg_iff_add_eq_zero] using ho
        ring_nf at h1 ⊢
        rw [h1]
        ring

private lemma unitary_second_column_from_first (U : QGate 1) :
    ((U : Matrix (Fin 2) (Fin 2) ℂ) 0 1 =
        -(((U : Matrix (Fin 2) (Fin 2) ℂ).det) *
          star ((U : Matrix (Fin 2) (Fin 2) ℂ) 1 0))) ∧
      ((U : Matrix (Fin 2) (Fin 2) ℂ) 1 1 =
        ((U : Matrix (Fin 2) (Fin 2) ℂ).det) *
          star ((U : Matrix (Fin 2) (Fin 2) ℂ) 0 0)) := by
  let M : Matrix (Fin 2) (Fin 2) ℂ := U
  have hn : star (M 0 0) * M 0 0 + star (M 1 0) * M 1 0 = 1 := by
    simpa [M] using unitary_first_column_norm U
  have ho : star (M 0 0) * M 0 1 + star (M 1 0) * M 1 1 = 0 := by
    have h := Matrix.UnitaryGroup.star_mul_self U
    have h01 := congr_fun (congr_fun h 0) 1
    simpa [M, Matrix.mul_apply, Fin.sum_univ_two] using h01
  have haux := second_column_from_first_aux (M 0 0) (M 0 1) (M 1 0) (M 1 1) hn ho
  simpa [M, Matrix.det_fin_two] using haux

private lemma phase00 (p q r : ℝ) (x : ℂ) :
    Complex.exp (Complex.I * ((r / 2 : ℝ) : ℂ)) *
      (Complex.exp (-Complex.I * ((q - p : ℝ) : ℂ) / 2) * x *
        Complex.exp (-Complex.I * ((r - p - q : ℝ) : ℂ) / 2)) =
      Complex.exp (Complex.I * (p : ℂ)) * x := by
  calc
    Complex.exp (Complex.I * ((r / 2 : ℝ) : ℂ)) *
        (Complex.exp (-Complex.I * ((q - p : ℝ) : ℂ) / 2) * x *
          Complex.exp (-Complex.I * ((r - p - q : ℝ) : ℂ) / 2))
        = (Complex.exp (Complex.I * ((r / 2 : ℝ) : ℂ)) *
          Complex.exp (-Complex.I * ((q - p : ℝ) : ℂ) / 2) *
          Complex.exp (-Complex.I * ((r - p - q : ℝ) : ℂ) / 2)) * x := by ring
    _ = Complex.exp (Complex.I * (p : ℂ)) * x := by
      rw [← Complex.exp_add, ← Complex.exp_add]
      congr 1
      apply congrArg Complex.exp
      simp [Complex.ofReal_sub, Complex.ofReal_div]
      ring_nf

private lemma phase10 (p q r : ℝ) (x : ℂ) :
    Complex.exp (Complex.I * ((r / 2 : ℝ) : ℂ)) *
      (Complex.exp (Complex.I * ((q - p : ℝ) : ℂ) / 2) * x *
        Complex.exp (-Complex.I * ((r - p - q : ℝ) : ℂ) / 2)) =
      Complex.exp (Complex.I * (q : ℂ)) * x := by
  calc
    Complex.exp (Complex.I * ((r / 2 : ℝ) : ℂ)) *
        (Complex.exp (Complex.I * ((q - p : ℝ) : ℂ) / 2) * x *
          Complex.exp (-Complex.I * ((r - p - q : ℝ) : ℂ) / 2))
        = (Complex.exp (Complex.I * ((r / 2 : ℝ) : ℂ)) *
          Complex.exp (Complex.I * ((q - p : ℝ) : ℂ) / 2) *
          Complex.exp (-Complex.I * ((r - p - q : ℝ) : ℂ) / 2)) * x := by ring
    _ = Complex.exp (Complex.I * (q : ℂ)) * x := by
      rw [← Complex.exp_add, ← Complex.exp_add]
      congr 1
      apply congrArg Complex.exp
      simp [Complex.ofReal_sub, Complex.ofReal_div]
      ring_nf

private lemma phase01 (p q r : ℝ) (x : ℂ) :
    Complex.exp (Complex.I * ((r / 2 : ℝ) : ℂ)) *
      (Complex.exp (-Complex.I * ((q - p : ℝ) : ℂ) / 2) * x *
        Complex.exp (Complex.I * ((r - p - q : ℝ) : ℂ) / 2)) =
      Complex.exp (Complex.I * ((r - q : ℝ) : ℂ)) * x := by
  calc
    Complex.exp (Complex.I * ((r / 2 : ℝ) : ℂ)) *
        (Complex.exp (-Complex.I * ((q - p : ℝ) : ℂ) / 2) * x *
          Complex.exp (Complex.I * ((r - p - q : ℝ) : ℂ) / 2))
        = (Complex.exp (Complex.I * ((r / 2 : ℝ) : ℂ)) *
          Complex.exp (-Complex.I * ((q - p : ℝ) : ℂ) / 2) *
          Complex.exp (Complex.I * ((r - p - q : ℝ) : ℂ) / 2)) * x := by ring
    _ = Complex.exp (Complex.I * ((r - q : ℝ) : ℂ)) * x := by
      rw [← Complex.exp_add, ← Complex.exp_add]
      congr 1
      apply congrArg Complex.exp
      simp [Complex.ofReal_sub, Complex.ofReal_div]
      ring_nf

private lemma phase11 (p q r : ℝ) (x : ℂ) :
    Complex.exp (Complex.I * ((r / 2 : ℝ) : ℂ)) *
      (Complex.exp (Complex.I * ((q - p : ℝ) : ℂ) / 2) * x *
        Complex.exp (Complex.I * ((r - p - q : ℝ) : ℂ) / 2)) =
      Complex.exp (Complex.I * ((r - p : ℝ) : ℂ)) * x := by
  calc
    Complex.exp (Complex.I * ((r / 2 : ℝ) : ℂ)) *
        (Complex.exp (Complex.I * ((q - p : ℝ) : ℂ) / 2) * x *
          Complex.exp (Complex.I * ((r - p - q : ℝ) : ℂ) / 2))
        = (Complex.exp (Complex.I * ((r / 2 : ℝ) : ℂ)) *
          Complex.exp (Complex.I * ((q - p : ℝ) : ℂ) / 2) *
          Complex.exp (Complex.I * ((r - p - q : ℝ) : ℂ) / 2)) * x := by ring
    _ = Complex.exp (Complex.I * ((r - p : ℝ) : ℂ)) * x := by
      rw [← Complex.exp_add, ← Complex.exp_add]
      congr 1
      apply congrArg Complex.exp
      simp [Complex.ofReal_sub, Complex.ofReal_div]
      ring_nf

private lemma exp_sub_arg_mul (r q : ℝ) (x : ℂ) :
    Complex.exp (Complex.I * ((r - q : ℝ) : ℂ)) * x =
      Complex.exp (Complex.I * (r : ℂ)) *
        (x * Complex.exp (-Complex.I * (q : ℂ))) := by
  calc
    Complex.exp (Complex.I * ((r - q : ℝ) : ℂ)) * x
        = (Complex.exp (Complex.I * (r : ℂ)) *
            Complex.exp (-Complex.I * (q : ℂ))) * x := by
          rw [← Complex.exp_add]
          congr 1
          simp [Complex.ofReal_sub]
          ring_nf
    _ = Complex.exp (Complex.I * (r : ℂ)) *
        (x * Complex.exp (-Complex.I * (q : ℂ))) := by ring

private lemma phase01_star (p q r : ℝ) (x : ℂ) :
    Complex.exp (Complex.I * ((r / 2 : ℝ) : ℂ)) *
      (Complex.exp (-Complex.I * ((q - p : ℝ) : ℂ) / 2) * x *
        Complex.exp (Complex.I * ((r - p - q : ℝ) : ℂ) / 2)) =
      Complex.exp (Complex.I * (r : ℂ)) *
        (x * Complex.exp (-Complex.I * (q : ℂ))) := by
  exact (phase01 p q r x).trans (exp_sub_arg_mul r q x)

private lemma phase11_star (p q r : ℝ) (x : ℂ) :
    Complex.exp (Complex.I * ((r / 2 : ℝ) : ℂ)) *
      (Complex.exp (Complex.I * ((q - p : ℝ) : ℂ) / 2) * x *
        Complex.exp (Complex.I * ((r - p - q : ℝ) : ℂ) / 2)) =
      Complex.exp (Complex.I * (r : ℂ)) *
        (x * Complex.exp (-Complex.I * (p : ℂ))) := by
  exact (phase11 p q r x).trans (exp_sub_arg_mul r p x)

private lemma zyz_matrix_entries (β γ δ : ℝ) :
    ((rz β * ry γ * rz δ : QGate 1) : Matrix (Fin 2) (Fin 2) ℂ) =
      !![Complex.exp (-Complex.I * (β : ℂ) / 2) * (Real.cos (γ / 2) : ℂ) *
            Complex.exp (-Complex.I * (δ : ℂ) / 2),
          Complex.exp (-Complex.I * (β : ℂ) / 2) * (-(Real.sin (γ / 2) : ℂ)) *
            Complex.exp (Complex.I * (δ : ℂ) / 2);
         Complex.exp (Complex.I * (β : ℂ) / 2) * (Real.sin (γ / 2) : ℂ) *
            Complex.exp (-Complex.I * (δ : ℂ) / 2),
          Complex.exp (Complex.I * (β : ℂ) / 2) * (Real.cos (γ / 2) : ℂ) *
            Complex.exp (Complex.I * (δ : ℂ) / 2)] := by
  ext i j
  fin_cases i <;> fin_cases j <;>
    simp [rz, ry, rzMatrix, ryMatrix]

/-- Nielsen and Chuang theorem 4.1: every single-qubit unitary has a `Z-Y-Z`
Euler-angle decomposition, up to a global phase. -/
theorem nc_thm4_1_goal (U : QGate 1) :
    ∃ α β γ δ : ℝ,
      (U : Matrix (Fin 2) (Fin 2) ℂ) =
        Complex.exp (Complex.I * (α : ℂ)) •
          ((rz β * ry γ * rz δ : QGate 1) : Matrix (Fin 2) (Fin 2) ℂ) := by
  classical
  let M : Matrix (Fin 2) (Fin 2) ℂ := U
  let a : ℂ := M 0 0
  let c : ℂ := M 1 0
  let Δ : ℂ := M.det
  -- The standard parametrization is obtained from the polar forms of `a`, `c`,
  -- and `det M`.  If `p = arg a`, `q = arg c`, and `r = arg det M`, then the
  -- Euler angles below solve the four phase equations after expanding
  -- `Rz β * Ry γ * Rz δ` with `zyz_matrix_entries`.
  let α : ℝ := Complex.arg Δ / 2
  let β : ℝ := Complex.arg c - Complex.arg a
  let γ : ℝ := 2 * Real.arccos ‖a‖
  let δ : ℝ := Complex.arg Δ - Complex.arg a - Complex.arg c
  refine ⟨α, β, γ, δ, ?_⟩
  have hcosC : Complex.cos (Real.arccos ‖a‖ : ℂ) = (‖a‖ : ℂ) := by
    simpa [a, M, Complex.ofReal_cos] using
      congrArg (fun x : ℝ => (x : ℂ)) (cos_arccos_first_entry_norm U)
  have hsinC : Complex.sin (Real.arccos ‖a‖ : ℂ) = (‖c‖ : ℂ) := by
    simpa [a, c, M, Complex.ofReal_sin] using
      congrArg (fun x : ℝ => (x : ℂ)) (sin_arccos_first_entry_norm U)
  have ha := polar_exp_mul_norm a
  have hc := polar_exp_mul_norm c
  have hD : Complex.exp (Complex.I * (Complex.arg Δ : ℂ)) = Δ := by
    simpa [Δ, M] using exp_arg_mul_I_of_norm_eq_one (unitary_det_norm_eq_one U)
  have hstar_a := norm_mul_exp_neg_arg a
  have hstar_c := norm_mul_exp_neg_arg c
  have hsecond := unitary_second_column_from_first U
  rw [zyz_matrix_entries β γ δ]
  ext i j
  fin_cases i <;> fin_cases j <;>
    simp [Matrix.smul_apply, α, β, γ, δ, M, a, c, Δ, hcosC, hsinC]
  · simpa [M, a, c, Δ] using
      ((phase00 (Complex.arg a) (Complex.arg c) (Complex.arg Δ) (‖a‖ : ℂ)).trans ha).symm
  · simpa [M, a, c, Δ, hD, hstar_c] using
      hsecond.1.trans (congrArg Neg.neg
        ((phase01_star (Complex.arg a) (Complex.arg c) (Complex.arg Δ) (‖c‖ : ℂ)).trans
          (by rw [hD, hstar_c])).symm)
  · simpa [M, a, c, Δ] using
      ((phase10 (Complex.arg a) (Complex.arg c) (Complex.arg Δ) (‖c‖ : ℂ)).trans hc).symm
  · simpa [M, a, c, Δ, hD, hstar_a] using
      hsecond.2.trans
        ((phase11_star (Complex.arg a) (Complex.arg c) (Complex.arg Δ) (‖a‖ : ℂ)).trans
          (by rw [hD, hstar_a])).symm
