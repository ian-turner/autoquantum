# Lean 4 Quantum Computing Landscape

Current state of quantum formalization in Lean 4 / Mathlib, and what AutoQuantum has built on top of it.
Last updated: April 27, 2026 (Mathlib v4.29.0).

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
| `controlPhase α = diag(1, exp(iα))` + unitarity proof | Done | `Core/Gate.lean` (Apr 27, 2026) |
| Rz/Rx/Ry rotation gates + unitarity proofs | **Done** (Apr 26, 2026) | `Core/Gate.lean` |
| CNOT gate + unitarity proof | Done | `Core/Gate.lean` (lint-cleaned Apr 17, 2026) |
| SWAP gate + unitarity proof | Done | `Core/Gate.lean` (lint-cleaned Apr 17, 2026) |
| `applyGate` — gate application to state | Done | `Core/Gate.lean` |
| `tensorWithId`, `idTensorWith`, generic `controlled` | Done | `Core/Gate.lean` |
| `tensorIndexEquiv k m` — canonical tensor basis equivalence | Done | `Core/Tensor.lean` |
| `qubitPerm`, `permuteQubits`, `permuteGate` | Done | `Core/Gate.lean` (Apr 18, 2026) |
| `onQubit`, `hadamardAt`, `phaseRotationAt`, `swapAt`, `bitReverse` | Done | `Core/Gate.lean` (Apr 18, 2026) |
| `onQubits`, `controlledAt`, `controlledPhaseAt` | Done | `Core/Gate.lean` (Apr 18, 2026) |
| `Circuit n` — `List (QGate n)` | Done | `Core/Circuit.lean` |
| `idTensorCircuit`, `tensorWithIdCircuit` — suffix/prefix circuit lifts | Done | `Core/Circuit.lean` |
| `circuitMatrix`, `circuitMatrix_append`, `Circuit.Implements` | Done | `Core/Circuit.lean` |
| `tensorState`, `tensorVec` | **Done** (Apr 19, 2026) | `Core/Hilbert.lean` |
| `hPlusVector`, `hPlusState`, `hPlusCircuit`, `hPlus_correct` (sorry) | Goal | `Goals/HPlus.lean` |
| GHZ state, circuit, `ghz_correct` (sorry) | Goal | `Goals/GHZ.lean` |
| QFT matrix, circuit, `qft_correct` (sorry) | Goal | `Goals/QFT.lean` |
| involution matrix exponential `exp (z • A) = cosh z • I + sinh z • A` | **Done** (Apr 25, 2026) | `Solutions/NC_Ex4_2.lean` |
| Nielsen-Chuang theorem 4.1 single-qubit Z-Y-Z Euler decomposition | **Done** | `Solutions/NC_Thm4_1.lean` |
| Nielsen-Chuang Figure 4.6 controlled-U two-CNOT decomposition | **Done** | `Solutions/NC_Fig4_6.lean` |
| Qubit measurement / Born rule | Future | — |

