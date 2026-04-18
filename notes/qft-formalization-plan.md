# QFT Formalization Plan

Step-by-step plan for proving the correctness of the Quantum Fourier Transform circuit in Lean 4.
Current scaffold lives in `lean/AutoQuantum/Algorithms/QFT.lean`.

---

## Mathematical Background

### Definition
The QFT on n qubits is the unitary operator:

```
QFT |j⟩ = (1 / √(2^n)) Σ_{k=0}^{2^n - 1} ω^{jk} |k⟩
```

where `ω = exp(2πi / 2^n)` is the primitive `2^n`-th root of unity.

As a matrix:
```
QFT[j, k] = (1 / √(2^n)) · exp(2πi · j · k / 2^n)
```

This is `(1 / √(2^n))` times the DFT matrix.

### Circuit Decomposition (for n qubits)

The standard circuit uses:
- `H` — Hadamard gate
- `R_k` — phase rotation by `2π/2^k`: `[[1, 0], [0, exp(2πi/2^k)]]`
- `SWAP` gates to reverse bit order at the end

**For each qubit m (m = 0 is MSB):**
1. Apply H to qubit m
2. Apply controlled-R_2 (control=qubit m+1, target=qubit m)
3. Apply controlled-R_3 (control=qubit m+2, target=qubit m)
4. ...
5. Apply controlled-R_{n-m} (control=qubit n-1, target=qubit m)

Repeat for all m, then bit-reverse.

---

## Lean Proof Strategy

### Step 1: Define the QFT matrix ✓ (done)

```lean
noncomputable def omega (n : ℕ) : ℂ :=
  Complex.exp (2 * Real.pi * Complex.I / (2 ^ n : ℂ))

noncomputable def qftMatrix (n : ℕ) : Matrix (Fin (2^n)) (Fin (2^n)) ℂ :=
  fun j k => (1 / Real.sqrt (2^n : ℝ) : ℂ) * (omega n) ^ (j.val * k.val)
```

### Step 2: Prove ω is a primitive root of unity ✓ (done)

```lean
lemma omega_pow_two_pow (n : ℕ) : (omega n) ^ (2 ^ n) = 1
```

**Proof:** rewrite with `← Complex.exp_nat_mul`, then cancel the factor `((2 ^ n : ℕ) : ℂ)` against the denominator `((2 : ℂ) ^ n)` in the exponent and finish with `Complex.exp_two_pi_mul_I`.

### Step 3: DFT orthogonality relation ✓ (done)

```lean
lemma dft_orthogonality (n : ℕ) (j j' : Fin (2 ^ n)) :
    ∑ k : Fin (2 ^ n), (omega n) ^ (j.val * k.val) * star ((omega n) ^ (j'.val * k.val)) =
    if j = j' then (2 ^ n : ℂ) else 0
```

Note: use `star` for conjugation, not `conj` (see `lean-quantum-landscape.md`).

**Implemented proof shape:**
- Rewrite `star (ω^m)` as `(ω⁻¹)^m` using `omega_star`.
- In the diagonal case, each summand becomes `1`.
- In the off-diagonal case, package the summand as a geometric progression with ratio
  `r = ω^j * (ω⁻¹)^j'`.
- Show `r^(2^n) = 1` from `omega_pow_two_pow`.
- Show `r ≠ 1` via `Complex.isPrimitiveRoot_exp` and `IsPrimitiveRoot.zpow_eq_one_iff_dvd`.
- Finish the off-diagonal sum with `geom_sum_mul`.

### Step 4: Prove QFT matrix is unitary ✓ (done)

Uses `dft_orthogonality` to show `qftMatrix n * star (qftMatrix n) = 1` entry-wise.
The key proof engineering point is that `Matrix.mem_unitaryGroup_iff` exposes the goal in the
`A * star A = 1` orientation, so the summand must be factored as
`qftMatrix n j k * star (qftMatrix n j' k)`.

### Step 5: Define gate embeddings (done)

`tensorWithId`, `idTensorWith`, and `controlled` in `Gate.lean` are now available. The working pattern is Kronecker product plus reindexing through `finProdFinEquiv` / `finCongr`, and `controlled` is implemented as a block-diagonal matrix reindexed from `Fin 2 ⊕ Fin 2` to `Fin 4`.

### Step 6: Define the QFT circuit ✓ (done)

The decomposed circuit is now defined in `QFT.lean` using the new gate-placement API:

- `hadamardAt`
- `controlledPhaseAt`
- `bitReverse`

The construction follows the textbook loop over target qubits `m = 0, ..., n-1`, with
controlled phase gates from later qubits onto `m`, followed by a final bit-reversal gate.

The API work that made this possible is recorded in `notes/qft-api-roadmap.md`.

### Step 7: Prove `qft_correct` (deferred)

The circuit is now present, so the remaining work is proof-only. This depends on Steps 3–4 plus
either:

- a direct matrix proof for small instances, and then
- a recursive factoring proof for general `n`,

or a stronger library of lemmas about the semantics of `controlledPhaseAt`, `hadamardAt`, and
`bitReverse`.

Current status: the file now builds with only `qft_correct` and `qft2_correct` left as `sorry`s.
Two additional helper lemmas are now in place:

- `omega_two : omega 2 = Complex.I`
- `qftMatrix_two` — the explicit 4×4 target matrix for `qftMatrix 2`
- `qftCircuit_two` — the explicit textbook gate list for `qftCircuit 2`

For the general inductive step, the file now also contains explicit index-splitting helpers
`msbIndex` / `lsbIndex` together with `dftMatrix_succ_entry`. This factors an `(n+1)`-qubit DFT
entry into:

- the leading-bit phase term,
- the lower-bit contribution to the new output bit, and
- the recursive `n`-qubit DFT term.

This corrected an earlier informal sketch that omitted the extra lower-bit phase
`ω_(n+1)^(j' * k0)` when writing `j = j0 * 2^n + j'` and `k = k0 + 2 * k'`.

The next concrete milestone is still `qft2_correct`, but a brute-force `simp` over the full
definition of `qftCircuit 2` does **not** reduce the embedded gate placements enough. A follow-up
attempt also showed that even helper lemmas for instantiated terms like `hadamardAt (1 : Fin 2)`
can get stuck on `Nat.casesAuxOn` when unfolded naively. The likely next move is to prove explicit
4×4 matrix lemmas for:

- `hadamardAt 0`
- `hadamardAt 1`
- `controlledPhaseAt 1 0 2`
- `bitReverse`

If we instead prioritize the general theorem first, the exact remaining circuit-side lemma inventory
is now written up in `notes/qft-general-proof-obligations.md`.

### Textbook alignment

The current proof plan intentionally tracks both local textbook references, but in different layers:

- **Nielsen and Chuang, §5.1:** the circuit definition `qftCircuit` follows the standard gate-by-gate construction exactly: Hadamard on each target qubit, controlled phase rotations from later qubits, and final bit reversal.
- **Fenner course notes, pages 99 and 109–110:** the proved matrix lemmas and the unfinished inductive step follow the DFT-first proof style: orthogonality by geometric series, then recursive decomposition by splitting indices into leading/trailing bits.

This means the remaining proof obligation `qftCircuit_succ_matrix` is expected to look more like Fenner’s recursive correctness proof than Nielsen and Chuang’s product-state derivation. That is acceptable. If we want the final file to advertise the Nielsen correspondence more clearly, the missing ingredient is an explanatory lemma that rewrites the target QFT state into the binary-fraction product form before the final swap layer.

---

## Known Proof Obstacles

1. **`exp(2πi) = 1`**: The right Mathlib lemma is not `Complex.exp_two_pi_mul_I` (unused in v4.29 simp). Try:
   - `Complex.exp_int_mul_two_pi_mul_I 1`
   - Or `rw [show 2 * Real.pi * Complex.I = ..., Complex.exp_mul_I]` + trig identities

2. **Geometric series over `Fin n`**: The needed lemma is roughly `Finset.univ_sum_geom_series`. Search Mathlib for `geom_sum` — the exact name and location changed between Mathlib versions.

3. **`Fin (2^(n+1))` ≅ `Fin (2^n) × Fin 2`**: Use `Fin.divNat` / `Fin.modNat` or `finProdFinEquiv` for tensor product reindexing.

4. **Kronecker product indices**: `Matrix.kroneckerMap A B` produces a matrix indexed by `ι × κ`, not `Fin (n * m)`. Need to reindex via `Fintype.equivFin` or similar.

5. **Casting `2^n` between types**: `push_cast` and `norm_cast` help with `(2^n : ℕ)` vs `(2^n : ℝ)` vs `(2^n : ℂ)` mismatches.

---

## Small Cases First

For confidence, prove n=1 and n=2 explicitly before the general case.

**n=1:** `qft1_correct` is now proved. The proof reduces `qftCircuit1` to `hadamard`, then uses `Matrix.ext` + `fin_cases` on the 2×2 matrix entries. The only nontrivial branch is `(1,1)`, where `omega 1 = -1` is obtained by an explicit rewrite from `exp (2 * π * I / 2^1)` to `exp (π * I)` followed by `Complex.exp_pi_mul_I`. Note: `decide` and `native_decide` do **not** work for `ℂ`-valued matrices (ℂ is not a `DecidableEq` type in a useful sense here).

**n=2:** `qftCircuit2 = qftMatrix 2` remains open. The direct brute-force proof by
`Matrix.ext` + `fin_cases` + unfolding `qftCircuit` exposes too much unreduced placement
machinery (`onQubit`, `onQubits`, `permuteGate`, `permuteQubits`). The newly added lemmas
`omega_two` and `qftCircuit_two` remove the scalar/root-of-unity issue and freeze the exact gate
sequence, but the gate-placement semantics still need to be pushed down to concrete 4×4 matrices.
The next reasonable proof shape is:

1. prove explicit 4×4 matrix lemmas for the four gates in `qftCircuit2`;
2. rewrite the circuit matrix to a product of those explicit matrices;
3. finish the 4×4 equality by `Matrix.ext` + `fin_cases`, with the scalar identity
   `omega 2 = Complex.I`.

For the general recursive proof, the current entrywise target should be read as:
```lean
dftMatrix (n+1) (j0 * 2^n + j') (k0 + 2 * k')
  = ω^(j0 * k0 * 2^n) * ω^(j' * k0) * dftMatrix n j' k'
```
where the recursive `dftMatrix n` term arises from the `ω^(2 * (j' * k'))` contribution via
`omega_sq_pred`.

---

## Reference: n=2 QFT Circuit Explicitly

For 2 qubits (|q0 q1⟩, q0 = MSB):
1. H on q0
2. Controlled-R_2 (control=q1, target=q0)
3. H on q1
4. SWAP(q0, q1)

Matrix product (basis order |00⟩, |01⟩, |10⟩, |11⟩):
```
SWAP ⬝ (I ⊗ H) ⬝ CR_2 ⬝ (H ⊗ I) = QFT_4
```

where `QFT_4[j,k] = (1/2) · i^{jk}` (since ω = i for N=4).
