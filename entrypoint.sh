#!/bin/bash
set -e

lake_dir="${LEAN_PROJECT_PATH:-/workspace/autoquantum/lean}/.lake"
packages_dir="$lake_dir/packages"
seed_marker="$packages_dir/.seeded-from-cache"
tools_dir="${AUTOQUANTUM_TOOLS_DIR:-/home/opencode/.cache/autoquantum-tools}"
tools_bin="$tools_dir/bin"

if [ "$(id -u)" -eq 0 ]; then
    mkdir -p /home/opencode/.cache/opencode
    mkdir -p "$lake_dir"
    mkdir -p "$packages_dir"
    chown 501:20 /home/opencode/.cache /home/opencode/.cache/opencode "$lake_dir" "$packages_dir"
    if [ -e "$lake_dir/config" ]; then
        chown 501:20 "$lake_dir/config"
    fi
    if [ -d /home/opencode/.cache/lake-packages-seed ] && [ ! -e "$packages_dir/mathlib" ]; then
        echo "Seeding writable Lake packages from shared cache"
        quoted_packages_dir="$(printf '%q' "$packages_dir")"
        exec_cmd="cp -a /home/opencode/.cache/lake-packages-seed/. ${quoted_packages_dir}/"
        su -s /bin/bash opencode -c "$exec_cmd"
        touch "$seed_marker"
        chown 501:20 "$seed_marker"
    fi
    script_path="$(realpath "$0")"
    exec su -s /bin/bash opencode -c "$(printf '%q ' "$script_path" "$@")"
fi

export PATH="$HOME/.elan/bin:$PATH"
if [ -f "$HOME/.elan/env" ]; then
    . "$HOME/.elan/env"
fi
if [ -d "$tools_bin" ]; then
    export PATH="$tools_bin:$PATH"
fi

if [ ! -x "$HOME/.elan/bin/elan" ] || [ ! -d "$packages_dir/mathlib" ]; then
    echo "Bootstrapping Lean toolchain and package cache"
    if ! "$(dirname "$0")/bootstrap-lean.sh"; then
        echo "Lean bootstrap failed. Ensure $HOME/.elan and $packages_dir are writable, or prewarm the shared caches first." >&2
        exit 1
    fi
fi

if [ -f "$seed_marker" ]; then
    (
        cd "${LEAN_PROJECT_PATH:-/workspace/autoquantum/lean}"
        lake update
    )
    rm -f "$seed_marker"
fi

if [ ! -x "$HOME/.elan/bin/elan" ]; then
    echo "Missing elan cache after bootstrap." >&2
    exit 1
fi

if [ ! -d "$packages_dir/mathlib" ]; then
    echo "Missing writable Lake package tree after bootstrap." >&2
    exit 1
fi

if [ -d "${PROJECT_ROOT:-/workspace/autoquantum}" ]; then
    cd "${PROJECT_ROOT:-/workspace/autoquantum}"
    echo "Working directory: $(pwd)"
fi

export OPENCODE_CONFIG="/workspace/autoquantum/opencode.json"
exec opencode serve \
    --hostname "${OPENCODE_HOST:-0.0.0.0}" \
    --port "${OPENCODE_PORT:-4096}" \
    --log-level DEBUG \
    "$@"
