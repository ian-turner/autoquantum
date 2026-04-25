#!/usr/bin/env python3
"""Run comparator against the repo's Goals/Solutions proof pairs."""

from __future__ import annotations

import argparse
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile
from dataclasses import dataclass
from pathlib import Path


DEFAULT_PERMITTED_AXIOMS = ["propext", "Quot.sound", "Classical.choice"]


@dataclass(frozen=True)
class GoalPair:
    stem: str
    goal_file: Path
    solution_file: Path

    @property
    def theorem_name(self) -> str:
        return stem_to_theorem(self.stem)

    @property
    def challenge_module(self) -> str:
        return f"Goals.{self.stem}"

    @property
    def solution_module(self) -> str:
        return f"Solutions.{self.stem}"


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Verify Lean proof challenges in lean/Goals against lean/Solutions using comparator."
    )
    parser.add_argument(
        "--goal",
        action="append",
        default=[],
        help="Limit verification to a specific goal stem (for example: Comm). Can be repeated.",
    )
    parser.add_argument(
        "--list-goals",
        action="store_true",
        help="Print discovered goal stems and exit.",
    )
    parser.add_argument(
        "--comparator",
        type=Path,
        default=None,
        help="Path to the comparator binary. Defaults to COMPARATOR_BIN, PATH, or .tools/bin/comparator.",
    )
    parser.add_argument(
        "--lean-dir",
        type=Path,
        default=None,
        help="Lean project directory. Defaults to <repo>/lean.",
    )
    parser.add_argument(
        "--permitted-axiom",
        action="append",
        default=None,
        help="Permit an extra axiom name. Repeat for multiple axioms.",
    )
    parser.add_argument(
        "--enable-nanoda",
        action="store_true",
        help="Enable comparator's additional nanoda kernel check.",
    )
    parser.add_argument(
        "--fail-fast",
        action="store_true",
        help="Stop after the first failed goal.",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Print what would be verified without invoking comparator.",
    )
    return parser.parse_args()


def repo_root() -> Path:
    return Path(__file__).resolve().parent.parent


def stem_to_theorem(stem: str) -> str:
    first_pass = re.sub(r"(.)([A-Z][a-z]+)", r"\1_\2", stem)
    second_pass = re.sub(r"([a-z0-9])([A-Z])", r"\1_\2", first_pass)
    return f"{second_pass.lower()}_goal"


def discover_pairs(lean_dir: Path, selected_goals: set[str]) -> list[GoalPair]:
    goals_dir = lean_dir / "Goals"
    solutions_dir = lean_dir / "Solutions"
    if not goals_dir.is_dir():
        raise SystemExit(f"Goals directory not found: {goals_dir}")
    if not solutions_dir.is_dir():
        raise SystemExit(f"Solutions directory not found: {solutions_dir}")

    pairs: list[GoalPair] = []
    goal_files = sorted(goals_dir.glob("*.lean"))
    for goal_file in goal_files:
        stem = goal_file.stem
        if selected_goals and stem not in selected_goals:
            continue
        solution_file = solutions_dir / goal_file.name
        pairs.append(GoalPair(stem=stem, goal_file=goal_file, solution_file=solution_file))
    return pairs


def tool_dir_candidates(root: Path) -> list[Path]:
    candidates: list[Path] = []
    if env_dir := os.environ.get("AUTOQUANTUM_TOOLS_DIR"):
        candidates.append(Path(env_dir).expanduser())
    candidates.append(Path("/home/opencode/.cache/autoquantum-tools"))
    candidates.append(root / ".tools")
    deduped: list[Path] = []
    seen: set[Path] = set()
    for candidate in candidates:
        resolved = candidate.expanduser()
        if resolved in seen:
            continue
        seen.add(resolved)
        deduped.append(resolved)
    return deduped


def resolve_comparator_binary(root: Path, requested: Path | None) -> Path:
    candidates: list[Path] = []
    if requested is not None:
        candidates.append(requested.expanduser())
    if env_bin := os.environ.get("COMPARATOR_BIN"):
        candidates.append(Path(env_bin).expanduser())
    if which_bin := shutil.which("comparator"):
        candidates.append(Path(which_bin))
    for tools_dir in tool_dir_candidates(root):
        candidates.extend(
            [
                tools_dir / "bin" / "comparator",
                tools_dir / "src" / "comparator" / ".lake" / "build" / "bin" / "comparator",
            ]
        )
    for candidate in candidates:
        if candidate.is_file():
            return candidate
    search_list = "\n  - ".join(str(path) for path in candidates)
    raise SystemExit(
        "Comparator binary not found. Checked:\n"
        f"  - {search_list}\n"
        "Run scripts/setup_comparator.sh or pass --comparator /path/to/comparator."
    )


def build_path(root: Path) -> str:
    extra_dirs: list[Path] = []
    for tools_dir in tool_dir_candidates(root):
        extra_dirs.extend(
            [
                tools_dir / "bin",
                tools_dir / "src" / "lean4export" / ".lake" / "build" / "bin",
                tools_dir / "src" / "comparator" / ".lake" / "build" / "bin",
                tools_dir
                / "src"
                / "comparator"
                / ".lake"
                / "packages"
                / "lean4export"
                / ".lake"
                / "build"
                / "bin",
            ]
        )
    present_dirs = [str(path) for path in extra_dirs if path.is_dir()]
    current_path = os.environ.get("PATH", "")
    if current_path:
        present_dirs.append(current_path)
    return os.pathsep.join(present_dirs)


def comparator_config(pair: GoalPair, axioms: list[str], enable_nanoda: bool) -> dict[str, object]:
    return {
        "challenge_module": pair.challenge_module,
        "solution_module": pair.solution_module,
        "theorem_names": [pair.theorem_name],
        "permitted_axioms": axioms,
        "enable_nanoda": enable_nanoda,
    }


def missing_runtime_binaries(env: dict[str, str], enable_nanoda: bool) -> list[str]:
    required = ["landrun", "lean4export"]
    if enable_nanoda:
        required.append("nanoda_bin")
    missing: list[str] = []
    search_path = env.get("PATH")
    for binary in required:
        if shutil.which(binary, path=search_path) is None:
            missing.append(binary)
    return missing


def run_pair(
    pair: GoalPair,
    comparator_bin: Path,
    lean_dir: Path,
    axioms: list[str],
    enable_nanoda: bool,
    env: dict[str, str],
) -> tuple[bool, str]:
    if not pair.solution_file.is_file():
        return False, f"missing solution file {pair.solution_file.relative_to(lean_dir)}"

    config = comparator_config(pair, axioms, enable_nanoda)
    with tempfile.NamedTemporaryFile("w", suffix=".json", delete=False) as handle:
        json.dump(config, handle, indent=2)
        handle.flush()
        config_path = Path(handle.name)
    try:
        command = ["lake", "env", str(comparator_bin), str(config_path)]
        completed = subprocess.run(
            command,
            cwd=lean_dir,
            env=env,
            text=True,
            capture_output=True,
        )
    finally:
        config_path.unlink(missing_ok=True)

    transcript = (completed.stdout or "") + (completed.stderr or "")
    if completed.returncode == 0:
        return True, transcript.strip()
    return False, transcript.strip() or f"comparator exited with status {completed.returncode}"


def main() -> int:
    args = parse_args()
    root = repo_root()
    lean_dir = (args.lean_dir or (root / "lean")).resolve()
    selected_goals = set(args.goal)
    pairs = discover_pairs(lean_dir, selected_goals)

    if not pairs:
        print("No comparator goals found.", file=sys.stderr)
        return 1

    if args.list_goals:
        for pair in pairs:
            print(f"{pair.stem}: theorem {pair.theorem_name}")
        return 0

    axioms = DEFAULT_PERMITTED_AXIOMS.copy()
    if args.permitted_axiom:
        axioms.extend(args.permitted_axiom)

    env = os.environ.copy()
    env["PATH"] = build_path(root)
    print(f"Lean project: {lean_dir}")

    comparator_bin: Path | None = None
    if not args.dry_run:
        comparator_bin = resolve_comparator_binary(root, args.comparator)
        print(f"Using comparator: {comparator_bin}")
        missing = missing_runtime_binaries(env, args.enable_nanoda)
        if missing:
            print(
                "Missing comparator runtime binaries: " + ", ".join(missing) +
                ". Run scripts/setup_comparator.sh and ensure the resulting bin directory is on PATH.",
                file=sys.stderr,
            )
            return 2

    failures: list[str] = []
    for pair in pairs:
        print(
            f"\n==> {pair.stem}: {pair.challenge_module}.{pair.theorem_name} "
            f"vs {pair.solution_module}.{pair.theorem_name}"
        )
        if args.dry_run:
            print(json.dumps(comparator_config(pair, axioms, args.enable_nanoda), indent=2))
            continue

        assert comparator_bin is not None
        ok, message = run_pair(
            pair=pair,
            comparator_bin=comparator_bin,
            lean_dir=lean_dir,
            axioms=axioms,
            enable_nanoda=args.enable_nanoda,
            env=env,
        )
        if ok:
            print("PASS")
        else:
            print("FAIL")
            failures.append(pair.stem)

        if message:
            print(message)

        if failures and args.fail_fast:
            break

    if failures:
        print(f"\nComparator verification failed for: {', '.join(failures)}", file=sys.stderr)
        return 1

    print("\nComparator verification passed for all selected goals.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
