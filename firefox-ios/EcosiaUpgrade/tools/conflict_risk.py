#!/usr/bin/env python3
"""Rank every Firefox file Ecosia customized by how much upstream changed it before the target.

Usage: conflict_risk.py --target <ref> [--base <ref>] [--ref <ref>] [--changed-only]

A customized file is a Firefox file (it exists at the base) that differs at <ref> or is gone there:
the marked, unmarked and deleted lists of core_modified_files.py. For each one, the script reads
what upstream did to it from the base to the target and whether a merge of <ref> and the target
conflicts on it (`git merge-tree`, nothing is written to the work tree).

Risk, highest first:
  conflict  the merge stops on this file
  silent    the file differs at the target and the merge takes both sides without a conflict: check it
            against its intent diff, because a clean merge can still lose Ecosia's change
  none      the file is the same at the base and the target
Within a risk, files are ordered by upstream churn (lines added plus removed), then by the
number of upstream commits that touched them.

  --base          Firefox release the tree is built on (default: UPSTREAM_BASE)
  --ref           tree with Ecosia's changes (default: HEAD)
  --target        Firefox release being upgraded to (required)
  --changed-only  leave out the files upstream did not touch

Prints a TSV with a header to stdout: rank, file, kind (marked, unmarked, deleted), risk,
upstream_commits, upstream_lines, ecosia_lines. A summary goes to stderr. Exits 0, or 2/64 when
it cannot run.
"""

import subprocess
import sys
from collections import Counter
from pathlib import Path

sys.dont_write_bytecode = True
sys.path.insert(0, str(Path(__file__).resolve().parent))

import core_modified_files  # noqa: E402
import upgrade_common as uc  # noqa: E402

RISKS = ("conflict", "silent", "none")
HEADER = ("rank", "file", "kind", "risk", "upstream_commits", "upstream_lines", "ecosia_lines")


def parse_numstat(text):
    """{path: added + removed} from `git diff --numstat -z --no-renames`. Binary files count 0."""
    lines = {}
    for record in text.split("\0"):
        if not record:
            continue
        added, removed, path = record.split("\t", 2)
        lines[path] = (0 if added == "-" else int(added)) + (0 if removed == "-" else int(removed))
    return lines


def parse_commit_counts(text):
    """{path: number of commits} from `git log --format=%x01 --name-only -z --no-renames`."""
    counts = Counter()
    for chunk in text.split("\x01"):
        counts.update({p.strip("\n") for p in chunk.split("\0") if p.strip("\n")})
    return counts


def parse_conflicts(text):
    """Conflicted paths from `git merge-tree --write-tree --name-only --no-messages -z`: the first
    record is the tree, the rest are paths."""
    records = [r for r in text.split("\0") if r]
    return set(records[1:])


def risk_of(path, conflicts, upstream_lines):
    """`upstream_lines` holds every path that differs between the base and the target, binary files
    included. A file upstream changed and changed back counts as untouched."""
    if path in conflicts:
        return "conflict"
    if path in upstream_lines:
        return "silent"
    return "none"


def rank(rows):
    """Rows are dicts with file, risk, upstream_lines, upstream_commits. Returns them sorted."""
    return sorted(rows, key=lambda r: (RISKS.index(r["risk"]), -r["upstream_lines"],
                                       -r["upstream_commits"], r["file"]))


def main():
    parser = uc.Parser(description=__doc__.split("\n")[1])
    parser.add_argument("--base")
    parser.add_argument("--ref", default="HEAD")
    parser.add_argument("--target", required=True)
    parser.add_argument("--changed-only", action="store_true")
    args = parser.parse_args()

    root = uc.repo_root()
    base = uc.base_ref(args.base, root)
    ref = uc.resolve_ref(args.ref, root)
    target = uc.resolve_ref(args.target, root)

    marked, unmarked, deleted, _ = core_modified_files.scan(base, ref, root)
    kinds = {p: "marked" for p in marked}
    kinds.update({p: "unmarked" for p in unmarked})
    kinds.update({p: "deleted" for p in deleted})

    upstream_lines = parse_numstat(uc.git("diff", "--numstat", "-z", "--no-renames", base, target,
                                          cwd=root))
    ecosia_lines = parse_numstat(uc.git("diff", "--numstat", "-z", "--no-renames", base, ref,
                                        cwd=root))
    upstream_commits = parse_commit_counts(uc.git("log", "--format=%x01", "--name-only", "-z",
                                                  "--no-renames", f"{base}..{target}", cwd=root))
    merge = subprocess.run(["git", "merge-tree", "--write-tree", "--name-only", "--no-messages",
                            "-z", f"--merge-base={base}", ref, target], cwd=root,
                           capture_output=True, text=True)
    if merge.returncode not in (0, 1):
        uc.die(f"git merge-tree failed: {merge.stderr.strip()}")
    conflicts = parse_conflicts(merge.stdout) if merge.returncode == 1 else set()

    rows = []
    for path, kind in kinds.items():
        risk = risk_of(path, conflicts, upstream_lines)
        if args.changed_only and risk == "none":
            continue
        rows.append({"file": path, "kind": kind, "risk": risk,
                     "upstream_commits": upstream_commits.get(path, 0),
                     "upstream_lines": upstream_lines.get(path, 0),
                     "ecosia_lines": ecosia_lines.get(path, 0)})

    print("\t".join(HEADER))
    for number, row in enumerate(rank(rows), 1):
        print("\t".join(str(v) for v in (number, row["file"], row["kind"], row["risk"],
                                         row["upstream_commits"], row["upstream_lines"],
                                         row["ecosia_lines"])))

    by = Counter((r["kind"], r["risk"]) for r in rows)
    summary = "; ".join(f"{kind}: " + ", ".join(f"{by[(kind, risk)]} {risk}" for risk in RISKS)
                        for kind in ("marked", "unmarked", "deleted"))
    print(f"conflict_risk: {base}..{ref} against {target}: {len(kinds)} customized files "
          f"({summary}); the merge conflicts on {len(conflicts)} paths in all", file=sys.stderr)
    return uc.OK


if __name__ == "__main__":
    sys.exit(main())
