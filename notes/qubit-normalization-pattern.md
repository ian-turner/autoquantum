# Qubit Normalization Pattern

This note records the proof pattern used to discharge the `ketPlus` and `ketMinus` normalization proofs in `lean/AutoQuantum/Qubit.lean`.

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

This should generalize to other symmetric single-qubit superpositions.
