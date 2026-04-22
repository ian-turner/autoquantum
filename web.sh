#!/bin/bash
set -e

if [ "$(id -u)" -eq 0 ]; then
    packages_dir="${LEAN_PROJECT_PATH:-/workspace/autoquantum/lean}/.lake/packages"
    mkdir -p /home/opencode/.cache/opencode
    mkdir -p "$packages_dir"
    chown 501:20 /home/opencode/.cache /home/opencode/.cache/opencode "$packages_dir"
    if [ -d /home/opencode/.cache/lake-packages-seed ] && [ ! -e "$packages_dir/mathlib" ]; then
        echo "Seeding writable Lake packages from shared cache"
        quoted_packages_dir="$(printf '%q' "$packages_dir")"
        exec_cmd="cp -a /home/opencode/.cache/lake-packages-seed/. ${quoted_packages_dir}/"
        su -s /bin/bash opencode -c "$exec_cmd"
        quoted_project_dir="$(printf '%q' "${LEAN_PROJECT_PATH:-/workspace/autoquantum/lean}")"
        update_cmd="export PATH=\$HOME/.elan/bin:\$PATH && cd ${quoted_project_dir} && lake update"
        su -s /bin/bash opencode -c "$update_cmd"
    fi
    script_path="$(realpath "$0")"
    exec su -s /bin/bash opencode -c "$(printf '%q ' "$script_path" "$@")"
fi

export PATH="$HOME/.elan/bin:$PATH"
if [ -f "$HOME/.elan/env" ]; then
    . "$HOME/.elan/env"
fi

if [ ! -x "$HOME/.elan/bin/elan" ]; then
    echo "Missing elan cache. Run the cache-warmer service first." >&2
    exit 1
fi

if [ ! -d "${LEAN_PROJECT_PATH:-/workspace/autoquantum/lean}/.lake/packages/mathlib" ]; then
    echo "Missing writable Lake package tree. Run the cache-warmer service first." >&2
    exit 1
fi

# Change to project directory if mounted
if [ -d "${PROJECT_ROOT:-/workspace/autoquantum}" ]; then
    cd "${PROJECT_ROOT:-/workspace/autoquantum}"
    echo "Working directory: $(pwd)"
fi

# Run OpenCode web UI
export OPENCODE_CONFIG="/workspace/autoquantum/opencode.json"
exec opencode web \
    --hostname "${OPENCODE_HOST:-0.0.0.0}" \
    --port "${OPENCODE_PORT:-4096}" \
    --log-level DEBUG \
    "$@"
