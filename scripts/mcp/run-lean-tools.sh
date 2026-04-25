#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/../.." && pwd)"
server_path="$repo_root/.mcp/lean-tools/server.py"

# Add common locations for lake / elan
export PATH="/opt/homebrew/bin:/usr/local/bin:$HOME/.elan/bin:$HOME/.local/bin:$PATH"
export LEAN_TOOLS_REPO_ROOT="$repo_root"

exec uv run "$server_path"
