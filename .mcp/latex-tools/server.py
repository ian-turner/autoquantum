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

mcp = FastMCP("latex-tools")


def _repo_root() -> Path:
    if root := os.environ.get("LATEX_TOOLS_REPO_ROOT"):
        return Path(root)
    # server.py lives at .mcp/latex-tools/server.py — three levels up is repo root
    return Path(__file__).resolve().parent.parent.parent


def _latex_root() -> Path:
    return _repo_root() / "latex"


def _resolve_project(project: str) -> Path:
    """Resolve a project name or relative path to an absolute directory under latex/."""
    latex_root = _latex_root()
    target = (latex_root / project).resolve()
    # Guard against path traversal outside latex/
    if not str(target).startswith(str(latex_root.resolve())):
        raise ValueError(f"project path must be inside latex/: {project}")
    return target


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


def _run(command: list[str], cwd: Path) -> str:
    result = subprocess.run(command, cwd=cwd, capture_output=True, text=True)
    parts = [f"Command: {' '.join(command)}", f"Exit code: {result.returncode}"]
    if out := _trim(result.stdout):
        parts.append(f"Stdout:\n{out}")
    if err := _trim(result.stderr):
        parts.append(f"Stderr:\n{err}")
    return "\n".join(parts)


@mcp.tool()
def compile(project: str, main: str = "main.tex") -> str:
    """Compile a LaTeX project with latexmk.

    project: subdirectory of latex/ containing the .tex source (e.g. 'qft-paper').
    main: the root .tex file within that directory (default 'main.tex').

    Runs: latexmk -pdf -interaction=nonstopmode -halt-on-error <main>
    Returns compiler output including any errors.
    """
    project_dir = _resolve_project(project)
    if not project_dir.is_dir():
        return f"Error: directory does not exist: latex/{project}"
    main_file = project_dir / main
    if not main_file.is_file():
        return f"Error: file does not exist: latex/{project}/{main}"
    return _run(
        ["latexmk", "-pdf", "-interaction=nonstopmode", "-halt-on-error", main],
        cwd=project_dir,
    )


@mcp.tool()
def clean(project: str) -> str:
    """Remove latexmk build artifacts from a LaTeX project directory.

    project: subdirectory of latex/ (e.g. 'qft-paper').

    Runs: latexmk -C
    """
    project_dir = _resolve_project(project)
    if not project_dir.is_dir():
        return f"Error: directory does not exist: latex/{project}"
    return _run(["latexmk", "-C"], cwd=project_dir)


@mcp.tool()
def list_projects() -> str:
    """List all project directories under latex/."""
    latex_root = _latex_root()
    if not latex_root.is_dir():
        return "latex/ directory does not exist yet."
    projects = sorted(p.name for p in latex_root.iterdir() if p.is_dir())
    if not projects:
        return "No projects found in latex/."
    return "\n".join(projects)


if __name__ == "__main__":
    mcp.run()
