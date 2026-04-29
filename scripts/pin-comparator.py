"""Pin comparator's lean4export dependency to a specific ref in its lakefile.toml."""
import sys
from pathlib import Path

lakefile = Path(sys.argv[1])
ref = sys.argv[2]
lines = lakefile.read_text().splitlines()
out, in_req, is_target = [], False, False
for line in lines:
    s = line.strip()
    if s == "[[require]]":
        in_req, is_target = True, False
    elif in_req and s.startswith("[[") and s != "[[require]]":
        in_req, is_target = False, False
    if in_req and s == 'name = "lean4export"':
        is_target = True
    if is_target and s.startswith('rev = "'):
        out.append(f'rev = "{ref}"')
        is_target = False
        continue
    out.append(line)
lakefile.write_text("\n".join(out) + "\n")
