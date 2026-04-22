#!/bin/bash
set -e

# Source elan and environment
if [ -f "$HOME/.profile" ]; then
    . "$HOME/.profile"
fi

# Change to project directory if mounted
if [ -d "${PROJECT_ROOT:-/workspace/autoquantum}" ]; then
    cd "${PROJECT_ROOT:-/workspace/autoquantum}"
    echo "Working directory: $(pwd)"
fi

# Serve OpenCode over socket
export OPENCODE_CONFIG="/workspace/autoquantum/opencode.json"
exec opencode serve \
    --hostname "${OPENCODE_HOST:-0.0.0.0}" \
    --port "${OPENCODE_PORT:-4096}" \
    --log-level DEBUG \
    "$@"
