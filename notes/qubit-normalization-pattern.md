# Qubit Normalization Pattern

This note records the proof patterns used to discharge the `ketPlus`, `ketMinus`, and `blochState` proofs in `lean/AutoQuantum/Qubit.lean`.

## Pattern

For a state of the form

```lean
superpose a b ket0.vec ket1.vec
```

prefer reusing `superpose_norm_eq_one` from `Hilbert.lean` rather than expanding the `EuclideanSpace` norm directly. The proof obligations then separate cleanly into:

1. `QState.norm_eq_one ket0` and `QState.norm_eq_one ket1`
2. Orthogonality via `simpa [QState.braket] using ket0_braket_ket1`
3. A scalar coefficient identity `Complex.normSq a + Complex.normSq b = 1`

## Coefficient algebra

For coefficients like `((1 : ℂ) / Real.sqrt 2)`, `field_simp` alone may stop too early. A stable route is:

```lean
have hcoef : Complex.normSq (((1 : ℂ) / Real.sqrt 2)) = 1 / 2 := by
  rw [Complex.normSq_div]
  norm_num [Real.sq_sqrt (show (0 : ℝ) ≤ 2 by positivity)]
nlinarith [hcoef]
```

If one coefficient is negated, as in `ketMinus`, first transport the positive-coefficient fact through `Complex.normSq_neg`:

```lean
have hneg : Complex.normSq (-((1 : ℂ) / Real.sqrt 2)) = 1 / 2 := by
  rw [Complex.normSq_neg]
  exact hcoef
calc
  Complex.normSq (((1 : ℂ) / Real.sqrt 2)) +
      Complex.normSq (-((1 : ℂ) / Real.sqrt 2)) = 1 / 2 + 1 / 2 := by
        rw [hcoef, hneg]
  _ = 1 := by norm_num
```

This also generalizes to Bloch-sphere states if the second coefficient is a unit-modulus phase times a real sine term.

## Unit-modulus phases

For Bloch states, the second coefficient is

```lean
Complex.exp (Complex.I * phi) * Real.sin (theta / 2)
```

Instead of expanding the complex exponential manually, use the built-in norm fact:

```lean
have hphase : Complex.normSq (Complex.exp (Complex.I * phi)) = 1 := by
  rw [Complex.normSq_eq_norm_sq, Complex.norm_exp_I_mul_ofReal]
  norm_num
```

Then the coefficient goal reduces to `cos^2 + sin^2 = 1`, which `nlinarith` can close from `Real.sin_sq_add_cos_sq`.

## Orthogonality and pointwise proofs

For `ketPlus_braket_ketMinus`, the clean proof is a coordinate calculation over `Fin 2`:

```lean
simp [QState.braket, QState.vec, QState.mk, ketPlus, ketMinus, ket0, ket1, basisState,
  superpose, PiLp.inner_apply, Fin.sum_univ_two]
```

For Bloch pole lemmas, `simp` needs both `QState.vec` and `QState.mk` to see through the subtype wrapper around the underlying vector.
