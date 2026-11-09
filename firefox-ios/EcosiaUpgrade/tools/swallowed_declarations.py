#!/usr/bin/env python3
"""Find functions that are declared only inside a comment but still called by live code.

Usage: swallowed_declarations.py [--ref <ref> | --worktree] [<path>...]

When upstream inserts methods right where an `/* Ecosia: */` block opens, the merge puts them
inside the comment while their call sites stay live (155.1 experiment: BookmarksViewController,
LocationTextField.applyTheme). A plain grep sees the declaration and reports nothing. This check
reads each file with comments and strings told apart: a function name declared in a comment, not
declared in the file's live code, and called by the file's live code (`name(` or `self.name(`).

  --ref       tree to read (default: HEAD)
  --worktree  read the files from the work tree instead, for a merge in progress
  <path>      Swift files to check (default: every Swift file with an `Ecosia:` comment)

Prints <path>:<line>: <name> ... for each one. Calls into a superclass or another type with the
same name are possible false positives.

Exit codes: 0 none found, 1 some found, 2 could not run, 64 usage error.
"""

import re
import sys
from pathlib import Path

sys.dont_write_bytecode = True
sys.path.insert(0, str(Path(__file__).resolve().parent))

import source_scan  # noqa: E402
import upgrade_common as uc  # noqa: E402

FUNC_DECL = re.compile(r"\bfunc\s+([A-Za-z_][A-Za-z0-9_]*)")


def line_of(text, pos):
    return text.count("\n", 0, pos) + 1


def check(path, text):
    """[(call line, name, comment line)] for one file."""
    kinds = source_scan.classify(text)
    code = source_scan.keep(text, kinds, source_scan.CODE)
    comments = source_scan.keep(text, kinds, source_scan.COMMENT)
    live = set(FUNC_DECL.findall(code))
    hidden = {}
    for m in FUNC_DECL.finditer(comments):
        hidden.setdefault(m.group(1), m.start())
    found = []
    for name, pos in sorted(hidden.items()):
        if name in live:
            continue
        call = re.search(rf"(?:(?<![\w.])|\bself\.){re.escape(name)}\s*\(", code)
        if call:
            found.append((line_of(text, call.start()), name, line_of(text, pos)))
    return found


def main():
    parser = uc.Parser(description=__doc__.split("\n")[1])
    source = parser.add_mutually_exclusive_group()
    source.add_argument("--ref", default="HEAD")
    source.add_argument("--worktree", action="store_true")
    parser.add_argument("paths", nargs="*")
    args = parser.parse_args()
    root = uc.repo_root()

    if args.worktree:
        ref = "the work tree"
        paths = args.paths
        if not paths:
            out = uc.git("grep", "-l", "-z", "-F", source_scan.MARKER, "--", "*.swift", cwd=root,
                         check=False)
            paths = sorted(p for p in out.split("\0") if p)
        blobs = {}
        for p in paths:
            try:
                blobs[p] = (root / p).read_text(errors="replace")
            except OSError:
                pass
    else:
        ref = uc.resolve_ref(args.ref, root)
        paths = args.paths
        if not paths:
            out = uc.git("grep", "-l", "-z", "-F", source_scan.MARKER, ref, "--", "*.swift",
                         cwd=root, check=False)
            paths = sorted(p[len(ref) + 1:] for p in out.split("\0") if p)
        blobs = uc.read_blobs(ref, paths, root)
    missing = [p for p in paths if p not in blobs]
    if missing:
        uc.die(f"not in {ref}: {', '.join(missing)}", uc.USAGE)

    hits = 0
    for path in paths:
        for call_line, name, comment_line in check(path, blobs[path]):
            hits += 1
            print(f"{path}:{call_line}: {name}() is called here but declared only inside a comment "
                  f"(line {comment_line})")
    print(f"swallowed_declarations: {len(paths)} files at {ref}, {hits} calls to functions "
          f"declared only in comments", file=sys.stderr)
    return uc.FAILED if hits else uc.OK


if __name__ == "__main__":
    sys.exit(main())
