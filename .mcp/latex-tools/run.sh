#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/../.." && pwd)"

# Prepend MacTeX (macOS) — on Linux, latexmk is already in $PATH via apt
export PATH="/Library/TeX/texbin:/opt/homebrew/bin:/usr/local/bin:$PATH"
export LATEX_TOOLS_REPO_ROOT="$repo_root"

exec uv run "$(dirname "$0")/server.py"
