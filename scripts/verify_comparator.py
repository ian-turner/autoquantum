#!/usr/bin/env python3
"""Run comparator against Goals/*/comparator.json configs."""

from __future__ import annotations

import argparse
import os
import shutil
import subprocess
import sys
from pathlib import Path


LEAN_DIR = Path(__file__).resolve().parent.parent / "lean"
TOOLS_DIRS = [Path("/home/opencode/.tools"), Path(__file__).resolve().parent.parent / ".tools"]


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Verify Lean proof challenges using Goals/*/comparator.json configs."
    )
    parser.add_argument("--goal", action="append", default=[], help="Limit to a specific goal folder name. Can be repeated.")
    parser.add_argument("--list-goals", action="store_true", help="Print discovered goals and exit.")
    parser.add_argument("--fail-fast", action="store_true", help="Stop after the first failure.")
    return parser.parse_args()


def discover_configs(selected: set[str]) -> list[tuple[str, Path]]:
    configs = []
    for config_path in sorted((LEAN_DIR / "Goals").glob("*/comparator.json")):
        name = config_path.parent.name
        if selected and name not in selected:
            continue
        configs.append((name, config_path))
    return configs


def resolve_comparator_binary() -> Path:
    if env_bin := os.environ.get("COMPARATOR_BIN"):
        return Path(env_bin)
    if which_bin := shutil.which("comparator"):
        return Path(which_bin)
    for tools_dir in TOOLS_DIRS:
        for candidate in [
            tools_dir / "bin" / "comparator",
            tools_dir / "src" / "comparator" / ".lake" / "build" / "bin" / "comparator",
        ]:
            if candidate.is_file():
                return candidate
    raise SystemExit("comparator binary not found")


def build_env() -> dict[str, str]:
    extra: list[str] = []
    for tools_dir in TOOLS_DIRS:
        extra += [
            str(tools_dir / "bin"),
            str(tools_dir / "src" / "lean4export" / ".lake" / "build" / "bin"),
            str(tools_dir / "src" / "comparator" / ".lake" / "build" / "bin"),
            str(tools_dir / "src" / "comparator" / ".lake" / "packages" / "lean4export" / ".lake" / "build" / "bin"),
        ]
    env = os.environ.copy()
    env["PATH"] = os.pathsep.join(extra + [env.get("PATH", "")])
    return env


def run_goal(config_path: Path, comparator_bin: Path, env: dict[str, str]) -> tuple[bool, str]:
    completed = subprocess.run(
        ["lake", "env", str(comparator_bin), str(config_path)],
        cwd=LEAN_DIR,
        env=env,
        text=True,
        capture_output=True,
    )
    transcript = (completed.stdout or "") + (completed.stderr or "")
    if completed.returncode == 0:
        return True, transcript.strip()
    return False, transcript.strip() or f"comparator exited with status {completed.returncode}"


def main() -> int:
    args = parse_args()
    configs = discover_configs(set(args.goal))

    if not configs:
        print("No comparator goals found.", file=sys.stderr)
        return 1

    if args.list_goals:
        for name, _ in configs:
            print(name)
        return 0

    comparator_bin = resolve_comparator_binary()
    env = build_env()
    print(f"Using comparator: {comparator_bin}")

    failures: list[str] = []
    for name, config_path in configs:
        print(f"\n==> {name}")
        ok, message = run_goal(config_path, comparator_bin, env)
        print("PASS" if ok else "FAIL")
        if message:
            print(message)
        if not ok:
            failures.append(name)
            if args.fail_fast:
                break

    if failures:
        print(f"\nFailed: {', '.join(failures)}", file=sys.stderr)
        return 1

    print("\nAll goals passed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
