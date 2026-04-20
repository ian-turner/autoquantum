# Gate Embedding Patterns

Reusable proof and definition patterns from the completed gate-embedding work in `Core/Gate.lean`.

## Tensor Embeddings

To lift a `k`-qubit gate to the first `k` qubits of a `(k+m)`-qubit system:

```lean
let e : Fin (2 ^ k) × Fin (2 ^ m) ≃ Fin (2 ^ (k + m)) :=
  finProdFinEquiv.trans <|
    finCongr (show 2 ^ k * 2 ^ m = 2 ^ (k + m) by rw [pow_add])

Matrix.reindex e e ((U : Matrix _ _ ℂ) ⊗ₖ (1 : Matrix _ _ ℂ))
```

For lifting onto the last `k` qubits, swap the product order and use `I ⊗ U`.

## Unitarity Preservation

The reusable helper is:

```lean
lemma reindex_mem_unitaryGroup ...
```

Proof shape:

1. Open `Matrix.mem_unitaryGroup_iff`.
2. Apply `congrArg (Matrix.reindex e e)` to the equality `A * star A = 1`.
3. Simplify with `Matrix.conjTranspose_reindex`.

This avoids reproving unitarity entrywise after every reindexing step.

## Controlled Gates

For a single-qubit `U`, define the controlled gate first on `Fin 2 ⊕ Fin 2`:

```lean
let CU : Matrix (Fin 2 ⊕ Fin 2) (Fin 2 ⊕ Fin 2) ℂ :=
  Matrix.fromBlocks (1 : Matrix (Fin 2) (Fin 2) ℂ) 0 0 U
```

Then reindex with `finSumFinEquiv` to reach `Fin 4`.

The block-diagonal unitarity proof is easiest if you convert
`U * star U = 1` into `U * Uᴴ = 1` first:

```lean
have hU' : U * star U = 1 := ...
have hU'' : U * Uᴴ = 1 := by
  simpa [Matrix.star_eq_conjTranspose] using hU'
```

After that, `Matrix.fromBlocks_conjTranspose` and `Matrix.fromBlocks_multiply` reduce the goal to
`fromBlocks 1 0 0 1 = 1`.

## Basis Order

`finProdFinEquiv` matches the current basis-order convention:

- the left factor is the more significant register
- the right factor is the less significant register

For two qubits this is the repository's `|00⟩, |01⟩, |10⟩, |11⟩` ordering, so the Kronecker-based
embeddings line up with `cnotMatrix` and `swapMatrix` without extra permutation lemmas.
