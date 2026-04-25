#!/bin/bash
set -e

tools_dir="${AUTOQUANTUM_TOOLS_DIR:-/home/opencode/.cache/autoquantum-tools}"

if [ "$(id -u)" -eq 0 ]; then
    mkdir -p /home/opencode/.elan /workspace/autoquantum/lean/.lake/packages "$tools_dir"
    chown 501:20 /home/opencode/.elan /workspace/autoquantum/lean/.lake/packages "$tools_dir"
    script_path="$(realpath "$0")"
    exec su -s /bin/bash opencode -c "$(printf '%q ' "$script_path" "$@")"
fi

export PATH="$HOME/.elan/bin:$PATH"

"$(dirname "$0")/bootstrap-lean.sh"
"$(dirname "$0")/scripts/setup_comparator.sh"
