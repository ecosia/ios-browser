#!/usr/bin/env python3
"""List path strings in the Tuist manifests that match no file (Tuist drops them without a warning).

Usage: dead_manifest_paths.py [<repo-root>]

Checks every string literal that looks like a path (contains "/") in firefox-ios/Project.swift and
firefox-ios/Tuist/ProjectDescriptionHelpers/*.swift against the work tree, relative to
firefox-ios/. Globs (*, **, {a,b}) count as live when they match at least one file. Paths inside
comments are skipped.

Prints <manifest>:<line>: <path> for each dead path.
Exit codes: 0 none, 1 some, 64 usage error.
"""
import glob
import itertools
import os
import re
import sys
from pathlib import Path

sys.dont_write_bytecode = True
sys.path.insert(0, str(Path(__file__).resolve().parent))

import source_scan  # noqa: E402
import upgrade_common as uc  # noqa: E402

if len(sys.argv) > 2:
    uc.die("usage: dead_manifest_paths.py [<repo-root>]", uc.USAGE)
repo = sys.argv[1] if len(sys.argv) == 2 else str(uc.repo_root())
root = os.path.join(repo, "firefox-ios")
manifests = [os.path.join(root, "Project.swift")] + sorted(
    glob.glob(os.path.join(root, "Tuist/ProjectDescriptionHelpers/*.swift")))

literal = re.compile(r'"((?:[^"\\]|\\.)*)"')
pathlike = re.compile(r'^[A-Za-z0-9_.*{}\-+ /,]+$')


def expand_braces(pattern):
    m = re.search(r"\{([^{}]*)\}", pattern)
    if not m:
        return [pattern]
    options = [o.strip() for o in m.group(1).split(",")]
    return list(itertools.chain.from_iterable(
        expand_braces(pattern[:m.start()] + o + pattern[m.end():]) for o in options))


def matches(pattern):
    for p in expand_braces(pattern):
        full = os.path.join(root, p)
        if any(ch in p for ch in "*?["):
            if glob.glob(full, recursive=True):
                return True
        elif os.path.exists(full):
            return True
    return False


dead = 0
for path in manifests:
    text = open(path).read()
    kinds = source_scan.classify(text)
    # Comments blanked out; code and strings kept, so the literals can be found.
    live = "".join(" " if k == source_scan.COMMENT and ch != "\n" else ch for ch, k in zip(text, kinds))
    for lineno, code in enumerate(live.splitlines(), 1):
        for s in literal.findall(code):
            if "/" not in s or not pathlike.match(s) or s.startswith(("$(", "http")):
                continue
            if not matches(s):
                dead += 1
                print(f"{os.path.relpath(path, repo)}:{lineno}: {s}")
print(f"dead_manifest_paths: {dead} manifest paths match nothing", file=sys.stderr)
sys.exit(1 if dead else 0)
