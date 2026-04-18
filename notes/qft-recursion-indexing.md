# QFT Recursion Indexing

Notes from the April 18, 2026 proof pass on the general-case QFT theorem in
`lean/AutoQuantum/Algorithms/QFT.lean`.

## Main Finding

The existing recursive scaffolding in `QFT.lean` distinguishes two different
ways to enlarge an `n`-qubit system to `n+1` qubits:

- `liftGate` / `liftCircuit` use `I₂ ⊗ U`, implemented with the index split
  `b * 2^n + i`. This adds a new **most-significant** qubit.
- the raw recursive QFT layers in `qftCircuit (n+1)` are indexed by
  `target.succ`. That shift is the shape you get when the old qubits move up by
  one index, i.e. when the new qubit is inserted at the **least-significant**
  end.

Those are different embeddings.

## Why This Matters

The first serious unfinished attempt at `qft_correct` assumed the target-`1..n`
layers in `qftCircuit (n+1)` should match a lifted `qftCircuit n` via the
existing `liftGate` / `liftCircuit` infrastructure. During this session, an
attempted lemma of the form

```lean
hadamardAt q.succ = liftGate (hadamardAt q)
```

did **not** simplify to the expected block-diagonal form. The obstruction is
not just a missing rewrite lemma; it reflects the wrong embedding direction.

The more plausible recursive bridge is now:

```lean
tensorWithId 1
```

not

```lean
idTensorWith 1
```

for the `target.succ` layers.

## Code Change Made

This session added:

- `qftLayers : Circuit n`

which stores the decomposed QFT gate layers **without** the final
`bitReverse`. The public circuit definition is now

```lean
qftCircuit n = qftLayers n ++ [⟨bitReverse⟩]
```

This is a useful normalization regardless of the final inductive proof shape,
because it separates the recursive gate layers from the final permutation.

## Expected Next Step

The next proof pass should likely introduce a second embedding helper based on
`tensorWithId 1` and prove shifted-placement lemmas against that embedding:

- `hadamardAt q.succ`
- `controlledPhaseAt control.succ target.succ`
- the corresponding circuit-level map for `qftLayers`

Only after that should the general inductive step be reorganized.
