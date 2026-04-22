#!/bin/bash
set -e

if [ "$(id -u)" -eq 0 ]; then
    mkdir -p /home/opencode/.elan /home/opencode/.cache/opencode /workspace/autoquantum/lean/.lake/packages
    chown 501:20 /home/opencode/.elan /home/opencode/.cache /home/opencode/.cache/opencode /workspace/autoquantum/lean/.lake/packages
    script_path="$(realpath "$0")"
    exec su -s /bin/bash opencode -c "$(printf '%q ' "$script_path" "$@")"
fi

# Source elan and environment
if [ -f "$HOME/.profile" ]; then
    . "$HOME/.profile"
fi

"$(dirname "$0")/bootstrap-lean.sh"

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
