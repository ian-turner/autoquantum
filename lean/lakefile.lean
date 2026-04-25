import Lake
open Lake DSL

package «AutoQuantum» where
  name := "AutoQuantum"

require mathlib from git
  "https://github.com/leanprover-community/mathlib4" @ "v4.29.0"

require repl from git
  "https://github.com/leanprover-community/repl" @ "v4.29.0"

lean_lib «AutoQuantum» where
  globs := #[.andSubmodules `AutoQuantum]

lean_lib Goals where
  globs := #[.submodules `Goals]

lean_lib Solutions where
  globs := #[.submodules `Solutions]
