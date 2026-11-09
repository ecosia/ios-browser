#!/usr/bin/env python3
"""Compare what upstream's Xcode project and Ecosia's Tuist project put into each target.

Usage: compare_targets.py <upstream_members.tsv> <our_members.tsv> <our_files.txt> <ecosia_created.txt>
                          <our_dependencies.tsv>
  *_members.tsv: output of pbx_members.py (target, phase, path)
  our_dependencies.tsv: output of pbx_members.py --dependencies for our project
  our_files.txt: files tracked on the branch (git ls-files firefox-ios/)
  ecosia_created.txt: files the branch adds on top of the upstream base
Sections:
  1 sources upstream compiles into a target we also build, which we compile elsewhere or nowhere
  2 sources we compile that upstream compiles into a different target, or into none
  3 sources we compile into more than one target; "LINKED" marks a source compiled into two
    targets where one imports the other (directly or through other modules) and upstream
    doesn't do the same: the type exists twice and becomes ambiguous
  4 resources: duplicate output names within one of our targets
  5 resources upstream copies into a target we build, which we don't copy there
  6 resources we copy that upstream doesn't copy into that target
LINKED rows in section 3 and every row in section 4 break builds or make a type ambiguous; the
rest is drift to read (sharing a source between an app and its extensions, or between test
targets, is how both projects work).

Exit codes: 0 no LINKED row and section 4 empty, 1 otherwise, 64 usage error.
"""
import collections
import sys

if len(sys.argv) != 6:
    print(__doc__, file=sys.stderr)
    sys.exit(64)
up_tsv, our_tsv, our_files_txt, created_txt, deps_tsv = sys.argv[1:6]

imports = collections.defaultdict(set)
for line in open(deps_tsv):
    if line.strip():
        target, module = line.rstrip("\n").split("\t")
        imports[target].add(module)


def reachable(target):
    """Every module `target` imports, directly or through other modules."""
    seen, todo = set(), [target]
    while todo:
        for m in imports.get(todo.pop(), ()):
            if m not in seen:
                seen.add(m)
                todo.append(m)
    return seen


def load(path):
    rows = collections.defaultdict(set)
    for line in open(path):
        t, k, p = line.rstrip("\n").split("\t")
        rows[(k, p)].add(t)
    return rows


up = load(up_tsv)
ours = load(our_tsv)
our_files = {l.strip() for l in open(our_files_txt) if l.strip()}
created = {l.strip() for l in open(created_txt) if l.strip()}
our_targets = {t for ts in ours.values() for t in ts}


def exists(p):
    return p in our_files or any(f.startswith(p + "/") for f in our_files)


def section(title, lines):
    print(f"## {title} ({len(lines)})")
    for l in sorted(lines):
        print(l)
    print()


s1 = []
for (k, p), uts in up.items():
    if k != "sources":
        continue
    for t in uts & our_targets:
        ots = ours.get(("sources", p), set())
        if t in ots:
            continue
        if not exists(p):
            s1.append(f"{p}\tupstream:{t}\tours:- (file not on branch)")
        else:
            s1.append(f"{p}\tupstream:{t}\tours:{','.join(sorted(ots)) or '-'}")
section("1 upstream compiles into a target we build; we compile it elsewhere or not at all", s1)

s2 = []
for (k, p), ots in ours.items():
    if k != "sources" or p in created:
        continue
    uts = up.get(("sources", p), set())
    for t in ots - uts:
        s2.append(f"{p}\tours:{t}\tupstream:{','.join(sorted(uts)) or '-'}")
section("2 we compile a non-Ecosia file into a target upstream doesn't", s2)

s3 = []
linked = 0
for (k, p), ots in ours.items():
    if k == "sources" and len(ots) > 1:
        uts = up.get(("sources", p), set())
        pairs = [(a, b) for a in ots for b in ots if a != b and b in reachable(a)]
        new = [(a, b) for a, b in pairs if not {a, b} <= uts]
        mark = ""
        if new:
            linked += 1
            mark = "\tLINKED " + ",".join(f"{a}>{b}" for a, b in sorted(new))
        s3.append(f"{p}\tours:{','.join(sorted(ots))}\tupstream:{','.join(sorted(uts)) or '-'}{mark}")
section("3 sources compiled into more than one of our targets", s3)


def output_name(p):
    parts = p.split("/")
    for i, part in enumerate(parts):
        if part.endswith((".xcassets", ".bundle", ".icon")):
            return "/".join(parts[i:i + 1])
        if part.endswith(".lproj"):
            return "/".join(parts[i:])
    return parts[-1]


by_target = collections.defaultdict(lambda: collections.defaultdict(list))
for (k, p), ots in ours.items():
    if k != "resources":
        continue
    for t in ots:
        by_target[t][output_name(p)].append(p)
s4 = []
for t, names in by_target.items():
    for n, ps in names.items():
        if len(ps) > 1:
            s4.append(f"{t}\t{n}\t" + " ".join(sorted(ps)))
section("4 resources with the same output name in one of our targets", s4)

s5 = []
for (k, p), uts in up.items():
    if k != "resources":
        continue
    for t in uts & our_targets:
        if t not in ours.get(("resources", p), set()):
            s5.append(f"{p}\tupstream:{t}\tours:{','.join(sorted(ours.get(('resources', p), set()))) or '-'}\t{'on branch' if exists(p) else 'not on branch'}")
section("5 resources upstream copies into a target we build, and we don't", s5)

s6 = []
for (k, p), ots in ours.items():
    if k != "resources" or p in created:
        continue
    uts = up.get(("resources", p), set())
    for t in ots - uts:
        s6.append(f"{p}\tours:{t}\tupstream:{','.join(sorted(uts)) or '-'}")
section("6 resources we copy (non-Ecosia files) that upstream doesn't copy into that target", s6)

print(f"compare_targets: {len(s3)} sources in more than one target, {linked} of them LINKED; "
      f"{len(s4)} duplicate resource names", file=sys.stderr)
if linked or s4:
    sys.exit(1)
