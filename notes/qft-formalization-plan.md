# QFT Formalization Plan

A step-by-step plan for proving the correctness of the Quantum Fourier Transform circuit in Lean 4.

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

This is exactly `(1 / √(2^n))` times the DFT matrix.

### Circuit Decomposition (for n qubits)

The standard circuit uses:
- `H` — Hadamard gate
- `R_k` — phase rotation by `2π/2^k`:
  ```
  R_k = [[1, 0], [0, exp(2πi/2^k)]]
  ```
- `SWAP` gates to reverse bit order at the end

**Circuit for qubit 0 (most significant):**
1. Apply H to qubit 0
2. Apply controlled-R_2 (control=qubit 1, target=qubit 0)
3. Apply controlled-R_3 (control=qubit 2, target=qubit 0)
4. ...
5. Apply controlled-R_n (control=qubit n-1, target=qubit 0)

Repeat for each qubit, then bit-reverse.

The matrix identity to prove is:
```
Circuit_matrix = QFT_matrix
```

---

## Lean Proof Strategy

### Step 1: Define the QFT matrix

```lean
def qftMatrix (n : ℕ) : Matrix (Fin (2^n)) (Fin (2^n)) ℂ :=
  fun j k =>
    let ω := Complex.exp (2 * Real.pi * Complex.I / (2^n : ℂ))
    (1 / Real.sqrt (2^n : ℝ) : ℂ) * ω ^ (j.val * k.val)
```

### Step 2: Prove QFT matrix is unitary

```lean
lemma qftMatrix_isUnitary (n : ℕ) : qftMatrix n ∈ Matrix.unitaryGroup (Fin (2^n)) ℂ
```

**Proof sketch:**
- `(qftMatrix n)^* ⬝ qftMatrix n = 1` by the DFT orthogonality relation:
  `Σ_k exp(2πi(j-j')k/N) = N · δ_{jj'}`
- This follows from `Finset.sum_geometric_two_add_one` or a direct root-of-unity sum lemma.

### Step 3: Define the circuit gates

```lean
-- Phase rotation gate
def phaseRotationMatrix (k : ℕ) : Matrix (Fin 2) (Fin 2) ℂ :=
  Matrix.of ![![1, 0], ![0, Complex.exp (2 * Real.pi * Complex.I / (2^k : ℂ))]]

-- Controlled gate embedding
def controlled (U : Matrix (Fin 2) (Fin 2) ℂ) : Matrix (Fin 4) (Fin 4) ℂ := ...

-- Bit-reversal permutation matrix
def bitReversal (n : ℕ) : Matrix (Fin (2^n)) (Fin (2^n)) ℂ := ...
```

### Step 4: Define the QFT circuit

```lean
def qftCircuit (n : ℕ) : Matrix (Fin (2^n)) (Fin (2^n)) ℂ :=
  bitReversal n ⬝ qftCircuitNoSwap n
```

where `qftCircuitNoSwap n` is the product of all H and controlled-R_k gates.

### Step 5: Prove circuit equals QFT matrix

```lean
theorem qft_circuit_correct (n : ℕ) : qftCircuit n = qftMatrix n
```

**Proof approach:**
- **Induction on n**: Base case n=1 is `H = qftMatrix 1` (direct computation).
- **Inductive step**: Show `qftCircuit (n+1)` factors as `(I ⊗ qftCircuit n) ⬝ (Hn stage)` and use `qftMatrix (n+1) = (I ⊗ qftMatrix n) ⬝ (phase stage)`.
- **Alternative**: `Matrix.ext` + entry-wise calculation using geometric sum.

---

## Known Proof Obstacles

1. **Geometric series over `Fin n`**: Need `Σ_{k : Fin N} ω^(j*k) = N * δ_{j,0}` for ω a primitive N-th root of unity. Check if this is in Mathlib (`Finset.geom_sum_eq` or similar).

2. **`Fin (2^(n+1))` ≅ `Fin (2^n) × Fin 2`**: Need a canonical isomorphism to split the tensor product structure. Use `finProdFinEquiv` or `Fin.divNat` / `Fin.modNat`.

3. **Kronecker product reindexing**: `Matrix.kronecker A B` is indexed by `n × m`, not `Fin (n * m)`. Need reindexing lemmas.

4. **`norm_cast` / `push_cast` for `2^n` in ℂ**: Casting `2^n : ℕ` to `ℂ` requires care.

---

## Small Cases First

For confidence, prove the n=1 and n=2 cases explicitly by `norm_num` / `decide`:

```lean
-- n=1: QFT on 1 qubit = Hadamard
example : qftCircuit 1 = qftMatrix 1 := by decide  -- or norm_num + Complex.ext

-- n=2: QFT on 2 qubits
example : qftCircuit 2 = qftMatrix 2 := by native_decide  -- or norm_num
```

---

## Reference: n=2 QFT Circuit Explicitly

For 2 qubits (|q0 q1⟩, q0 = MSB):
1. H on q0
2. Controlled-R_2 (control=q1, target=q0)
3. H on q1
4. SWAP(q0, q1)

Matrix product:
```
SWAP ⬝ (I ⊗ H) ⬝ CR_2 ⬝ (H ⊗ I) = QFT_4
```

where `QFT_4[j,k] = (1/2) · i^{jk}` (since ω = i for N=4).
