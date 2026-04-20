#!/bin/bash
set -e

# Source elan and environment
if [ -f "$HOME/.profile" ]; then
    . "$HOME/.profile"
fi

# If the AutoQuantum project is mounted, change to its directory.
if [ -d "/workspace/autoquantum" ]; then
    cd "/workspace/autoquantum"
fi

# Start the OpenCode HTTP server.
# Default port 4096, host 0.0.0.0; can be overridden via environment variables.
exec opencode serve \
    --hostname "${OPENCODE_HOST:-0.0.0.0}" \
    --port "${OPENCODE_PORT:-4096}" \
    --log-level DEBUG \
    "$@"