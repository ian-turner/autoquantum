#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/../.." && pwd)"

export LEAN_PROJECT_PATH="$repo_root/lean"
export LEAN_MCP_DISABLED_TOOLS="${LEAN_MCP_DISABLED_TOOLS:-lean_run_code,lean_build,lean_leansearch,lean_loogle,lean_leanfinder,lean_state_search,lean_hammer_premise}"
export LEAN_MCP_INSTRUCTIONS="${LEAN_MCP_INSTRUCTIONS:-Prefer lean_goal, lean_diagnostic_messages, lean_file_outline, lean_local_search, and lean_verify. Use remote search tools only after local search fails. Keep outputs concise and proof-oriented.}"

exec uvx lean-lsp-mcp
