#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"

export LEAN_PROJECT_PATH="${LEAN_PROJECT_PATH:-$repo_root/lean}"
export LEAN_MCP_DISABLED_TOOLS="${LEAN_MCP_DISABLED_TOOLS:-lean_run_code,lean_build,lean_leanfinder,lean_hammer_premise}"
export LEAN_MCP_INSTRUCTIONS="${LEAN_MCP_INSTRUCTIONS:-Prefer lean_goal, lean_diagnostic_messages, lean_file_outline, lean_local_search, and lean_verify. For Mathlib lemma discovery use lean_loogle (type-based) or lean_leansearch (semantic) — try lean_local_search first. Use lean_state_search to find tactics that close a goal. Keep outputs concise and proof-oriented.}"
export LEAN_REPL="${LEAN_REPL:-true}"
export LEAN_LOOGLE_LOCAL="${LEAN_LOOGLE_LOCAL:-false}"

export PATH="/opt/homebrew/bin:/usr/local/bin:$HOME/.elan/bin:$HOME/.local/bin:$PATH"

if command -v lean-lsp-mcp >/dev/null 2>&1; then
  exec lean-lsp-mcp
fi

if command -v uvx >/dev/null 2>&1; then
  exec uvx lean-lsp-mcp
fi

echo "lean_lsp MCP startup failed: neither lean-lsp-mcp nor uvx was found on PATH." >&2
echo "Install lean-lsp-mcp (preferred) or uv/uvx and retry." >&2
exit 127
