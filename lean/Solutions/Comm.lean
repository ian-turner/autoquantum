/-- Reference solution for the comparator challenge in `Goals/Comm.lean`. -/
theorem comm_goal (n m : Nat) : n + m = m + n :=
  Nat.add_comm n m 
