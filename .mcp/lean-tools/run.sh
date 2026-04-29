#!/usr/bin/env bash
set -euo pipefail

server_path="$(cd "$(dirname "$0")" && pwd)/server.py"

# Add common locations for lake / elan
export PATH="/opt/homebrew/bin:/usr/local/bin:$HOME/.elan/bin:$HOME/.local/bin:$PATH"

exec uv run "$server_path"
