import AutoQuantum.Algorithms.QFT

open AutoQuantum AutoQuantum.QFT Matrix

noncomputable def qftCircuit (n : ℕ) : Circuit n := sorry

/-- The QFT circuit matrix equals the normalized DFT matrix. -/
theorem qft_correct (n : ℕ) :
    (circuitMatrix (qftCircuit n)) = qftMatrix n := by
  sorry
