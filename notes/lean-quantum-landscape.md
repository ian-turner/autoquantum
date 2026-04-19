# Lean 4 Quantum Computing Landscape

Current state of quantum formalization in Lean 4 / Mathlib, and what AutoQuantum has built on top of it.
Last updated: April 18, 2026 (Mathlib v4.29.0).

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
| `ket0`, `ket1`, `ketPlus`, `ketMinus` | Done | `Qubit.lean` (lint-cleaned Apr 17, 2026) |
| `ketPlus_braket_ketMinus` | Done | `Qubit.lean` |
| Bloch sphere parameterization | Done | `Qubit.lean` |
| `QGate k` — unitary gate type | Done | `Gate.lean` |
| Pauli X, Y, Z gates + unitarity proofs | Done | `Gate.lean` (lint-cleaned Apr 17, 2026) |
| Hadamard gate + unitarity proof | Done | `Gate.lean` |
| Phase rotation R_k + unitarity proof | Done | `Gate.lean` |
| CNOT gate + unitarity proof | Done | `Gate.lean` (lint-cleaned Apr 17, 2026) |
| SWAP gate + unitarity proof | Done | `Gate.lean` (lint-cleaned Apr 17, 2026) |
| `applyGate` — gate application to state | Done | `Gate.lean` |
| `tensorWithId`, `idTensorWith`, `controlled` | Done | `Gate.lean` |
| `qubitPerm`, `permuteQubits`, `permuteGate` | Done | `Gate.lean` (Apr 18, 2026) |
| `onQubit`, `hadamardAt`, `phaseRotationAt`, `swapAt`, `bitReverse` | Done | `Gate.lean` (Apr 18, 2026) |
| `onQubits`, `controlledAt`, `controlledPhaseAt` | Done | `Gate.lean` (Apr 18, 2026) |
| `Circuit n` — list of gate steps | Done | `Circuit.lean` |
| `circuitMatrix` — product of gate matrices | Done | `Circuit.lean` |
| `circuitMatrix_append` — composition lemma | Done | `Circuit.lean` |
| `Circuit.CorrectFor` — correctness predicate | Done | `Circuit.lean` (unitary witness intentionally unused) |
| `qftMatrix n` — the QFT unitary | Done | `QFT.lean` |
| `omega_pow_two_pow` — QFT root-of-unity lemma | **Done** | `QFT.lean` |
| `dft_orthogonality` — DFT orthogonality sum | **Done** (Apr 18, 2026) | `QFT.lean` |
| `qft1_correct` — 1-qubit QFT correctness | **Done** | `QFT.lean` |
| `qftMatrix_isUnitary` | **Done** (Apr 18, 2026) | `QFT.lean` |
| `qftCircuit n` — the decomposed QFT circuit | Done | `QFT.lean` (Apr 18, 2026) |
| `qftLayers n` — the decomposed QFT layers without the final `bitReverse` | **Done** (Apr 18, 2026) | `QFT.lean` |
| `liftEquiv`, `liftGate`, `liftCircuit`, `liftGate_mul`, `circuitMatrix_liftCircuit` — suffix-lift scaffolding for the inductive QFT proof | **Done** (Apr 18, 2026) | `QFT.lean` |
| `dftMatrix_succ_entry` — recursive `(n+1)`-to-`n` DFT entry factorization | **Done** (Apr 18, 2026) | `QFT.lean` |
| `omega_two` — the 2-qubit QFT root identity `omega 2 = I` | **Done** (Apr 18, 2026) | `QFT.lean` |
| `qftMatrix_two` — explicit 4×4 target matrix for `qftMatrix 2` | **Done** (Apr 18, 2026) | `QFT.lean` |
| `qftCircuit_two` — explicit gate list for `qftCircuit 2` | **Done** (Apr 18, 2026) | `QFT.lean` |
| `zeroIndex`, `onesIndex`, `allZeroState`, `allOneState` — canonical GHZ basis indices and endpoint states | **Done** (Apr 18, 2026) | `GHZ.lean` |
| `ghzState n` — general GHZ target state with a special `n = 0` case | **Done** (Apr 18, 2026) | `GHZ.lean` |
| `ghzCnotChain n` — nearest-neighbor `CX 0 1; ...; CX n-1 n` chain | **Done** (Apr 18, 2026) | `GHZ.lean` |
| `ghzCircuit n` — general GHZ preparation circuit | **Done** (Apr 18, 2026) | `GHZ.lean` |
| `ghzCircuit_three` — sanity-check specialization to the familiar 3-qubit circuit | **Done** (Apr 18, 2026) | `GHZ.lean` |
| `ghzCircuit_prepares_ghz` — state-preparation theorem for `n + 1` qubits | Partial | `GHZ.lean` (one remaining `sorry`; proof should induct over `ghzCnotChain`) |
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

### 17. End-placement embeddings are not enough for textbook circuit definitions
For the decomposed QFT, `tensorWithId`, `idTensorWith`, and a fixed-layout `controlled` constructor are still too low-level: they only place gates at the ends of the register. The missing abstraction is a qubit-permutation layer
```lean
Equiv.Perm (Fin n) -> Equiv.Perm (Fin (2 ^ n))
```
plus gate conjugation by those permutations. Once that exists, arbitrary `hadamardAt`, `controlledPhaseAt`, and `bitReverse` constructors can be defined cleanly instead of by hand-built swap chains.

### 18. `Matrix.mem_unitaryGroup_iff` exposes the `A * star A = 1` orientation directly
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

### 24. `⊗ₖ` notation is file-local syntax: importing `Gate.lean` does not automatically open the Kronecker scope in `QFT.lean`
When the new suffix-lift helper `liftGate` was first written in `QFT.lean`, the definition used
```lean
(1 : Matrix (Fin 2) (Fin 2) ℂ) ⊗ₖ (U : Matrix (Fin (2 ^ n)) (Fin (2 ^ n)) ℂ)
```
but the file had not opened `scoped Kronecker`. Lean then parsed the definition badly enough that
the follow-on errors looked like a malformed `Subtype.mk` or an attempted application of
`Matrix.reindex` to the identity matrix. The fix is explicit:
```lean
open scoped Kronecker
```
inside every file that uses `⊗ₖ`, even if some imported file already opened that scope locally.

### 25. The recursive `target.succ` QFT layers appear to require `tensorWithId 1`, not the older suffix-lift helper
During the next general-proof pass, `QFT.lean` was refactored to expose
```lean
qftLayers n
```
as the gate list without the final `bitReverse`. A direct attempted bridge lemma of the form
```lean
hadamardAt q.succ = liftGate (hadamardAt q)
```
did not fail for a merely syntactic reason. It exposed that the two sides are using different
computational-basis reindexings.

The existing helper
```lean
liftGate U
```
uses the split `b * 2^n + i`, i.e. it adds a new **most-significant** qubit via `I₂ ⊗ U`.
But the raw recursive QFT layers in `qftCircuit (n+1)` are indexed by `target.succ`, which is the
shape you get when the old qubits are shifted upward because a new **least-significant** qubit was
inserted.

So the likely next circuit-side embedding for the inductive proof is
```lean
tensorWithId 1
```
rather than `liftGate` / `idTensorWith 1`. This distinction is easy to miss because both are
“attach one idle qubit” operations, but they are different Kronecker/reindex conventions.

### 26. Concrete `tensorWithId` / `idTensorWith` goals can get stuck on `finProdFinEquiv.symm`, `Fin.divNat`, and `Fin.modNat`
In `Algorithms/GHZ.lean`, the natural first proof attempt was to evaluate the three state-transition
lemmas directly from
```lean
tensorWithId 2 hadamard
tensorWithId 1 cnot
idTensorWith 1 cnot
```
using `Subtype.ext`, `ext i`, and `fin_cases i`. That gets surprisingly far, but the remaining goals
do not simplify to clean coordinate equalities. Instead they stop in shapes like:
```lean
vecCons ... (Fin.divNat 4) * 1 (Fin.divNat 4, Fin.modNat 4).2 ... = ...
```
This is a signal that the proof should switch from “more `simp`” to an explicit matrix bridge. For
small fixed-width examples, the better next step is to prove matrix-level specializations for the
embedded gates first, and only then do the state-coordinate calculation.

### 27. The GHZ superposition formula needs a special `n = 0` branch
When `GHZ.lean` was generalized from a 3-qubit example to an `n`-qubit family, the obvious first
definition was
```lean
ghzState n := (|0...0⟩ + |1...1⟩) / √2
```
for all `n`. That does **not** work at `n = 0`. On zero qubits, `|0...0⟩` and `|1...1⟩` collapse to
the same unique basis vector in `Fin (2 ^ 0) = Fin 1`, so the orthogonality proof needed by
`superpose_norm_eq_one` is false.

The stable formalization is:
```lean
ghzState 0 := allZeroState 0
ghzState (n + 1) := (|0...0⟩ + |1...1⟩) / √2
```
and then state the main correctness theorem on `n + 1` qubits instead of trying to force the
nonempty-register argument through the degenerate zero-qubit case.
