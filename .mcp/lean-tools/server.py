#!/usr/bin/env python3
# /// script
# dependencies = ["mcp>=1.0.0"]
# ///

import json
import os
import subprocess
import urllib.error
import urllib.parse
import urllib.request
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
def sorry_count() -> str:
    """Count remaining `sorry`s across all Lean source files in AutoQuantum/."""
    lean_root = _lean_root()
    src_dir = lean_root / "AutoQuantum"
    files = sorted(src_dir.rglob("*.lean"))
    rows = []
    total = 0
    for f in files:
        text = f.read_text(errors="replace")
        count = text.count("sorry")
        if count:
            rows.append(f"  {f.relative_to(lean_root)}: {count}")
            total += count
    if not rows:
        return "No sorrys found."
    return "\n".join([f"Total: {total}"] + rows)


@mcp.tool()
def check_file(file: str) -> str:
    """Typecheck a single Lean file with lake env lean.

    file is relative to lean/, e.g. 'AutoQuantum/Gate.lean'.
    """
    if not file.endswith(".lean"):
        raise ValueError("file must end with .lean")
    return _run(["lake", "env", "lean", file])


_UA = "Mozilla/5.0 (compatible; lean-mcp-search/1.0)"


@mcp.tool()
def search_mathlib(query: str, kind: str = "leansearch") -> str:
    """Search Mathlib for lemmas and definitions via HTTP — no LSP warmup required.

    Use this instead of grep when looking for Mathlib declarations.

    kind="leansearch"  natural-language semantic search
                       e.g. "commutativity of addition over natural numbers"
    kind="loogle"      type-signature pattern search
                       e.g. "?a + ?b = ?b + ?a" or "List ?a → ?a"
    """
    if kind == "loogle":
        url = "https://loogle.lean-lang.org/json?" + urllib.parse.urlencode({"q": query})
        req = urllib.request.Request(url, headers={"User-Agent": _UA})
        try:
            with urllib.request.urlopen(req, timeout=30) as resp:
                data = json.loads(resp.read())
        except urllib.error.URLError as e:
            return f"Loogle request failed: {e}"
        if err := data.get("error"):
            return f"Loogle error: {err}"
        hits = data.get("hits") or []
        if not hits:
            return f"No Loogle results for: {query}"
        count = data.get("count", len(hits))
        lines = [f"Loogle results for '{query}' ({count} total, showing {len(hits)}):"]
        for h in hits:
            lines.append(f"  {h['name']} : {h.get('type', '')}")
            if doc := h.get("doc") or h.get("docString", ""):
                lines.append(f"    {doc[:160]}")
        return "\n".join(lines)

    if kind == "leansearch":
        body = json.dumps({"query": [query], "num_results": 20}).encode()
        req = urllib.request.Request(
            "https://leansearch.net/search",
            data=body,
            headers={"Content-Type": "application/json", "User-Agent": _UA},
        )
        try:
            with urllib.request.urlopen(req, timeout=15) as resp:
                data = json.loads(resp.read())
        except urllib.error.URLError as e:
            return f"LeanSearch request failed: {e}"
        # Response is [[{result, distance}, ...]]
        hits = data[0] if data and isinstance(data[0], list) else data
        if not hits:
            return f"No LeanSearch results for: {query}"
        lines = [f"LeanSearch results for '{query}' ({len(hits)} results):"]
        for entry in hits:
            r = entry.get("result", entry)
            name = ".".join(r["name"]) if isinstance(r.get("name"), list) else r.get("name", "")
            sig = r.get("signature") or r.get("type", "")
            lines.append(f"  {name} : {sig}")
            if doc := r.get("docstring") or r.get("informal_description", ""):
                lines.append(f"    {doc[:160]}")
        return "\n".join(lines)

    raise ValueError(f"Unknown kind {kind!r}. Use 'loogle' or 'leansearch'.")


if __name__ == "__main__":
    mcp.run()
