# Lean 4 Quantum Computing Landscape

Current state of quantum formalization in Lean 4 / Mathlib (as of April 2026).

---

## What Mathlib Already Provides

### Linear Algebra
- `Matrix (n m : Type) R` — matrices over a ring R
- `Matrix.unitaryGroup n R` — unitary group U(n, R)
- `Matrix.IsHermitian` — Hermitian matrices
- `Matrix.IsUnitary` — unitary matrices
- `Matrix.kroneckerMap` / `Matrix.kronecker` — Kronecker (tensor) product
- `Matrix.trace`, `Matrix.det`, `Matrix.rank`

### Inner Product Spaces
- `InnerProductSpace 𝕜 E` — inner product space over field 𝕜
- `EuclideanSpace 𝕜 n` — standard finite-dimensional inner product space (= `PiLp 2 (fun _ : n => 𝕜)`)
- `EuclideanSpace.single i c` — basis vector e_i scaled by c
- `orthonormalBasis` — orthonormal bases
- `Finset.sum` over basis for decomposition

### Complex Numbers
- `Complex.exp`, `Complex.abs`, `Complex.normSq`
- `Complex.I` — imaginary unit
- `Real.sqrt`, `Real.pi`
- `Complex.exp_mul_I` — Euler's formula

### Analysis
- `ContinuousLinearMap`, operator norms
- `Spectrum` — spectrum of operators (for eigenvalue reasoning)

---

## What LeanQuantum Provides (inQWIRE)

- Gate definitions as `Matrix.unitaryGroup (Fin (2^n)) ℂ`
- Pauli gates X, Y, Z and Hadamard H
- Proofs: H²=I, X²=I, Y²=I, Z²=I
- Hermiticity of Pauli and Hadamard gates
- Some composition lemmas

**Gaps:** No circuit type, no multi-qubit gates (CNOT, Toffoli), no algorithm proofs.

---

## What Lean-QuantumInfo Provides (Timeroot)

- Quantum states as density matrices and pure states
- Partial trace, tensor products
- Quantum channels
- Various quantum information inequalities

**Gaps:** Less focused on circuit gate sets; more on information-theoretic quantities.

---

## What AutoQuantum Needs to Add

| Feature | Status | Notes |
|---------|--------|-------|
| `QState n` type (unit vectors) | To build | Wrap `EuclideanSpace ℂ (Fin (2^n))` with norm = 1 |
| Gate application | To build | `Matrix.mulVec`, norm preservation proof |
| CNOT gate | To build | 4×4 unitary matrix |
| Controlled-U gates | To build | General construction |
| Phase rotation R_k | To build | `diag [1, exp(2πi/2^k)]` |
| Circuit as list | To build | `List (GateApplication n)` |
| Circuit composition | To build | Sequential application |
| Parallel (tensor) composition | To build | Kronecker product of gate matrices |
| QFT circuit definition | To build | Standard gate decomposition |
| QFT correctness theorem | To build | QFT_matrix = DFT_matrix / sqrt(2^n) |
| Qubit measurement | Future | Partial trace / Born rule |

---

## Recommended Approach

### State Representation
Use `EuclideanSpace ℂ (Fin (2^n))` directly (not wrapped in a structure) where possible — this avoids coercion friction when using Mathlib lemmas. When a normalized state is specifically needed, use a `Subtype`:

```lean
def QState (n : ℕ) := {v : EuclideanSpace ℂ (Fin (2^n)) // ‖v‖ = 1}
```

### Gate Representation
Use `unitaryGroup (Fin (2^n)) ℂ` for semantic correctness. For defining specific gates, construct the matrix first, prove it is unitary, then package into the subtype:

```lean
def hadamardMatrix : Matrix (Fin 2) (Fin 2) ℂ := ...
lemma hadamardMatrix_isUnitary : hadamardMatrix ∈ Matrix.unitaryGroup (Fin 2) ℂ := ...
def hadamard : QGate 1 := ⟨hadamardMatrix, hadamardMatrix_isUnitary⟩
```

### Circuits
Represent a circuit as:
```lean
inductive CircuitStep (n : ℕ) where
  | gate : QGate k → Fin n → CircuitStep n   -- apply k-qubit gate at qubit index
  | tensor : QGate j → QGate k → CircuitStep (j + k)

def Circuit (n : ℕ) := List (CircuitStep n)
```

For the QFT proof, it may be simpler to represent the circuit directly as a matrix product and prove equality to the DFT matrix.

---

## Potential Issues

1. **`2^n` in index types**: Lean needs `2^n` to reduce for `Fin (2^n)` to be usable. Use `Nat.pow` carefully; `decide` tactics work for fixed small n.
2. **`EuclideanSpace` vs `Matrix.mulVec`**: `EuclideanSpace ℂ (Fin n)` is `PiLp 2 (...)`, not `Fin n → ℂ`. You need `EuclideanSpace.equiv` or `WithLp.equiv` to bridge to raw function types for `mulVec`.
3. **Kronecker product indices**: `Matrix.kroneckerMap` gives a matrix indexed by `n × m`, not `Fin (n * m)`. Use `Fin.divNat` / `Fin.modNat` or `Fintype.equivFin` to reindex.
4. **Complex number goals**: `norm_num` handles many but not all complex arithmetic goals; `simp [Complex.ext_iff]` + `ring` often needed.
