# Proof Attempt Log

Running log of approaches tried for each open `sorry`. Use this to brief new agent
sessions so they don't repeat dead ends.

**Format:** one entry per attempt — date, model, approach summary, outcome, blocker.

---

## `HPlus.lean` — `hPlus_correct`

**Statement:**
```lean
theorem hPlus_correct (n : ℕ) :
    runCircuit (hPlusCircuit n) (basisState n 0) = hPlusState n
```

---

### Attempt 1 — 2026-04-20 — opencode/big-pickle (OpenCode default)

**Approach:** Front-qubit induction. Split `hPlusCircuit (1+n)` as `[hadamardAt 0] ++ tail`.
Tried to prove the key lemma `hadamardAt_zero_tensorState` by unfolding
`onQubit → permuteGate (swap last 0) (idTensorWith n hadamard)` and reasoning about
the permutation matrix algebra.

**Outcome:** FAIL — sorry in inductive step. ~6 tactic attempts across 3 rewritten proof
bodies, all ending in `sorry`. The model never used `lean_lsp_lean_goal` (MCP timeout
of 15 s caused tool failures on first call, so the model abandoned interactive tools).

**n=0 base case:** Proved correctly.

**Blocker:** `hadamardAt (0 : Fin (1+n)) = tensorWithId n hadamard` as a gate-matrix
equality. Requires showing `qubitPerm (Equiv.swap (Fin.last n) 0)` maps `e₁(a,b) ↦ e₂(b,a)`
through `finFunctionFinEquiv` — confirmed hard to automate.

**Dead ends (do not retry):**
- Induction on `m` inside the lemma with `simp [onQubit, permuteGate]`
- Coordinate proof via `applyGate_vec_apply` + manual `permuteGate` matrix entry expansion
- Case split on `m = 0 / succ m` with explicit `idTensorWith 0 hadamard = hadamard`

---

### Attempt 2 — recommended next approach

**Strategy: back-qubit induction** — split off the LAST gate instead of the first.

`hadamardAt (Fin.last n)` in an `(n+1)`-qubit system has a trivial permutation:
`Equiv.swap (Fin.last n) (Fin.last n) = Equiv.refl`, so
`permuteGate refl V = V`, giving:

```lean
hadamardAt (Fin.last n) = idTensorWith n hadamard
```

This should close in one or two `simp` calls. Then the induction uses
`idTensorWith_apply` (the companion to the already-proved `tensorWithId_apply`).

**Required new lemmas (in order):**

1. `idTensorWith_apply` in `Lemmas/Tensor.lean`:
   ```lean
   lemma idTensorWith_apply {k m : ℕ} (U : QGate k) (ψ : QState m) (φ : QState k) :
       applyGate (idTensorWith m U) (tensorState ψ φ) = tensorState ψ (applyGate U φ)
   ```
   Pattern: same `Matrix.reindex` + Kronecker entry proof as `tensorWithId_apply`.
   Use `simp_rw` on the matrix entries; `Im a x = if a = x then 1 else 0` by `rfl`.

2. `hadamardAt_last_eq` in `Lemmas/Gate.lean`:
   ```lean
   lemma hadamardAt_last_eq (n : ℕ) :
       hadamardAt (Fin.last n) = idTensorWith n hadamard
   ```
   Proof sketch: `simp [hadamardAt, onQubit, Equiv.swap_self, permuteGate, permuteQubits]`

3. `hPlusVector_succ'` in `Algorithms/HPlus.lean` (split from the right):
   ```lean
   lemma hPlusVector_succ' (n : ℕ) :
       hPlusVector (n + 1) = (tensorState (hPlusState n) (hPlusState 1)).vec
   ```
   Or reuse `hPlusVector_succ` by showing `tensorState` commutes for uniform states.

4. `basisState_zero_tensor'` (split from the right, if needed):
   ```lean
   lemma basisState_zero_tensor' (n : ℕ) :
       basisState (n + 1) 0 = tensorState (basisState n 0) (basisState 1 0)
   ```

5. Circuit tail lemma — the first `n` gates of `hPlusCircuit (n+1)` act only on the
   first `n` qubits. This requires showing the `Fin.castSucc`-embedded hadamards
   correspond to the `n`-qubit circuit lifted via `tensorWithId 1`.

**Pitfall:** `hPlusVector_succ` (already proved) splits as `(1+n)` = `hPlusState 1 ⊗ hPlusState n`.
The back-induction needs `(n+1)` = `hPlusState n ⊗ hPlusState 1`. These are equal by
commutativity of the uniform distribution but `tensorState` is NOT symmetric by
definition — you will need to either prove a commutativity lemma or reprove `hPlusVector_succ'`
directly with the `(n, 1)` split.

---

## `GHZ.lean` — `ghz_correct_one`, `ghz_correct_two`, `ghz_correct`

*(No attempts yet. See home.md for circuit definition.)*

---

## `QFT.lean` — `qft2_correct`, `qft_correct`

*(No attempts yet. See qft-formalization-plan.md and qft-general-proof-obligations.md.)*
