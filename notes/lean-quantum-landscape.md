# Lean 4 Quantum Computing Landscape

Current state of quantum formalization in Lean 4 / Mathlib, and what AutoQuantum has built on top of it.
Last updated: April 2026 (Mathlib v4.29.0).

---

## What Mathlib Already Provides

### Linear Algebra
- `Matrix (n m : Type) R` — matrices over a ring R
- `Matrix.unitaryGroup n R` — unitary group U(n, R); membership via `Matrix.mem_unitaryGroup_iff`
- `Matrix.IsHermitian` — Hermitian matrices
- `Matrix.IsUnitary` — unitary matrices
- `Matrix.kroneckerMap` / `Matrix.kronecker` — Kronecker (tensor) product
- `Matrix.trace`, `Matrix.det`, `Matrix.rank`
- `Fin.sum_univ_four` — useful for closing sum goals on 4×4 matrices

### Inner Product Spaces
- `InnerProductSpace 𝕜 E` — inner product space over field 𝕜
- `EuclideanSpace 𝕜 ι` — standard finite-dimensional inner product space (`= PiLp 2 (fun _ : ι => 𝕜)`)
- `EuclideanSpace.single i c` — basis vector e_i scaled by c
- `PiLp.norm_single` — norm of a basis vector (replaces deprecated `EuclideanSpace.norm_single`)
- `norm_inner_le_norm` — Cauchy-Schwarz: `‖⟪x, y⟫_𝕜‖ ≤ ‖x‖ * ‖y‖`
- `orthonormalBasis`, `Finset.sum` over basis for decomposition

### Complex Numbers
- `Complex.exp`, `Complex.normSq`, `Complex.abs`
- `Complex.I` — imaginary unit; `Complex.I_sq : Complex.I ^ 2 = -1`
- `Real.sqrt`, `Real.pi`
- `star : ℂ → ℂ` — complex conjugation (use this, not `conj` which can shadow in `open Complex`)
- `Complex.exp_add`, `Complex.exp_mul_I` — Euler's formula and addition

### Useful Imports (confirmed v4.29.0)
- `Mathlib.Analysis.InnerProductSpace.Basic` — inner product spaces
- `Mathlib.Analysis.InnerProductSpace.PiL2` — EuclideanSpace, `EuclideanSpace.single`, `PiLp.norm_single`
- `Mathlib.Analysis.InnerProductSpace.Orthonormal` — `orthonormal_iff_ite`, `Orthonormal`
- `Mathlib.Analysis.Complex.Norm` — `Complex.sq_norm : ‖z‖^2 = normSq z`
- `Mathlib.LinearAlgebra.UnitaryGroup` — unitary group
- `Mathlib.LinearAlgebra.Matrix.Hermitian` — Hermitian matrices
- `Mathlib.Analysis.SpecialFunctions.Complex.Circle` — complex exp on the unit circle
- `Mathlib.Analysis.SpecialFunctions.Exp` — real/complex exponential
- `Mathlib.RingTheory.RootsOfUnity.Basic` — roots of unity

### Imports that do NOT exist in v4.29.0
- `Mathlib.Data.Complex.Exponential` — **removed/moved**; use `Mathlib.Analysis.SpecialFunctions.Exp`
- `Mathlib.Algebra.GeomSum` — **not a valid path**; geometric sum lemmas live under `Mathlib.Algebra.BigOperators` or `Mathlib.RingTheory.RootsOfUnity`

---

## What LeanQuantum Provides (inQWIRE)

- Gate definitions as `Matrix.unitaryGroup (Fin (2^n)) ℂ`
- Pauli gates X, Y, Z and Hadamard H
- Proofs: H²=I, X²=I, Y²=I, Z²=I
- Hermiticity of Pauli and Hadamard gates

**Gaps:** No circuit type, no multi-qubit gates (CNOT, Toffoli), no algorithm proofs.

---

## What Lean-QuantumInfo Provides (Timeroot)

- Quantum states as density matrices and pure states
- Partial trace, tensor products
- Quantum channels
- Various quantum information inequalities

**Gaps:** Less focused on circuit gate sets; more on information-theoretic quantities.

---

## What AutoQuantum Has Built

| Feature | Status | Location |
|---------|--------|----------|
| `QHilbert n` — `EuclideanSpace ℂ (Fin (2^n))` | Done | `Hilbert.lean` |
| `QState n` — unit vector subtype | Done | `Hilbert.lean` |
| `QState.braket` — inner product wrapper | Done | `Hilbert.lean` |
| `basisState_braket` — basis orthonormality | **Done** (c4dcc6b) | `Hilbert.lean` |
| `basisState n k` — computational basis state | Done | `Hilbert.lean` |
| `superpose` — linear combination of vectors | Done | `Hilbert.lean` |
| `superpose_norm_eq_one` — normalization of superposition | **Done** (c4dcc6b) | `Hilbert.lean` |
| `ket0`, `ket1`, `ketPlus`, `ketMinus` | Done | `Qubit.lean` |
| `ketPlus_braket_ketMinus` | Done | `Qubit.lean` |
| Bloch sphere parameterization | Done | `Qubit.lean` |
| `QGate k` — unitary gate type | Done | `Gate.lean` |
| Pauli X, Y, Z gates + unitarity proofs | Done | `Gate.lean` |
| Hadamard gate (unitarity sorry'd) | Partial | `Gate.lean` |
| Phase rotation R_k (unitarity sorry'd) | Partial | `Gate.lean` |
| CNOT gate + unitarity proof | Done | `Gate.lean` |
| SWAP gate + unitarity proof | Done | `Gate.lean` |
| `applyGate` — gate application to state | Deferred | `Gate.lean` |
| `tensorWithId`, `idTensorWith`, `controlled` | Deferred | `Gate.lean` |
| `Circuit n` — list of gate steps | Done | `Circuit.lean` |
| `circuitMatrix` — product of gate matrices | Done | `Circuit.lean` |
| `circuitMatrix_append` — composition lemma | Done | `Circuit.lean` |
| `Circuit.CorrectFor` — correctness predicate | Done | `Circuit.lean` |
| `qftMatrix n` — the QFT unitary | Done | `QFT.lean` |
| `qftMatrix_isUnitary` | Sorry'd | `QFT.lean` |
| `qftCircuit n` — the QFT circuit | Deferred | `QFT.lean` |
| `qft_correct` — main theorem | Deferred | `QFT.lean` |
| Qubit measurement / Born rule | Future | — |

---

## Known Issues and Workarounds

### 1. `EuclideanSpace` vs `Matrix.mulVec`
`EuclideanSpace ℂ (Fin n) = PiLp 2 (fun _ => ℂ)` is a newtype wrapper. `Matrix.mulVec` expects `Fin n → ℂ`, which requires an explicit bridge.

**Status:** `applyGate` body is deferred with `sorry`.

**Solutions to try:**
- `Matrix.toEuclideanLin` — maps a matrix to a `LinearMap` between `EuclideanSpace`s directly (check if available in v4.29)
- `WithLp.equiv 2 (Fin n → ℂ) : PiLp 2 (fun _ => ℂ) ≃ (Fin n → ℂ)` — explicit equivalence

### 2. Naming collision with `inner`
Defining a function called `inner` inside a namespace that also uses `⟪·, ·⟫_𝕜` notation causes shadowing. **Solution:** Use a different name (`braket`) and keep the `@inner 𝕜 E _` form for the definition body.

### 3. `conj` in `open Complex`
`conj` in an `open Complex` context may not resolve to the conjugation function. **Solution:** Use `star` (the general conjugation from the `Star` typeclass). This is what `Matrix.conjTranspose` uses internally.

### 4. `Circuit` must be `abbrev`
`def Circuit (n : ℕ) := List (GateStep n)` does not automatically inherit `List` instances (`++`, `List.induction`). **Solution:** Use `abbrev Circuit (n : ℕ) := List (GateStep n)`.

### 5. `fin_cases` + `simp` on 4×4 matrices
After `fin_cases i <;> fin_cases j`, Lean generates 16 goals with residual `∑` expressions. Adding `Fin.sum_univ_four` to the simp set closes these for 0/1-entry matrices.

### 6. `import` must precede doc comments
Lean 4 requires all `import` statements at the very top of a file, before anything else — including `/-! ... -/` module doc comments. Placing a doc comment first causes "invalid 'import' command" errors on every subsequent import.

### 7. `⟪·, ·⟫_𝕜` notation requires `open scoped InnerProductSpace`
The inner product notation is declared `scoped[InnerProductSpace]` in `Mathlib.Analysis.InnerProductSpace.Defs`. Without opening the scope it is unavailable outside Mathlib's own files. Add this line to any file that uses `⟪·, ·⟫_𝕜`:
```lean
open scoped InnerProductSpace
```
Alternatively, write `@inner ℂ E _ x y` directly (which is how the notation expands).

### 8. `norm_add_sq` requires explicit field `𝕜`
`norm_add_sq (x y : E) : ‖x+y‖^2 = ‖x‖^2 + 2 * re⟪x,y⟫ + ‖y‖^2` has `𝕜` as an implicit argument inferred from `E`. When `E` is a `PiLp`/`EuclideanSpace` type, Lean's elaborator often cannot unify the `InnerProductSpace ?𝕜 E` instance and gets stuck on the `re` metavariable. **Fix:** provide the field explicitly:
```lean
@norm_add_sq ℂ (QHilbert n) _ _ _ x y
```

### 9. Basis orthonormality via `EuclideanSpace.orthonormal_single`
To prove `⟪EuclideanSpace.single j 1, EuclideanSpace.single k 1⟫_ℂ = if j = k then 1 else 0`, the direct route is:
```lean
have h := EuclideanSpace.orthonormal_single (𝕜 := ℂ) (ι := Fin (2^n))
rw [orthonormal_iff_ite] at h
exact h j k
```
`orthonormal_iff_ite` requires `[DecidableEq ι]`; for `Fin n` this is always satisfied automatically.

### 10. `field_simp` stalls on `Complex.normSq ((1 : ℂ) / √2)`
In `Qubit.lean`, the coefficient obligation for `ketPlus` normalization does not fully close with `field_simp`; Lean can stop at a scalar goal like `Complex.normSq (1 / ↑√2) * (1 + 1) = 1`. The robust route is to prove the scalar fact first:
```lean
have hcoef : Complex.normSq (((1 : ℂ) / Real.sqrt 2)) = 1 / 2 := by
  rw [Complex.normSq_div]
  norm_num [Real.sq_sqrt (show (0 : ℝ) ≤ 2 by positivity)]
```
and then finish the sum with `nlinarith`.

### 11. `QState.mk` must often be unfolded in pointwise vector proofs
When a goal mentions `(blochState θ φ).vec` or another state built with `QState.mk`, `fin_cases` plus `simp` may stop at terms like `↑(QState.mk v h)` instead of reducing to `v`. In `Qubit.lean`, the pole lemmas only closed once `QState.vec` and `QState.mk` were both added to the simp set:
```lean
fin_cases i <;> simp [QState.vec, QState.mk, blochState, superpose, ket0, ket1, basisState]
```
For the `|+⟩`/`|-⟩` orthogonality proof, a direct coordinate calculation using `PiLp.inner_apply` and `Fin.sum_univ_two` avoids the same subtype noise.
