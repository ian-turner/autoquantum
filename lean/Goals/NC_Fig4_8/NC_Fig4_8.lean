import AutoQuantum.Core.Circuit

/-!
# Nielsen--Chuang Figure 4.8 goal

This file states the textbook circuit identity implementing a double-controlled
unitary `U` operation using single-controlled `V` operations, where `V^2=U`.

No proof is provided here yet; this is a goal file for later proof-writing work.
-/

open AutoQuantum
open Complex Matrix


/-- The right-hand side circuit in Nielsen--Chuang Figure 4.8.

Gate order (left to right in the figure):
1. Controlled-V:   control = qubit 0 (top),    target = qubit 2 (bottom)
2. CNOT:           control = qubit 0 (top),    target = qubit 1 (middle)
3. Controlled-V†:  control = qubit 1 (middle), target = qubit 2 (bottom)
4. CNOT:           control = qubit 0 (top),    target = qubit 1 (middle)
5. Controlled-V:   control = qubit 1 (middle), target = qubit 2 (bottom) -/
noncomputable def nc_fig4_8_circuit (U : QGate 1) (V : QGate 1)
    (hv : V ^ 2 = U) : Circuit 3 :=
  [ ((controlledAt 0 2 (by decide) V)                    : QGate 3)
  , ((controlledAt 0 1 (by decide) pauliX)               : QGate 3)
  , ((controlledAt 1 2 (by decide) (QGate.dagger V))     : QGate 3)
  , ((controlledAt 0 1 (by decide) pauliX)               : QGate 3)
  , ((controlledAt 1 2 (by decide) V)                    : QGate 3)
  ]

/-- Nielsen--Chuang Figure 4.8 circuit identity.

Stated as a direct matrix product to avoid unfolding `circuitMatrix`/`foldl`
in the proof; the two forms are definitionally equal via
`Circuit.Implements`/`circuitMatrix`. -/
theorem nc_fig4_8_goal (U : QGate 1) (V : QGate 1) (hv : V ^ 2 = U) :
    (controlledAt 0 2 (by decide) V                : QGate 3) *
    (controlledAt 0 1 (by decide) pauliX           : QGate 3) *
    (controlledAt 1 2 (by decide) (QGate.dagger V) : QGate 3) *
    (controlledAt 0 1 (by decide) pauliX           : QGate 3) *
    (controlledAt 1 2 (by decide) V                : QGate 3) =
    controlled (controlled U) := by
  sorry
