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

The first and last controlled-V gates apply V when each control wire is one.
The CNOT and controlled-V-dagger structure in the middle inverts the V
applied when only one of the controls is one. -/
noncomputable def nc_fig4_8_circuit (U : QGate 1) (V : QGate 1)
    (hv : V * V = U) : Circuit 3 :=
  [ ((controlledAt 1 2 (by decide) V) : QGate 3)
  , ((controlledAt 0 1 (by decide) pauliX) : QGate 3)
  , ((controlledAt 1 2 (by decide) (QGate.dagger V)) : QGate 3)
  , ((controlledAt 0 1 (by decide) pauliX) : QGate 3)
  , ((controlledAt 0 2 (by decide) V) : QGate 3)
  ]

/-- Nielsen--Chuang Figure 4.8 circuit identity -/
theorem nc_fig4_8_goal (U : QGate 1) (V : QGate 1) (hv : V * V = U) :
    Circuit.Implements (nc_fig4_8_circuit U V hv) (controlled (controlled U)) := by
  sorry
