#!/bin/bash
set -e

tools_dir="${AUTOQUANTUM_TOOLS_DIR:-/home/opencode/.cache/autoquantum-tools}"
lean_packages_dir="${LEAN_PROJECT_PATH:-/workspace/autoquantum/lean}/.lake/packages"

if [ "$(id -u)" -eq 0 ]; then
    mkdir -p /home/opencode/.elan "$lean_packages_dir" "$tools_dir"
    chown 501:20 /home/opencode/.elan "$lean_packages_dir" "$tools_dir"
    script_path="$(realpath "$0")"
    exec su -s /bin/bash opencode -c "$(printf '%q ' "$script_path" "$@")"
fi

export PATH="$HOME/.elan/bin:$PATH"

"$(dirname "$0")/bootstrap-lean.sh"
"$(dirname "$0")/setup_comparator.sh"
