/-- Reference solution for the comparator challenge in `Goals/Comm.lean`. -/
theorem comm_goal (n m : Nat) : n + m = m + n := by
  simpa using Nat.add_comm n m
