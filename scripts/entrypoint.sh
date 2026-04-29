#!/bin/bash
set -e

# Re-exec as opencode user if running as root
if [ "$(id -u)" -eq 0 ]; then
    mkdir -p /home/opencode/.cache/opencode
    chown 501:20 /home/opencode/.cache /home/opencode/.cache/opencode
    script_path="$(realpath "$0")"
    exec su -s /bin/bash opencode -c "$(printf '%q ' "$script_path" "$@")"
fi

export PATH="/home/opencode/.elan/bin:/home/opencode/.tools/bin:$PATH"

cd "${PROJECT_ROOT:-/workspace/autoquantum}"

export OPENCODE_CONFIG="/workspace/autoquantum/opencode.json"
exec opencode serve \
    --hostname "${OPENCODE_HOST:-0.0.0.0}" \
    --port "${OPENCODE_PORT:-4096}" \
    --log-level DEBUG \
    "$@"
