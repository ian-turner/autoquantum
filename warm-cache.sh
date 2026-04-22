#!/bin/bash
set -e

if [ "$(id -u)" -eq 0 ]; then
    mkdir -p /home/opencode/.elan /workspace/autoquantum/lean/.lake/packages
    chown 501:20 /home/opencode/.elan /workspace/autoquantum/lean/.lake/packages
    script_path="$(realpath "$0")"
    exec su -s /bin/bash opencode -c "$(printf '%q ' "$script_path" "$@")"
fi

export PATH="$HOME/.elan/bin:$PATH"

"$(dirname "$0")/bootstrap-lean.sh"
