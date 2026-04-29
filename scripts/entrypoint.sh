#!/bin/bash
set -e

export PATH="/home/opencode/.elan/bin:/home/opencode/.tools/bin:$PATH"

cd /workspace/autoquantum

export OPENCODE_CONFIG="/workspace/autoquantum/opencode.json"
exec opencode serve \
    --hostname "${OPENCODE_HOST:-0.0.0.0}" \
    --port "${OPENCODE_PORT:-4096}" \
    --log-level DEBUG \
    "$@"
