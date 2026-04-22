#!/bin/bash
set -e

# Source elan and environment
if [ -f "$HOME/.profile" ]; then
    . "$HOME/.profile"
fi

# Change to project directory if mounted
if [ -d "${PROJECT_ROOT:-/workspace/project}" ]; then
    cd "${PROJECT_ROOT:-/workspace/project}"
    echo "Working directory: $(pwd)"
fi

# Generate opencode.json from template if template exists
if [ -f "opencode.json.template" ]; then
    echo "Generating opencode.json from template..."
    envsubst < opencode.json.template > opencode.json
    echo "Generated opencode.json with MODEL=${MODEL:-deepseek/deepseek-reasoner}"
fi

# Command parsing
if [ "$1" = "serve" ]; then
    shift
    exec opencode serve \
        --hostname "${OPENCODE_HOST:-0.0.0.0}" \
        --port "${OPENCODE_PORT:-4096}" \
        --log-level DEBUG \
        "$@"
elif [ "$1" = "shell" ]; then
    exec /bin/bash
else
    # Run any other opencode command or default to serve
    exec opencode "$@"
fi