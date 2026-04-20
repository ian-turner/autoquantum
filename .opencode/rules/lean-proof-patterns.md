# Lean 4 Proof Patterns — AutoQuantum

Confirmed-working patterns against Mathlib v4.29.0 + AutoQuantum types.
Copy these exactly; small deviations cause hard-to-diagnose failures.

---

## Tensor-product coordinate proofs

### Pattern 1: Always use abstract types for tensorVec lemmas

`change` fails when `ψ` or `φ` is a concrete term (e.g. `hPlusState 1`) because Lean
reduces it during definitional equality checking. State all tensor coordinate lemmas with
abstract `ψ : QHilbert k`, `φ : QHilbert m`, then instantiate.

```lean
-- ✅ correct
lemma myLemma {k m : ℕ} (ψ : QHilbert k) (φ : QHilbert m) (a : Fin (2^k)) (b : Fin (2^m)) :
    tensorVec ψ φ (e (a, b)) = ψ a * φ b := tensorVec_apply ψ φ a b

-- ❌ fails: `change` mismatches on concrete hPlusState
```

When bridging `.vec` to `tensorVec`, use `show`:
```lean
have hten : (tensorState ψ φ).vec (e (a, b)) = ψ.vec a * φ.vec b := by
  show tensorVec ψ.vec φ.vec (e (a, b)) = _
  exact tensorVec_apply _ _ a b
```

### Pattern 2: `subst` before `simp` for case hypotheses

`simp [ha]` where `ha : a = 0` does not reliably substitute inside complex expressions.
Always `subst ha` first to eliminate the variable everywhere.

```lean
-- ❌ unreliable
simp [ha, hb, this]

-- ✅ correct
subst ha   -- eliminates `a` everywhere in goal
simp [hb, this]
```

### Pattern 3: Product surjection destructuring

`e.surjective j` yields `∃ p : A × B, e p = j` — use nested angle brackets.

```lean
-- ✅ correct
obtain ⟨⟨a, b⟩, rfl⟩ := e.surjective j

-- ❌ wrong — Lean sees ∃ p : A×B, not ∃ a b
obtain ⟨a, b, rfl⟩ := e.surjective j
```

### Pattern 4: Standard tensor equivalence `e`

Define `e` once and use it throughout the file. The `symm` is required because
`pow_add` states `2^(k+m) = 2^k * 2^m` but `finCongr` needs the equality the other way.

```lean
let e : Fin (2 ^ k) × Fin (2 ^ m) ≃ Fin (2 ^ (k + m)) :=
  finProdFinEquiv.trans (finCongr (pow_add 2 k m).symm)
```

---

## Gate placement and `onQubit` / `permuteGate` proofs

### The `onQubit` definition (for `n = succ m`)

```
onQubit (q : Fin (m+1)) U = permuteGate (Equiv.swap (Fin.last m) q) (idTensorWith m U)
```

where:
- `idTensorWith m U : QGate (m+1)` = `I_{2^m} ⊗ U` (identity on first m qubits, U on the last)
- `permuteGate σ V = permuteQubits σ⁻¹ * V * permuteQubits σ`
- `qubitPerm σ` permutes the basis-index representation by composing bit-strings with σ⁻¹

### Key identity: `hadamardAt (Fin.last n)` is trivial

When `q = Fin.last m`, the swap is `Equiv.swap (Fin.last m) (Fin.last m) = Equiv.refl`.
`permuteGate Equiv.refl V = V` (the permutation is the identity). Therefore:

```lean
hadamardAt (Fin.last n) = idTensorWith n hadamard
```

This means the LAST hadamard in `hPlusCircuit (n+1)` is exactly `idTensorWith n hadamard`,
which acts on the tensor product as `applyGate (idTensorWith n U) (tensorState ψ φ) = tensorState ψ (applyGate U φ)`.

### For `hadamardAt 0`: the permutation is non-trivial

`hadamardAt (0 : Fin (1+m))` = `permuteGate (swap last 0) (idTensorWith m hadamard)`.
The permutation `swap(last, 0)` swaps qubit positions 0 and m, which in the product basis
corresponds to swapping the first and last tensor factors. The gate is mathematically equal
to `tensorWithId m hadamard` (i.e., `H ⊗ I_m`), but proving the matrix equality requires
working through `qubitPerm` and `finFunctionFinEquiv` — which is non-trivial.

**Easier alternative**: induct from the back of the circuit (splitting off `hadamardAt (Fin.last n)`)
and use `idTensorWith_apply` rather than dealing with the front-qubit permutation.

### `permuteGate refl` simplification

```lean
-- permuteGate refl V = V
have : Equiv.swap (Fin.last n) (Fin.last n) = Equiv.refl _ := Equiv.swap_self _
simp [permuteGate, permuteQubits, this]
-- or: simp [permuteGate, Equiv.swap_self]
```

### Matrix-entry approach for `onQubit` proofs

When proving `applyGate (onQubit q U) ψ = ...` by matrix entries:

1. `Subtype.ext` to get to vectors
2. `ext i`, `obtain ⟨⟨a, b⟩, rfl⟩ := e.surjective i`
3. `rw [applyGate_vec_apply]`
4. Reindex the sum via `Fintype.sum_equiv e`
5. Compute `(permuteGate σ V)_{e(a,b), e(x,y)} = V_{qubitPerm σ (e(a,b)), qubitPerm σ (e(x,y))}`
6. Show `qubitPerm (swap last 0) (e₁(a, b)) = e₂(b, a)` using `finFunctionFinEquiv` unpacking

---

## Circuit decomposition patterns

### Splitting `hPlusCircuit (n+1)` at the front

```lean
-- hPlusCircuit (1+n) = [⟨hadamardAt 0⟩] ++ rest
simp only [hPlusCircuit, List.finRange_succ, List.map, List.cons_append]
rw [runCircuit, circuitMatrix_append, applyGate_mul]
```

### Splitting at the back (easier — avoids the permutation problem)

```lean
-- hPlusCircuit (n+1) ends with hadamardAt (Fin.last n) = idTensorWith n hadamard
-- Use List.getLast / List.dropLast or List.finRange_castSucc decomposition
```

### `circuitMatrix` of a list-map circuit

```lean
-- circuitMatrix ((List.finRange n).map f) for small n: use circuitMatrix_singleton + circuitMatrix_append
-- For n=0: circuitMatrix_nil gives the identity
-- For n=1: simp [hPlusCircuit, List.finRange_one, circuitMatrix_singleton]
```

---

## Pitfalls (high frequency)

| # | Issue | Fix |
|---|-------|-----|
| P1 | `simp` on `onQubit` / `onQubits` can leave `Nat.casesAuxOn` stuck | Use `change` to the explicit `permuteGate` form, then work entrywise |
| P2 | `lean_check_file` times out mid-proof | Use `lean_lsp_lean_diagnostic_messages` instead; only call `lean_check_file` after finishing |
| P3 | LSP tools need absolute paths | Use `lean_proof_step` to resolve; pattern: `/workspace/autoquantum/lean/AutoQuantum/...` |
| P4 | `⊗ₖ` notation not in scope | Add `open scoped Kronecker` in every file that uses it |
| P5 | `finCongr` takes the wrong direction | `finCongr (pow_add 2 k m).symm` not `(pow_add 2 k m)` |
| P6 | `PiLp.norm_single` replaces deprecated `EuclideanSpace.norm_single` | |
| P7 | `import` statements must come before doc comments (`/-! ... -/`) | |
| P8 | `Matrix.mulVec` cannot accept `EuclideanSpace` directly | Bridge via `Matrix.toEuclideanLin` |
| P9 | `conj` in `open Complex` context shadows the function | Use `star` instead |
| P10 | `obtain ⟨a, b, rfl⟩ := e.surjective j` fails silently | Use nested `⟨⟨a, b⟩, rfl⟩` |
