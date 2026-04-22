#!/bin/bash
set -euo pipefail

LEAN_TOOLCHAIN="${LEAN_TOOLCHAIN:-leanprover/lean4:v4.29.0}"
LEAN_PROJECT_PATH="${LEAN_PROJECT_PATH:-/workspace/autoquantum/lean}"

# Install elan into the mounted cache volume when starting from scratch.
if [ ! -x "$HOME/.elan/bin/elan" ]; then
    echo "Bootstrapping elan into $HOME/.elan"
    curl -sSf https://raw.githubusercontent.com/leanprover/elan/master/elan-init.sh | sh -s -- -y
fi

if [ -f "$HOME/.profile" ]; then
    . "$HOME/.profile"
fi

if ! "$HOME/.elan/bin/elan" toolchain list | grep -Fq "$LEAN_TOOLCHAIN"; then
    echo "Installing Lean toolchain $LEAN_TOOLCHAIN"
    "$HOME/.elan/bin/elan" toolchain install "$LEAN_TOOLCHAIN"
fi

"$HOME/.elan/bin/elan" default "$LEAN_TOOLCHAIN" >/dev/null

if [ -d "$LEAN_PROJECT_PATH" ]; then
    echo "Refreshing Lean dependencies in $LEAN_PROJECT_PATH"
    (
        cd "$LEAN_PROJECT_PATH"
        lake update
        lake exe cache get
    )
fi
