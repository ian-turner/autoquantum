import Lake
open Lake DSL

package «AutoQuantum» where
  name := "AutoQuantum"

require mathlib from git
  "https://github.com/leanprover-community/mathlib4" @ "master"

lean_lib «AutoQuantum» where
  globs := #[.andSubmodules `AutoQuantum]
