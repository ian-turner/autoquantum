import AutoQuantum.Core.Gate

namespace AutoQuantum

open Complex Matrix


/-- Nielsen and Chuang theorem 4.1: every single-qubit unitary has a `Z-Y-Z`
Euler-angle decomposition, up to a global phase. -/
theorem nc_thm4_1_goal (U : QGate 1) :
    ∃ α β γ δ : ℝ,
      (U : Matrix (Fin 2) (Fin 2) ℂ) =
        Complex.exp (Complex.I * (α : ℂ)) •
          ((rz β * ry γ * rz δ : QGate 1) : Matrix (Fin 2) (Fin 2) ℂ) := by
  sorry

end AutoQuantum
