#!/usr/bin/env python3
# /// script
# dependencies = ["mcp>=1.0.0"]
# ///

import os
import subprocess
from pathlib import Path

from mcp.server.fastmcp import FastMCP

MAX_OUTPUT_CHARS = 12_000
MAX_OUTPUT_LINES = 160

mcp = FastMCP("lean-tools")


def _repo_root() -> Path:
    if root := os.environ.get("LEAN_TOOLS_REPO_ROOT"):
        return Path(root)
    # server.py lives at .mcp/lean-tools/server.py — three levels up is repo root
    return Path(__file__).resolve().parent.parent.parent


def _lean_root() -> Path:
    return _repo_root() / "lean"


def _trim(text: str) -> str:
    text = text.strip()
    if not text:
        return ""
    lines = text.split("\n")
    if len(lines) > MAX_OUTPUT_LINES:
        lines = lines[-MAX_OUTPUT_LINES:]
        text = "\n".join(lines)
    if len(text) > MAX_OUTPUT_CHARS:
        text = "[output truncated]\n" + text[-MAX_OUTPUT_CHARS:]
    return text


def _run(command: list[str]) -> str:
    result = subprocess.run(command, cwd=_lean_root(), capture_output=True, text=True)
    parts = [f"Command: {' '.join(command)}", f"Exit code: {result.returncode}"]
    if out := _trim(result.stdout):
        parts.append(f"Stdout:\n{out}")
    if err := _trim(result.stderr):
        parts.append(f"Stderr:\n{err}")
    return "\n".join(parts)


@mcp.tool()
def build(target: str = "AutoQuantum") -> str:
    """Run lake build in the repo's lean/ project. target defaults to 'AutoQuantum'."""
    cmd = ["lake", "build"]
    if target:
        cmd.append(target)
    return _run(cmd)


@mcp.tool()
def check_file(file: str) -> str:
    """Typecheck a single Lean file with lake env lean.

    file is relative to lean/, e.g. 'AutoQuantum/Gate.lean'.
    """
    if not file.endswith(".lean"):
        raise ValueError("file must end with .lean")
    return _run(["lake", "env", "lean", file])


if __name__ == "__main__":
    mcp.run()
