#!/usr/bin/env python3
"""List the Firefox files Ecosia modified, from the tree instead of by hand.

Usage: core_modified_files.py [--base <ref>] [--ref <ref>] [--list marked|unmarked|deleted] [--counts]

A Firefox file is one that exists at the upstream base. It is Ecosia-modified when it differs at
<ref>. "marked" (the default) lists the modified files with an `Ecosia:` marker inside a comment:
the input of build_intent_diffs.sh. "unmarked" lists modified files without one (a missing marker,
or an upgrade change that is not Ecosia's). "deleted" lists Firefox files that are gone at <ref>.

  --base    Firefox release the tree is built on (default: UPSTREAM_BASE). Tag names resolve to
            refs/tags/... first.
  --ref     tree to scan (default: HEAD)
  --counts  print "<path><TAB><number of marker lines>" instead of the path alone

Prints one path per line to stdout and a summary to stderr. Exits 0, or 2/64 when it cannot run.
"""

import sys
from pathlib import Path

sys.dont_write_bytecode = True
sys.path.insert(0, str(Path(__file__).resolve().parent))

import source_scan  # noqa: E402
import upgrade_common as uc  # noqa: E402


def scan(base, ref, root):
    """(marked {path: count}, unmarked [path], deleted [path], string_only [path])."""
    modified = uc.changed_files(base, ref, root, "MT")
    deleted = uc.changed_files(base, ref, root, "D")
    # Only files whose text mentions the marker need the comment-aware pass.
    prefix = f"{ref}:"
    mentions = {c[len(prefix):] for c in uc.git("grep", "-l", "-z", "-I", "-F", source_scan.MARKER,
                                                ref, cwd=root, check=False).split("\0") if c}
    candidates = sorted(set(modified) & mentions)
    blobs = uc.read_blobs(ref, candidates, root)
    marked, string_only = {}, []
    for path, text in blobs.items():
        lines = source_scan.marker_lines(text, path)
        if lines:
            marked[path] = len(lines)
        else:
            string_only.append(path)
    unmarked = [p for p in modified if p not in marked]
    return marked, unmarked, deleted, string_only


def main():
    parser = uc.Parser(description=__doc__.split("\n")[1])
    parser.add_argument("--base")
    parser.add_argument("--ref", default="HEAD")
    parser.add_argument("--list", choices=["marked", "unmarked", "deleted"], default="marked")
    parser.add_argument("--counts", action="store_true")
    args = parser.parse_args()

    root = uc.repo_root()
    base = uc.base_ref(args.base, root)
    ref = uc.resolve_ref(args.ref, root)
    marked, unmarked, deleted, string_only = scan(base, ref, root)

    if args.list == "marked":
        for path in sorted(marked):
            print(f"{path}\t{marked[path]}" if args.counts else path)
    elif args.list == "unmarked":
        for path in unmarked:
            print(path)
    else:
        for path in deleted:
            print(path)

    print(f"core_modified_files: {base}..{ref}: {len(marked) + len(unmarked)} Firefox files modified, "
          f"{len(marked)} with an Ecosia: marker in a comment, {len(unmarked)} without, "
          f"{len(deleted)} deleted", file=sys.stderr)
    if string_only:
        print(f"core_modified_files: {len(string_only)} modified files mention Ecosia: only outside "
              f"comments (counted as unmarked): {', '.join(string_only)}", file=sys.stderr)
    return uc.OK


if __name__ == "__main__":
    sys.exit(main())
