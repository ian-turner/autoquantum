# Matrix Exponential for Involutions

Date: April 25, 2026

## Summary

`lean/Goals/NC_Ex4_2.lean` now proves the standard involution identity for complex matrices:

```lean
exp (z • A) = Complex.cosh z • I + Complex.sinh z • A
```

under the hypothesis `A ^ 2 = 1`, and then specializes it to the Nielsen-Chuang Exercise 4.2 form

```lean
exp (((x : ℂ) * Complex.I) • A) =
  (Real.cos x : ℂ) • I + (Real.sin x * Complex.I) • A
```

for `x : ℝ`.

## Proof Pattern

The proof is easiest through `NormedSpace.expSeries`, not by working directly with `exp_eq_tsum`.

1. Prove an even-term lemma:
   `expSeries ... (2 * k) ... = (z^(2*k) / (2*k)!) • I`
2. Prove an odd-term lemma:
   `expSeries ... (2 * k + 1) ... = (z^(2*k+1) / (2*k+1)!) • A`
3. Combine them with `HasSum.even_add_odd`.
4. Bridge back to `exp` with:
   `simpa [expSeries_apply_eq] using hasSum_expSeries_of_sq_eq_one ...`

This avoids fighting the expanded coefficient shape too early.

## Mathlib Notes

- Matrix exponentials use plain `exp A`, not `exp ℂ A`.
- When writing factorials under a coercion, `↑(Nat.factorial n)` parses reliably; `↑(n!)` can be fragile in larger expressions.
- For the final trigonometric specialization, `Complex.cosh_mul_I` and `Complex.sinh_mul_I` are the right lemmas.

