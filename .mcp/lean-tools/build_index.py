#!/usr/bin/env python3
"""Build a local declaration search index from Mathlib .lean source files.

Usage: python3 build_index.py <path-to-Mathlib/> > mathlib_index.json

Writes a JSON array of declaration records to stdout; progress to stderr.
"""
import json
import re
import sys
from pathlib import Path

DECL_RE = re.compile(
    r"^(?:(?:@\[[^\]]*\]\s*)*(?:private|protected|noncomputable|partial|unsafe)\s+)*"
    r"(theorem|lemma|def|abbrev|instance|class|structure|inductive|opaque)"
    r"\s+([^\s:({\[]+)"
)


def extract_decls(path: Path, mathlib_root: Path):
    try:
        lines = path.read_text(errors="replace").splitlines()
    except Exception:
        return

    rel = str(path.relative_to(mathlib_root.parent))

    for i, line in enumerate(lines):
        m = DECL_RE.match(line)
        if not m:
            continue
        kind = m.group(1)
        name = m.group(2)

        # Collect the header (name + type signature) across continuation lines.
        # Stop at := / := by / where clause / next declaration.
        parts = [line.rstrip()]
        for j in range(1, 8):
            if i + j >= len(lines):
                break
            next_l = lines[i + j].rstrip()
            if DECL_RE.match(next_l):
                break
            parts.append(next_l)
            stripped = next_l.strip()
            if ":= by" in stripped or re.search(r":=\s*$", stripped) or stripped == "where":
                break

        header = " ".join(p.strip() for p in parts)
        # Truncate at := so we only keep the signature, not the body.
        idx = header.find(":=")
        if idx >= 0:
            header = header[:idx].rstrip()

        yield {
            "kind": kind,
            "name": name,
            "file": rel,
            "line": i + 1,
            "header": header[:400],
        }


def main():
    if len(sys.argv) < 2:
        print("Usage: build_index.py <path-to-Mathlib/>", file=sys.stderr)
        sys.exit(1)

    mathlib_root = Path(sys.argv[1]).resolve()
    if not mathlib_root.is_dir():
        print(f"Error: {mathlib_root} is not a directory", file=sys.stderr)
        sys.exit(1)

    results = []
    lean_files = sorted(mathlib_root.rglob("*.lean"))
    total_files = len(lean_files)

    for n, lean_file in enumerate(lean_files, 1):
        results.extend(extract_decls(lean_file, mathlib_root))
        if n % 500 == 0:
            print(f"  {n}/{total_files} files, {len(results)} decls so far…", file=sys.stderr)

    json.dump(results, sys.stdout, ensure_ascii=False, separators=(",", ":"))
    print(f"\nIndexed {len(results)} declarations from {len(lean_files)} files in {mathlib_root}", file=sys.stderr)


if __name__ == "__main__":
    main()
