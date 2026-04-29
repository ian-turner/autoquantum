#!/bin/bash
set -e

exec opencode serve \
    --hostname "${OPENCODE_HOST:-0.0.0.0}" \
    --port "${OPENCODE_PORT:-4096}" \
    --log-level DEBUG \
    "$@"
