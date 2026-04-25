#!/bin/bash
set -euo pipefail

LEAN_TOOLCHAIN="${LEAN_TOOLCHAIN:-leanprover/lean4:v4.29.0}"
LEAN_PROJECT_PATH="${LEAN_PROJECT_PATH:-/workspace/autoquantum/lean}"
ELAN_BIN="${HOME}/.elan/bin"

# Install elan into the mounted cache volume when starting from scratch.
if [ ! -x "$ELAN_BIN/elan" ]; then
    echo "Bootstrapping elan into $HOME/.elan"
    curl -sSf https://raw.githubusercontent.com/leanprover/elan/master/elan-init.sh | sh -s -- -y
fi

if [ -f "$HOME/.profile" ]; then
    . "$HOME/.profile"
fi

# Ensure elan shims are available even when the entrypoint shell is not a login shell.
export PATH="$ELAN_BIN:$PATH"

if ! "$ELAN_BIN/elan" toolchain list | grep -Fq "$LEAN_TOOLCHAIN"; then
    echo "Installing Lean toolchain $LEAN_TOOLCHAIN"
    "$ELAN_BIN/elan" toolchain install "$LEAN_TOOLCHAIN"
fi

"$ELAN_BIN/elan" default "$LEAN_TOOLCHAIN" >/dev/null

if [ -d "$LEAN_PROJECT_PATH" ]; then
    if [ -f "$LEAN_PROJECT_PATH/.lake/packages/mathlib/lakefile.lean" ]; then
        echo "Lean dependencies already present in $LEAN_PROJECT_PATH/.lake/packages"
    else
        echo "Refreshing Lean dependencies in $LEAN_PROJECT_PATH"
        (
            cd "$LEAN_PROJECT_PATH"
            find .lake/packages -mindepth 1 -maxdepth 1 -exec rm -rf {} +
            lake update
            lake exe cache get
        )
    fi
fi
