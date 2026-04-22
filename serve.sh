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

# Command parsing
if [ "$1" = "serve" ]; then
    shift
    exec opencode serve \
        --config "/workspace/autoquantum/opencode.json" \
        --hostname "${OPENCODE_HOST:-0.0.0.0}" \
        --port "${OPENCODE_PORT:-4096}" \
        --log-level DEBUG \
        "$@"
else
    # Run any other opencode command or default to serve
    if [ $# -eq 0 ]; then
        exec opencode serve \
            --config "/workspace/autoquantum/opencode.json" \
            --hostname "${OPENCODE_HOST:-0.0.0.0}" \
            --port "${OPENCODE_PORT:-4096}" \
            --log-level DEBUG
    else
        exec opencode "$@"
    fi
fi