# Lean 4 Quantum Computing Landscape

Current state of quantum formalization in Lean 4 / Mathlib, and what AutoQuantum has built on top of it.
Last updated: April 23, 2026 (Mathlib v4.29.0).

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
| `QHilbert n` — `EuclideanSpace ℂ (Fin (2^n))` | Done | `Core/Hilbert.lean` |
| `QState n` — unit vector subtype | Done | `Core/Hilbert.lean` |
| `QState.braket` — inner product wrapper | Done | `Core/Hilbert.lean` |
| `basisState_braket` — basis orthonormality | **Done** (c4dcc6b) | `Core/Hilbert.lean` |
| `basisState n k` — computational basis state | Done | `Core/Hilbert.lean` |
| `superpose` — linear combination of vectors | Done | `Core/Hilbert.lean` |
| `superpose_norm_eq_one` — normalization of superposition | **Done** (c4dcc6b) | `Core/Hilbert.lean` |
| `ket0`, `ket1`, `ketPlus`, `ketMinus` | Done | `Core/Qubit.lean` (lint-cleaned Apr 17, 2026) |
| `ketPlus_braket_ketMinus` | Done | `Core/Qubit.lean` |
| Bloch sphere parameterization | Done | `Core/Qubit.lean` |
| `QGate k` — unitary gate type | Done | `Core/Gate.lean` |
| Pauli X, Y, Z gates + unitarity proofs | Done | `Core/Gate.lean` (lint-cleaned Apr 17, 2026) |
| Hadamard gate + unitarity proof | Done | `Core/Gate.lean` |
| Phase rotation R_k + unitarity proof | Done | `Core/Gate.lean` |
| CNOT gate + unitarity proof | Done | `Core/Gate.lean` (lint-cleaned Apr 17, 2026) |
| SWAP gate + unitarity proof | Done | `Core/Gate.lean` (lint-cleaned Apr 17, 2026) |
| `applyGate` — gate application to state | Done | `Core/Gate.lean` |
| `applyGate_vec_apply` — coordinate formula for gate application | **Done** (Apr 19, 2026) | `Lemmas/Gate.lean` |
| `applyGate_basisState_vec_apply` — gate on basis state gives matrix column | **Done** (Apr 19, 2026) | `Lemmas/Gate.lean` |
| `hadamard_apply_ket0` — H\|0⟩ = \|+⟩ | **Done** (Apr 19, 2026) | `Lemmas/Gate.lean` |
| `hadamard_apply_ket1` — H\|1⟩ = \|−⟩ | **Done** (Apr 19, 2026) | `Lemmas/Gate.lean` |
| `tensorWithId`, `idTensorWith`, generic `controlled` | Done | `Core/Gate.lean` |
| `tensorWithId_apply`, `idTensorWith_apply` — action on tensor states | Done | `Lemmas/Tensor.lean` |
| `tensorIndexEquiv k m` — canonical tensor basis equivalence | Done | `Core/Tensor.lean` |
| `qubitPerm`, `permuteQubits`, `permuteGate` | Done | `Core/Gate.lean` (Apr 18, 2026) |
| `onQubit`, `hadamardAt`, `phaseRotationAt`, `swapAt`, `bitReverse` | Done | `Core/Gate.lean` (Apr 18, 2026) |
| `onQubits`, `controlledAt`, `controlledPhaseAt` | Done | `Core/Gate.lean` (Apr 18, 2026) |
| `Circuit n` — `List (QGate n)` | Done | `Core/Circuit.lean` |
| `idTensorCircuit m c` — suffix-lift a circuit by mapping `idTensorWith m` over every gate | Done | `Core/Circuit.lean` |
| `tensorWithIdCircuit m c` — prefix-lift a circuit by mapping `tensorWithId m` over every gate | Done | `Core/Circuit.lean` |
| `circuitMatrix` — product of gate matrices | Done | `Core/Circuit.lean` |
| `circuitMatrix_append` — composition lemma | Done | `Core/Circuit.lean` |
| `Circuit.Implements` — primary correctness predicate | Done | `Core/Circuit.lean` |
| `tensorWithId_mul`, `tensorWithId_one`, `idTensorWith_mul`, `idTensorWith_one`, `circuitMatrix_tensorWithIdCircuit`, `circuitMatrix_idTensorCircuit` | Done | `Lemmas/Gate.lean` / `Lemmas/Circuit.lean` |
| permutation-matrix proof infrastructure (`permuteQubits_coe`, `permMatrix_mul_apply`, `mul_permMatrix_apply`, `finFunctionFinEquiv_symm_tensorIndex_{zero,succ,cons}`, `finFunctionFinEquiv_symm_qubitPerm_apply`, `tensorIndexEquiv_symm_{snd_eq_digit_zero,fst_apply_eq_digit_succ}`, and `tensorWithId_one_entry`) | **Done** (Apr 22, 2026) | `Lemmas/Gate.lean` |
| `qftMatrix n` — the QFT unitary | Done | `QFT.lean` |
| `omega_pow_two_pow` — QFT root-of-unity lemma | **Done** | `QFT.lean` |
| `dft_orthogonality` — DFT orthogonality sum | **Done** (Apr 18, 2026) | `QFT.lean` |
| `qft1_correct` — 1-qubit QFT correctness | **Done** | `QFT.lean` |
| `qftMatrix_isUnitary` | **Done** (Apr 18, 2026) | `QFT.lean` |
| `qftCircuit n` — the decomposed QFT circuit | Done | `QFT.lean` (Apr 18, 2026) |
| `qftLayers n` — the decomposed QFT layers without the final `bitReverse` | **Done** (Apr 18, 2026) | `QFT.lean` |
| shared circuit-lift scaffolding for inductive circuit proofs (`tensorWithIdCircuit`, `idTensorCircuit`, and their matrix lemmas) | **Done** | `Core/Circuit.lean` / `Lemmas/Circuit.lean` |
| `dftMatrix_succ_entry` — recursive `(n+1)`-to-`n` DFT entry factorization | **Done** (Apr 18, 2026) | `QFT.lean` |
| `omega_two` — the 2-qubit QFT root identity `omega 2 = I` | **Done** (Apr 18, 2026) | `QFT.lean` |
| `qftMatrix_two` — explicit 4×4 target matrix for `qftMatrix 2` | **Done** (Apr 18, 2026) | `QFT.lean` |
| `qftCircuit_two` — explicit gate list for `qftCircuit 2` | **Done** (Apr 18, 2026) | `QFT.lean` |
| `tensorState`, `tensorVec_norm` | **Done** (Apr 19, 2026) | `Core/Hilbert.lean` / `Lemmas/Hilbert.lean` |
| `hPlusVector`, `hPlusVector_norm`, `hPlusState`, `hPlusCircuit` | Partial (tensor support done; correctness still open) | `Algorithms/HPlus.lean` |
| GHZ state vector, circuit (requires n ≥ 1), and correctness scaffolding | Partial (normalization proved) | `Algorithms/GHZ.lean` |
| involution matrix exponential example `exp (z • A) = cosh z • I + sinh z • A` under `A ^ 2 = 1` | **Done** (Apr 25, 2026) | `Goals/NC_Ex4_2.lean` |
| `qft_correct` — main theorem | Deferred | `QFT.lean` |
| Qubit measurement / Born rule | Future | — |

---

## Known Issues and Workarounds

### 1. `EuclideanSpace` vs `Matrix.mulVec`
`EuclideanSpace ℂ (Fin n) = PiLp 2 (fun _ => ℂ)` is a newtype wrapper. `Matrix.mulVec` expects `Fin n → ℂ`, which requires an explicit bridge.

**Status:** Resolved for gate application.

**Working pattern:**
- `Matrix.toEuclideanLin` maps a matrix directly to a `LinearMap` on `EuclideanSpace`.
- To recover norm preservation from matrix unitarity, use `Matrix.toEuclideanLin_conjTranspose_eq_adjoint` together with `Matrix.UnitaryGroup.star_mul_self`, then turn the resulting inner-product preservation proof into a `LinearIsometry` via `LinearMap.isometryOfInner`.

### 2. Naming collision with `inner`
Defining a function called `inner` inside a namespace that also uses `⟪·, ·⟫_𝕜` notation causes shadowing. **Solution:** Use a different name (`braket`) and keep the `@inner 𝕜 E _` form for the definition body.

### 3. `conj` in `open Complex`
`conj` in an `open Complex` context may not resolve to the conjugation function. **Solution:** Use `star` (the general conjugation from the `Star` typeclass). This is what `Matrix.conjTranspose` uses internally.

### 4. `Circuit` must be an `abbrev`
Wrapping the denotational circuit type in a custom structure adds avoidable proof noise. The stable core representation is:
```lean
abbrev Circuit (n : ℕ) := List (QGate n)
```
This keeps `List` instances (`++`, `List.induction`, `map`) directly available and avoids repeated `.unitary` projections.

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
In `Core/Qubit.lean`, the coefficient obligation for `ketPlus` normalization does not fully close with `field_simp`; Lean can stop at a scalar goal like `Complex.normSq (1 / ↑√2) * (1 + 1) = 1`. The robust route is to prove the scalar fact first:
```lean
have hcoef : Complex.normSq (((1 : ℂ) / Real.sqrt 2)) = 1 / 2 := by
  rw [Complex.normSq_div]
  norm_num [Real.sq_sqrt (show (0 : ℝ) ≤ 2 by positivity)]
```
and then finish the sum with `nlinarith`.

### 11. `QState.mk` must often be unfolded in pointwise vector proofs
When a goal mentions `(blochState θ φ).vec` or another state built with `QState.mk`, `fin_cases` plus `simp` may stop at terms like `↑(QState.mk v h)` instead of reducing to `v`. In `Core/Qubit.lean`, the pole lemmas only closed once `QState.vec` and `QState.mk` were both added to the simp set:
```lean
fin_cases i <;> simp [QState.vec, QState.mk, blochState, superpose, ket0, ket1, basisState]
```
For the `|+⟩`/`|-⟩` orthogonality proof, a direct coordinate calculation using `PiLp.inner_apply` and `Fin.sum_univ_two` avoids the same subtype noise.

### 12. `Complex.exp_conj` rewrites can leave a `starRingEnd`-shaped angle
After rewriting a unit-circle goal with
```lean
rw [mul_comm, ← Complex.exp_conj, ← Complex.exp_add]
```
the exponent may normalize to `(starRingEnd ℂ) θ + θ` rather than `star θ + θ`. A helper lemma stated with `star θ` may then fail to rewrite the goal. The stable route is to prove the cancellation identity using the exact post-rewrite expression and finish with `simpa using congrArg Complex.exp hθ`.

### 13. `finProdFinEquiv` stops at `Fin (a * b)`, not `Fin (a + b)`-style qubit exponents
For tensor embeddings, `finProdFinEquiv` gives
`Fin (2^k) × Fin (2^m) ≃ Fin (2^k * 2^m)`, while `QGate (k+m)` is indexed by
`Fin (2^(k+m))`. The robust bridge is:
```lean
let e : Fin (2 ^ k) × Fin (2 ^ m) ≃ Fin (2 ^ (k + m)) :=
  finProdFinEquiv.trans <|
    finCongr (show 2 ^ k * 2 ^ m = 2 ^ (k + m) by rw [pow_add])
```
The orientation matters: `pow_add` states `2^(k+m) = 2^k * 2^m`, so the equality passed to
`finCongr` must be the symmetric form shown above.

### 14. `unusedSimpArgs` usually means a proof script kept historical baggage
When `simp` closes a goal through reducible definitions or lemmas already tagged with `[simp]`, extra entries in the explicit simp list are ignored and Lean reports them with `linter.unusedSimpArgs`. The same cleanup can expose trailing tactics such as `all_goals simp [...]` as unreachable because the earlier `simp` already discharged every branch. For small `fin_cases` matrix proofs, keep the simp set minimal and rerun the linter after each proof simplification pass.

### 15. `Complex.exp_pi_mul_I` does not match `exp (2 * π * I / 2 ^ 1)` without an explicit scalar rewrite
In `QFT.lean`, the `qft1_correct` proof stalled when trying to show `omega 1 = -1` by simplification alone. Even though `Complex.exp_pi_mul_I` is the right endpoint lemma, `simp` did not normalize
```lean
Complex.exp (2 * (Real.pi : ℂ) * Complex.I / (2 ^ 1 : ℂ))
```
to `Complex.exp ((Real.pi : ℂ) * Complex.I)`. The reliable route was to prove the intermediate scalar identity explicitly:
```lean
have harg : 2 * (Real.pi : ℂ) * Complex.I / (2 ^ 1 : ℂ) = (Real.pi : ℂ) * Complex.I := by
  rw [show (2 ^ 1 : ℂ) = 2 by norm_num]
  field_simp [show (2 : ℂ) ≠ 0 by norm_num]
```
and then rewrite with `rw [harg, Complex.exp_pi_mul_I]`.

### 16. `Complex.exp_nat_mul` introduces `↑(2^n)` while the original denominator may stay as `(2 : ℂ)^n`

In `omega_pow_two_pow`, rewriting
```lean
(Complex.exp (2 * Real.pi * Complex.I / (2 ^ n : ℂ))) ^ (2 ^ n)
```
with `← Complex.exp_nat_mul` produces an exponent of the form
```lean
((2 ^ n : ℕ) : ℂ) * (2 * (Real.pi : ℂ) * Complex.I / ((2 : ℂ) ^ n))
```
rather than a uniform `(2 ^ n : ℂ)` shape everywhere. The stable route is:
```lean
change Complex.exp ((((2 ^ n : ℕ) : ℂ) * (2 * (Real.pi : ℂ) * Complex.I / ((2 : ℂ) ^ n)))) = 1
have hcast : ((2 ^ n : ℕ) : ℂ) = (2 : ℂ) ^ n := by simp
rw [hcast]
field_simp [show ((2 : ℂ) ^ n) ≠ 0 by exact pow_ne_zero n (by norm_num)]
```
This mixed-shape issue is easy to miss because both sides pretty-print as `2 ^ n`.

### 17. Coordinatewise `PiLp` tensor proofs need `WithLp.ofLp_sum` before `Pi.single` simplification
For finite `EuclideanSpace` / `PiLp` vectors, evaluating a finite sum of basis vectors at a coordinate does not always reduce with `Finset.sum_apply` directly because the expression is still wrapped in `WithLp.ofLp`. In the `tensorState` normalization proof, the stable route was:
```lean
rw [WithLp.ofLp_sum]
simp_rw [WithLp.ofLp_sum]
simp [WithLp.ofLp_smul, Pi.single_apply]
```
This exposes the underlying coordinatewise `if` expression so `Finset.sum_eq_single` can collapse the tensor-basis expansion.

### 18. In this repo, parallel `check_file` calls are slower and less reliable than one full build after a broad refactor
`lake env lean AutoQuantum/<File>.lean` is expensive enough here that spawning several `check_file` MCP calls in parallel often burns timeout budget and gives less useful feedback than one `lake build AutoQuantum` run. Use `check_file` only after a single-file Lean edit. After shared API changes or edits spanning multiple Lean files, prefer one full build.

### 19. `⊗ₖ` notation in lemma files still requires `open scoped Kronecker`, even when `Core` imported the matrix modules
When adding algebraic lemmas about `tensorWithId` or `idTensorWith` outside `Core/Gate.lean`, the parser will reject `⊗ₖ` unless the local file opens the Kronecker scope. Importing a file that uses the notation is not enough; each file that writes `⊗ₖ` must include:
```lean
open scoped Kronecker
```

### 20. End-placement embeddings are not enough for textbook circuit definitions
For the decomposed QFT, `tensorWithId`, `idTensorWith`, and a fixed-layout `controlled` constructor are still too low-level: they only place gates at the ends of the register. The missing abstraction is a qubit-permutation layer
```lean
Equiv.Perm (Fin n) -> Equiv.Perm (Fin (2 ^ n))
```
plus gate conjugation by those permutations. Once that exists, arbitrary `hadamardAt`, `controlledPhaseAt`, and `bitReverse` constructors can be defined cleanly instead of by hand-built swap chains.

### 19b. `Matrix.mem_unitaryGroup_iff` exposes the `A * star A = 1` orientation directly
In `qftMatrix_isUnitary`, the first working proof attempt was organized as though the goal were
`star A * A = 1`, matching the usual column-orthogonality presentation of the DFT. But
`Matrix.mem_unitaryGroup_iff` produced the row-oriented identity
```lean
A * star A = 1
```
so the entrywise summand had to be rewritten in the shape
```lean
qftMatrix n j k * star (qftMatrix n j' k)
```
rather than the reversed product. Once the scalar factorization was aligned to that orientation,
`dft_orthogonality n j j'` applied directly.

### 19. Direct `simp` on instantiated `onQubit` / `onQubits` can leave `Nat.casesAuxOn` stuck in goals
In the first serious attempt at `qft2_correct`, unfolding
```lean
hadamardAt (0 : Fin 2)
hadamardAt (1 : Fin 2)
controlledPhaseAt (1 : Fin 2) (0 : Fin 2) (by decide) 2
```
inside a `Matrix.ext` + `fin_cases` proof did not normalize all the way to concrete 4×4 matrices.
Even helper lemmas intended to expose the `n = 2` specializations stalled on goals containing
`Nat.casesAuxOn` or timed out during `whnf`. The reliable next step is not "more simp"; it is to
prove matrix-level lemmas by first `change`-ing the goal to the explicit permuted form
(`permuteGate ... (idTensorWith 1 hadamard)`, etc.) and then reasoning entrywise from there.

### 20. Global `rw [pow_mul]` is too blunt once a DFT exponent has already been split by `pow_add`
In the new recursive DFT-entry helper for `QFT.lean`, a first attempt used
```lean
rw [pow_add, pow_add, pow_add, pow_mul]
```
to turn the final factor `ω ^ (2^(n+1) * t)` into `((ω ^ 2^(n+1)) ^ t)`. Lean also rewrote
earlier factors like `ω ^ (b * c * 2^n)` at the same time, which made the intended
`omega_pow_two_pow` rewrite miss. The stable pattern is to isolate just the desired factor:
```lean
have hfull : ω ^ (2^(n+1) * t) = (ω ^ (2^(n+1))) ^ t := by rw [pow_mul]
rw [hfull, omega_pow_two_pow]
```
This keeps the proof state aligned with the recursive factorization you actually want.

### 21. `norm_num` does not close `Real.sqrt (2 ^ 2 : ℝ) = 2` for the 2-qubit QFT scalar without an explicit square rewrite

### 22. For matrix exponentials, keep the proof in `expSeries` form until the last step
For `Matrix (Fin n) (Fin n) ℂ`, the matrix exponential is written `exp A`, not `exp ℂ A`. In the
involution identity
```lean
exp (z • A) = Complex.cosh z • I + Complex.sinh z • A
```
with `hA : A ^ 2 = 1`, the stable route was:
```lean
expSeries_even_of_sq_eq_one
expSeries_odd_of_sq_eq_one
HasSum.even_add_odd
simpa [expSeries_apply_eq] using ...
```
Trying to split the already-expanded `exp_eq_tsum` series too early leads to avoidable mismatch
goals between
```lean
fun n => (n !⁻¹ : ℂ) • (z • A) ^ n
```
and the cleaner `expSeries` even/odd lemmas. Also, factorial coercions parse more reliably as
`↑(Nat.factorial n)` than as `↑(n!)` inside larger expressions.
In the new explicit target lemma `qftMatrix_two`, the normalization factor
```lean
(1 / (Real.sqrt (2 ^ 2 : ℝ) : ℂ))
```
needed a helper lemma because `norm_num` did not solve `√4 = 2` directly. The stable route was:
```lean
have hsqrtR : Real.sqrt (2 ^ 2 : ℝ) = 2 := by
  rw [show (2 ^ 2 : ℝ) = (2 : ℝ) ^ 2 by norm_num]
  exact Real.sqrt_sq (by positivity)
```
and then cast that real equality into `ℂ` with `exact_mod_cast`.

### 22. `Complex.I_pow_eq_pow_mod` handles most QFT entry powers, but a cleanup pass still needs `I_sq` / `I_pow_three`
For `qftMatrix_two`, `simp [Complex.I_pow_eq_pow_mod]` reduced most branches immediately, but some entries still stopped at terms like
```lean
Complex.I ^ 2 * (1 / 2)
Complex.I ^ 3 * (1 / 2)
```
The reliable finish was a second cleanup pass:
```lean
all_goals
  try simp [Complex.I_sq, Complex.I_pow_three]
  try ring_nf
```
That pattern is likely to be useful again for the eventual explicit `qft2_correct` matrix calculation.

### 23. The inductive QFT proof cannot use the suffix layers directly as `qftCircuit n` until bit-reversal is decomposed
The first serious attempt at the general proof treated the target-`1..n` part of `qftCircuit (n+1)`
as though it were simply `qftCircuit n` embedded on the last `n` qubits. That is not literally
true: the raw suffix layers in `qftCircuit (n+1)` do **not** include a standalone suffix
bit-reversal gate, while `qftCircuit n` does. The induction hypothesis only becomes usable after a
separate permutation lemma decomposes the full `(n+1)`-qubit `bitReverse` into:
```lean
embedded_suffix_bitReverse * final_swap_0_last
```
This is not just cosmetic proof organization; it is the structural step that makes the recursive
statement line up with the existing induction hypothesis.

### 24. `⊗ₖ` notation is file-local syntax: importing `Core/Gate.lean` does not automatically open the Kronecker scope in a lemma file
When the generic tensor-embedding lemmas were added outside `Core/Gate.lean`, one proof used
```lean
(1 : Matrix (Fin 2) (Fin 2) ℂ) ⊗ₖ (U : Matrix (Fin (2 ^ n)) (Fin (2 ^ n)) ℂ)
```
but the file had not opened `scoped Kronecker`. Lean then parsed the proof badly enough that
the follow-on errors looked unrelated to notation. The fix is explicit:
```lean
open scoped Kronecker
```
inside every file that uses `⊗ₖ`, even if some imported file already opened that scope locally.

### 30. `change` fails for concrete-type tensor lemmas; use abstract `ψ : QHilbert k` instead
When a lemma involves `tensorVec ψ φ` and `ψ` or `φ` is a concrete term (e.g., `(hPlusState 1).vec`), the `change` tactic fails during the coordinatewise proof because Lean reduces the concrete term during definitional equality checking, causing a mismatch. The fix is to always state and prove tensor coordinate lemmas with **abstract** `ψ : QHilbert k` and `φ : QHilbert m`, then instantiate them:
```lean
-- fails if ψ is concrete:
change ∑ x, ∑ y, (if e (a, b) = e (x, y) then ψ x * φ y else 0) = ψ a * φ b

-- works: prove with abstract ψ φ, then call:
exact tensorVec_apply _ _ a b
```
When bridging from a `.vec`-qualified goal to `tensorVec`, prepend `show tensorVec ψ.vec φ.vec (e (a,b)) = _` before `exact tensorVec_apply _ _ a b`.

### 31. `simp [ha]` where `ha : a = 0` does not reliably substitute inside complex expressions; use `subst ha` first
After a `by_cases ha : a = 0`, writing `simp [ha, ...]` does not always rewrite `a` inside subterms like `e (a, b)`. The goal silently stays with `a` rather than `0`, so `this : e (0, b) ≠ 0` does not unify with the goal `¬ e (a, b) = 0`. Fix: call `subst ha` (or `subst hb`) immediately after the case split, which eliminates the variable everywhere:
```lean
by_cases ha : a = 0
· subst ha   -- ← eliminates `a` everywhere before have/simp
  have : e (0, b) ≠ 0 := ...
  simp [hb, this]
```
`subst` only works when `ha` has the form `variable = expr` (not `expr = variable`). If the hypothesis is reversed, use `subst ha.symm` or `simp only [ha]` carefully.

### 32. `obtain ⟨a, b, rfl⟩ := e.surjective j` fails; surjectivity of `A × B ≃ C` yields `∃ p : A × B`, not `∃ a b`
For an equivalence `e : A × B ≃ C`, `e.surjective j` has type `∃ p : A × B, e p = j`. The destructuring pattern must use **nested** angle brackets:
```lean
obtain ⟨⟨a, b⟩, rfl⟩ := e.surjective j   -- ✅
obtain ⟨a, b, rfl⟩   := e.surjective j   -- ❌ pattern mismatch
```
After this line, `j` is replaced everywhere by `e (a, b)` and the goal is restated in terms of `a` and `b`.

### 33. `Finset.sum_ite_eq` and `sum_ite_eq'` have swapped naming vs. expectation
In Mathlib v4.29.0 the two lemmas are:
```lean
Finset.sum_ite_eq  : ∑ x in s, (if a = x then f x else 0) = if a ∈ s then f a else 0  -- constant = variable
Finset.sum_ite_eq' : ∑ x in s, (if x = a then f x else 0) = if a ∈ s then f a else 0  -- variable = constant
```
The "prime" variant has `x = a` (variable on the left), and the non-prime variant has `a = x` (constant on the left). This is the **opposite** of the usual convention where the prime adds commutativity. If your inner sum is `∑ y, if b = y then ... else 0` (constant `b` on the left), use `Finset.sum_ite_eq` (no prime).

### 34. The `e` in a `show` or `hmat` proof must match the internal `e` in `tensorWithId` syntactically
`tensorWithId` uses `finProdFinEquiv.trans <| finCongr (show 2^k * 2^m = 2^(k+m) by rw [pow_add])`. When proving matrix-entry lemmas by `show (Matrix.reindex e e ...) (e (a,b)) (e (x,y)) = _`, the local `e` must be defined **identically** (same expression) as the internal one. Using `(pow_add 2 k m).symm` instead of `show ... by rw [pow_add]` creates a different proof term; `Equiv.symm_apply_apply` then fails because the two `e`s are not syntactically unified. Copy the exact `let e :=` from the `tensorWithId` definition.

### 25. The recursive `target.succ` QFT layers appear to require `tensorWithId 1`, not the older suffix direction
During the next general-proof pass, `QFT.lean` was refactored to expose
```lean
qftLayers n
```
as the gate list without the final `bitReverse`. A direct attempted bridge lemma of the form
```lean
hadamardAt q.succ = idTensorWith 1 (hadamardAt q)
```
did not fail for a merely syntactic reason. It exposed that the two sides are using different
computational-basis reindexings.

The shared suffix helper direction
```lean
idTensorWith 1 U
```
uses the split `b * 2^n + i`, i.e. it adds a new **most-significant** qubit via `I₂ ⊗ U`.
But the raw recursive QFT layers in `qftCircuit (n+1)` are indexed by `target.succ`, which is the
shape you get when the old qubits are shifted upward because a new **least-significant** qubit was
inserted.

So the likely next circuit-side embedding for the inductive proof is
```lean
tensorWithId 1
```
rather than `idTensorWith 1`. This distinction is easy to miss because both are
“attach one idle qubit” operations, but they are different Kronecker/reindex conventions.
### 26. `ext` on `PiLp`/`EuclideanSpace` after `Subtype.ext` produces `(↑...).ofLp i`, not `(applyGate ...).vec.ofLp i`
After `apply Subtype.ext; ext i` on a `QState` equality, the goal takes the form
```lean
(↑(applyGate hadamard ket0)).ofLp i = (↑ketPlus).ofLp i
```
where `↑` is the `Subtype.val` coercion. The lemma `applyGate_vec_apply` has LHS `(applyGate U ψ).vec i`, which elaborates to `(applyGate U ψ).vec.ofLp i`. Lean's `rw` cannot match `.val.ofLp i` against `.vec.ofLp i` syntactically, even though `QState.vec psi = psi.val` definitionally.

**Fix:** insert `show (applyGate hadamard ket0).vec i = ketPlus.vec i` (which `change`-style definitional equality accepts) before the `rw [applyGate_vec_apply]`:
```lean
apply Subtype.ext
ext i
show (applyGate hadamard ket0).vec i = ketPlus.vec i
rw [applyGate_vec_apply]
```

### 27. `Matrix.dotProduct` is unknown as a `simp` argument; use `rfl` to close the `⬝ᵥ` residual goal
After `simp [Matrix.toEuclideanLin, Matrix.toLin'_apply, Matrix.mulVec]`, a goal of the form
```lean
(fun j => ↑U i j) ⬝ᵥ ψ.vec.ofLp = ∑ x, ↑U i x * ψ.vec.ofLp x
```
may remain. Here `⬝ᵥ` is `Matrix.dotProduct`, but writing `simp [Matrix.dotProduct]` raises "Unknown constant". The left and right sides are definitionally equal (both reduce to `∑ j, U i j * ψ.vec.ofLp j`), so the goal closes immediately with `rfl`.

### 28. `EuclideanSpace.single_apply` is deprecated; use `PiLp.single_apply` instead
`EuclideanSpace.single_apply` was removed from the `EuclideanSpace` namespace. In Mathlib v4.29.0 the replacement is:
```lean
PiLp.single_apply (p : ENNReal) (𝕜 : Type*) (i a j)
    : (PiLp.single p i a).ofLp j = if j = i then a else 0
```
Note the slightly different argument order and that `p` and `𝕜` are now explicit. In practice `simp [PiLp.single_apply]` works identically to the old usage; just rename every `EuclideanSpace.single_apply` occurrence.

### 35. `hadamardAt 0` via `permuteGate (swap last 0) (idTensorWith n H)` resists direct proof; induct from the back instead

Proving `hadamardAt (0 : Fin (1+n)) = tensorWithId n hadamard` requires showing that
`qubitPerm (Equiv.swap (Fin.last n) 0)` maps the tensor-factor basis index
`e₁(a, b) : Fin (2^1) × Fin (2^n) → Fin (2^(1+n))` to the swapped form
`e₂(b, a)`. This involves unpacking `finFunctionFinEquiv` bitstring encoding and is
confirmed hard to automate (DeepSeek failed after ~6 attempts, April 20, 2026).

The easier route: use `hadamardAt (Fin.last n)` instead.
`Equiv.swap (Fin.last n) (Fin.last n) = Equiv.refl` eliminates the permutation entirely,
giving `hadamardAt (Fin.last n) = idTensorWith n hadamard` with a one-liner proof:
```lean
simp [hadamardAt, onQubit, Equiv.swap_self, permuteGate, permuteQubits]
```
Then induct from the back of `hPlusCircuit` and prove `idTensorWith_apply` (the companion
to `tensorWithId_apply`, same proof pattern) to close `hPlus_correct`.

### 36. `idTensorWith_apply` proof uses `Finset.mul_sum` where `tensorWithId_apply` used `Finset.sum_mul`

When mirroring the `tensorWithId_apply` proof to obtain `idTensorWith_apply`, the factorization of the double sum changes order: `∑_x ∑_y (Im a x * ψ x) * (U b y * φ y) = (∑_x Im a x * ψ x) * (∑_y U b y * φ y)`. After collapsing the identity matrix sum to `ψ a`, we need to factor `ψ a` out of the remaining sum over `y`. This is `Finset.mul_sum` (factor on the left) rather than `Finset.sum_mul` (factor on the right). The rest of the proof is identical.

### 29. `hPlusVector` coordinates simplify cleanly with `basisState` and `QState.vec`; explicit `EuclideanSpace.single_apply` is unnecessary
For the uniform-superposition normalization proof, the pointwise identity
```lean
have hcoord : ∀ j : Fin (2 ^ n), hPlusVector n j = (1 / Real.sqrt (2 ^ n : ℝ) : ℂ) := by
  intro j
  simp [hPlusVector, basisState, QState.vec]
```
closed directly. An earlier attempt added `EuclideanSpace.single_apply`, but in Mathlib v4.29 that lemma is deprecated in favor of `PiLp.single_apply`, and it was not needed anyway because `simp` already unfolds the basis-state coordinates through the subtype wrapper.

### 30. `tensorIndexEquiv n 1` + `finFunctionFinEquiv.symm` exposes the trailing qubit as digit `0`
For qubit-permutation proofs on a register split as `n` leading qubits plus one trailing qubit, the useful coordinate facts are:
```lean
finFunctionFinEquiv.symm (tensorIndexEquiv n 1 (a, b)) 0 = b
finFunctionFinEquiv.symm (tensorIndexEquiv n 1 (a, b)) j.succ =
  finFunctionFinEquiv.symm a j
```
The `0` case closes with `simp [tensorIndexEquiv]` plus `omega`. The `succ` case needs one explicit quotient rewrite:
```lean
have hquot : ((b : ℕ) + 2 * a) / (2 * 2 ^ (j : ℕ)) = a / 2 ^ (j : ℕ) := by
  rw [← Nat.div_div_eq_div_mul]
  rw [Nat.add_mul_div_left _ _ (by omega), Nat.div_eq_of_lt b.is_lt, zero_add]
```
After that, `simp [hquot]` closes the digit goal. This is the stable way to relate `qubitPerm` on `castSucc`-lifted qubits to the tensor decomposition used by `tensorWithId 1`.

### 31. The tempting `ρ = tensorWithId 1` lift of the old-qubit swap is not a one-line simp reduction
A tempting reduction for `hadamardAt_castSucc_eq` is to set
```lean
ρ := Equiv.swap (Fin.castSucc (Fin.last m)) (Fin.castSucc i)
```
and try to prove
```lean
permuteQubits ρ = tensorWithId 1 (permuteQubits (Equiv.swap (Fin.last m) i))
```
Current evidence only supports the weaker conclusion that this transport lemma does **not** fall out from `simp` plus the basic digit lemmas. The interaction between `castSucc` on qubit indices and the base-2 digits exposed by `finFunctionFinEquiv.symm` is subtle, so this route should be treated as an explicit proof obligation rather than an obvious rewrite.

### 32. `finFunctionFinEquiv.symm` on a reassembled `tensorIndexEquiv` often needs an explicit `Fin.cons` normal form
For the remaining `hadamardAt_castSucc_eq` blocker, applying
```lean
apply_fun (finFunctionFinEquiv (m := 2) (n := m + 2)).symm
```
to the transport goal does **not** let `simp` reuse the `tensorIndexEquiv` digit lemmas automatically. Lean keeps the reassembled right-hand side as `% 2` / `/ 2^j` arithmetic on the full `tensorIndexEquiv` value unless the tensor bitstring is first rewritten into an explicit tuple function.

The stable normalization is the helper
```lean
finFunctionFinEquiv_symm_tensorIndex_cons :
  finFunctionFinEquiv.symm (tensorIndexEquiv n 1 (a, b)) =
    Fin.cons b (finFunctionFinEquiv.symm a)
```
proved with `rw [Fin.cons_zero, finFunctionFinEquiv_symm_tensorIndex_zero]` and
`rw [Fin.cons_succ, finFunctionFinEquiv_symm_tensorIndex_succ]`.

Without this explicit `Fin.cons` form, `simp [qubitPerm]` tends to unfold back to arithmetic instead of the intended bitstring-level transport argument.

### 33. `pow_succ` does not by itself bridge `Fin (2^k ⊕ 2^k)` to `Fin (2^(k+1))`
For the generic controlled-gate constructor, the index equivalence naturally starts at
```lean
Fin (2 ^ k) ⊕ Fin (2 ^ k)
```
but `finCongr` needs a literal equality
```lean
2 ^ k + 2 ^ k = 2 ^ (k + 1)
```
while `pow_succ 2 k` gives the multiplicative form
```lean
2 ^ (k + 1) = 2 ^ k * 2.
```
`simpa [two_mul, Nat.mul_comm] using (pow_succ 2 k).symm` was not strong enough here. The stable route was an explicit calculation:
```lean
calc
  2 ^ k + 2 ^ k = 2 * 2 ^ k := by rw [two_mul]
  _ = 2 ^ k * 2 := by rw [Nat.mul_comm]
  _ = 2 ^ (k + 1) := by simpa using (pow_succ 2 k).symm
```
This is the reliable bridge when packaging block-diagonal `diag(I, U)` matrices as `(k+1)`-qubit gates.
