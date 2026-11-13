#!/usr/bin/env python3
"""List skipped tests in Schemes+Ecosia.swift that name no existing test class or method.

Usage: skipped_tests.py [<our_members.tsv>]

Xcode ignores a skip entry for a test that doesn't exist, so a renamed or deleted test stays in the
list unnoticed. Each entry is checked against the Swift files the scheme's unit-test targets
compile, taken from the generated project (run ./tuist-setup.sh --no-open first) or from a
pbx_members.py listing of it.

Exit codes: 0 every entry exists, 1 some are stale, 2 could not run, 64 usage error.
"""

import re
import sys
from pathlib import Path

sys.dont_write_bytecode = True
sys.path.insert(0, str(Path(__file__).resolve().parent))

import pbx_members  # noqa: E402
import upgrade_common as uc  # noqa: E402

SCHEME = "firefox-ios/Tuist/ProjectDescriptionHelpers/Schemes+Ecosia.swift"
PROJECT = "firefox-ios/Client.xcodeproj/project.pbxproj"


def main():
    if len(sys.argv) > 2:
        uc.die("usage: skipped_tests.py [<our_members.tsv>]", uc.USAGE)
    root = uc.repo_root()
    scheme = (root / SCHEME).read_text()

    found = re.search(r"unitTestTargets: \[TestableTarget\] = \[(.*?)\]", scheme, re.S)
    block = re.search(r"skippedTests: \[String\] = \[(.*?)\n    \]", scheme, re.S)
    if not found or not block:
        uc.die(f"cannot find unitTestTargets or skippedTests in {SCHEME}")
    targets = set(re.findall(r'"(\w+)"', found.group(1)))
    entries = [re.search(r'"([^"]+)"', l).group(1) for l in block.group(1).splitlines()
               if re.match(r'\s*"', l)]

    if len(sys.argv) == 2:
        rows = [l.rstrip("\n").split("\t") for l in open(sys.argv[1]) if l.strip()]
    else:
        if not (root / PROJECT).exists():
            uc.die(f"{PROJECT} not found; run ./tuist-setup.sh --no-open first")
        rows = pbx_members.members(pbx_members.load_project(root / PROJECT))
    sources = {p for t, k, p in rows if t in targets and k == "sources" and p.endswith(".swift")}

    classes = {}
    for p in sources:
        path = root / p
        if not path.exists():
            continue
        text = path.read_text(errors="ignore")
        for m in re.finditer(r"^\s*(?:final\s+|open\s+|public\s+|@MainActor\s+)*class\s+(\w+)\s*:",
                             text, re.M):
            classes.setdefault(m.group(1), []).append(text)

    stale = 0
    for e in entries:
        cls, _, method = e.partition("/")
        method = method.rstrip("()")
        if cls not in classes:
            print(f"missing class: {e}")
            stale += 1
        elif method and not any(re.search(rf"func\s+{re.escape(method)}\s*\(", t)
                                for t in classes[cls]):
            print(f"missing method: {e}")
            stale += 1
    print(f"skipped_tests: {len(entries)} skipped entries, {stale} stale, targets: "
          f"{', '.join(sorted(targets))}", file=sys.stderr)
    return uc.FAILED if stale else uc.OK


if __name__ == "__main__":
    sys.exit(main())
