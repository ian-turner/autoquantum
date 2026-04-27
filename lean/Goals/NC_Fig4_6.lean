import AutoQuantum.Core.Circuit

/-!
# Nielsen--Chuang Figure 4.6 goal

This file states the textbook circuit identity implementing a controlled single-qubit
unitary `U` from one-qubit gates `A`, `B`, `C`, two CNOTs, and a control-wire phase.

No proof is provided here yet; this is a goal file for later proof-writing work.
-/

namespace AutoQuantum

open Complex Matrix

/-- The right-hand side circuit in Nielsen--Chuang Figure 4.6.

The first qubit is the control and the second qubit is the target. The target sees
`C`, then CNOT, then `B`, then CNOT, then `A`; the control wire receives the phase
`diag(1, exp(i α))`. -/
noncomputable def nc_fig4_6_circuit (α : ℝ) (A B C : QGate 1) : Circuit 2 :=
  [ idTensorWith 1 C
  , cnot
  , idTensorWith 1 B
  , cnot
  , idTensorWith 1 A
  , tensorWithId 1 (controlPhase α)
  ]

/-- Nielsen--Chuang Figure 4.6: if `U = exp(i α) A X B X C` and `ABC = I`, then
the decomposed circuit with two CNOTs and one-qubit gates `A`, `B`, `C` implements
the controlled-`U` gate. -/
theorem nc_fig4_6_goal (U A B C : QGate 1) (α : ℝ)
    (hU : (U : Matrix (Fin 2) (Fin 2) ℂ) =
      Complex.exp (Complex.I * (α : ℂ)) •
        ((A * pauliX * B * pauliX * C : QGate 1) : Matrix (Fin 2) (Fin 2) ℂ))
    (hABC : A * B * C = 1) :
    Circuit.Implements (nc_fig4_6_circuit α A B C) (controlled U) := by
  sorry

end AutoQuantum
