#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TOOLS_DIR="${AUTOQUANTUM_TOOLS_DIR:-${ROOT_DIR}/.tools}"
SRC_DIR="${TOOLS_DIR}/src"
BIN_DIR="${TOOLS_DIR}/bin"

COMPARATOR_REF="${COMPARATOR_REF:-v4.29.0}"
LEAN4EXPORT_REF="${LEAN4EXPORT_REF:-v4.29.0}"
LANDRUN_REF="${LANDRUN_REF:-main}"

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    printf 'Missing required command: %s\n' "$1" >&2
    exit 1
  fi
}

clone_or_update() {
  local repo_url="$1"
  local ref="$2"
  local target_dir="$3"

  if [ -d "${target_dir}/.git" ]; then
    git -C "$target_dir" fetch --tags origin
    git -C "$target_dir" reset --hard HEAD
    git -C "$target_dir" clean -fdx
  else
    git clone --branch "$ref" --depth 1 "$repo_url" "$target_dir"
  fi

  git -C "$target_dir" checkout "$ref"
}

pin_comparator_lean4export_ref() {
  local comparator_dir="$1"

  python3 - "$comparator_dir/lakefile.toml" "$LEAN4EXPORT_REF" <<'PY'
from pathlib import Path
import sys

lakefile = Path(sys.argv[1])
ref = sys.argv[2]
lines = lakefile.read_text().splitlines()
updated_lines: list[str] = []
in_require = False
target_block = False
replaced = False

for line in lines:
    stripped = line.strip()
    if stripped == "[[require]]":
        in_require = True
        target_block = False
        updated_lines.append(line)
        continue
    if in_require and stripped.startswith("[[") and stripped != "[[require]]":
        in_require = False
        target_block = False
    if in_require and stripped == 'name = "lean4export"':
        target_block = True
        updated_lines.append(line)
        continue
    if target_block and stripped.startswith('rev = "'):
        updated_lines.append(f'rev = "{ref}"')
        replaced = True
        target_block = False
        continue
    updated_lines.append(line)

if not replaced:
    raise SystemExit("failed to pin comparator's lean4export dependency")

lakefile.write_text("\n".join(updated_lines) + "\n")
PY

  rm -f "${comparator_dir}/lake-manifest.json"
  rm -rf "${comparator_dir}/.lake"
}

build_lean_repo() {
  local repo_dir="$1"
  local binary_name="$2"

  lake --dir "$repo_dir" update
  if [ -f "${repo_dir}/lake-manifest.json" ] || grep -q 'mathlib' "${repo_dir}/lakefile.toml" 2>/dev/null || grep -q 'mathlib' "${repo_dir}/lakefile.lean" 2>/dev/null; then
    lake --dir "$repo_dir" exe cache get || true
  fi
  lake --dir "$repo_dir" build
  cp "${repo_dir}/.lake/build/bin/${binary_name}" "${BIN_DIR}/${binary_name}"
}

mkdir -p "$SRC_DIR" "$BIN_DIR"

require_cmd git
require_cmd lean
require_cmd lake

clone_or_update "https://github.com/leanprover/lean4export.git" "$LEAN4EXPORT_REF" "${SRC_DIR}/lean4export"
build_lean_repo "${SRC_DIR}/lean4export" lean4export

clone_or_update "https://github.com/leanprover/comparator.git" "$COMPARATOR_REF" "${SRC_DIR}/comparator"
pin_comparator_lean4export_ref "${SRC_DIR}/comparator"
build_lean_repo "${SRC_DIR}/comparator" comparator

if command -v go >/dev/null 2>&1; then
  clone_or_update "https://github.com/Zouuup/landrun.git" "$LANDRUN_REF" "${SRC_DIR}/landrun"
  (
    cd "${SRC_DIR}/landrun"
    go build -o "${BIN_DIR}/landrun" cmd/landrun/main.go
  )
else
  printf 'warning: go is not installed; skipping landrun build\n' >&2
fi

cat <<EOF
Comparator helper binaries were installed under:
  ${BIN_DIR}

Add them to PATH before running verification:
  export PATH="${BIN_DIR}:\$PATH"

Then verify the sample goal with:
  python3 scripts/verify_comparator.py --goal Comm
EOF
