# Manual upgrade checks

The checks tickets 12 (MOB-5038) and 13 (MOB-5039) ran by hand on `upgrade/firefox`, written down so ticket 14 (MOB-5040) can turn them into scripts. Run from the repository root. Results and triage are in the diary ([157.md](../diary/157.md), 2026-11-04 entries for 12 and 13). The helper scripts are at the end of this file; save each one outside the repository (for example in a temporary folder `$t`) before running it.

Always name Firefox tags as `refs/tags/...`: `firefox-v147.2` is ambiguous in some clones.

```bash
t=$(mktemp -d)
main_base=refs/tags/firefox-v147.2                       # main's Firefox base
branch_base=refs/tags/$(cut -f1 firefox-ios/EcosiaUpgrade/UPSTREAM_BASE)
synced_main=$(git merge-base HEAD origin/main)            # the main the branch has merged
```

## 1. Ecosia files missing on either side

Files Ecosia created are the files each side adds on top of its own Firefox base. `--no-renames` matters: with rename detection, `MultiplyImpact.swift` was paired with an unrelated upstream file and dropped (experiment ticket 19 §9h).

```bash
git diff --no-renames --diff-filter=A --name-only "$main_base" origin/main | sort > "$t/main_added.txt"
git diff --no-renames --diff-filter=A --name-only "$main_base" "$synced_main" | sort > "$t/synced_added.txt"
git diff --no-renames --diff-filter=A --name-only "$branch_base" HEAD | sort > "$t/branch_added.txt"
comm -23 "$t/main_added.txt" "$t/branch_added.txt"     # created on main, missing on the branch
comm -13 "$t/main_added.txt" "$t/branch_added.txt"     # created only on the branch
comm -23 "$t/synced_added.txt" "$t/branch_added.txt"   # same, minus main commits not synced yet
```

For each path in the output, compare its blob on every side (`blobs.sh` below). A file that exists on the branch but also in the Firefox base (for example `AGENTS.md`) is not missing; a file that exists nowhere on the branch needs a reason.

```bash
comm -23 "$t/synced_added.txt" "$t/branch_added.txt" \
  | bash "$t/blobs.sh" HEAD "$branch_base" "$synced_main" origin/main
```

Also check what the next main sync will conflict on:

```bash
git merge-tree --write-tree --name-only HEAD origin/main
```

## 2. Symbol dependencies

`build_symbol_map.py` from the experiment, run unchanged through a wrapper (`run_symbol_map.py` below) that points it at this repository, the branch as the new side, and a file list of our choice.

```bash
git show origin/firefox-upgrade-155.1:firefox-ios/Tuist/upgrade/rebase-manifest-155.1/build_symbol_map.py > "$t/build_symbol_map.py"
mkdir -p "$t/runA" "$t/runB"
# A: the experiment's own file list
git show origin/firefox-upgrade-155.1:firefox-ios/Tuist/upgrade/rebase-manifest-155.1/ecosia_owned_files.txt > "$t/runA/ecosia_owned_files.txt"
# B: every Ecosia Swift file, plus Ecosia-created Swift files elsewhere (no Tuist manifests, no XCUITests)
{ git ls-files 'firefox-ios/Client/Ecosia/*.swift' 'firefox-ios/Ecosia/*.swift' 'firefox-ios/EcosiaTests/*.swift'
  grep '\.swift$' "$t/branch_added.txt" \
    | grep -v -E '^firefox-ios/(Client/Ecosia|Ecosia|EcosiaTests)/|^firefox-ios/(Project|Tuist)\.swift$|^firefox-ios/Tuist/|/XCUITests/'
} | sort -u > "$t/runB/ecosia_owned_files.txt"
python3 -I "$t/run_symbol_map.py" "$PWD" "$main_base" HEAD "$t/runA"
python3 -I "$t/run_symbol_map.py" "$PWD" "$main_base" HEAD "$t/runB" extended
```

Each run writes `symbol-dependency-report.md` into its folder. To triage a flag:

```bash
# where the name is declared now (Ecosia's own copies count)
git grep -n -E '(class|struct|enum|protocol|typealias|actor) NAME[^A-Za-z0-9_]' HEAD -- firefox-ios BrowserKit/Sources
git grep -n -E 'func NAME[^A-Za-z0-9_]' HEAD -- firefox-ios BrowserKit/Sources
# how the flagged file uses it (a comment or string is a false positive)
git grep -n -w NAME HEAD -- <flagged file>
# for a method flag: which Firefox declaration disappeared
git grep -n 'func NAME' "$main_base" -- firefox-ios/Client BrowserKit/Sources firefox-ios/Shared firefox-ios/Storage
```

## 3. Build-system drift

Upstream's `Client.xcodeproj` against the project Tuist generates, per target and build phase. Generate the branch's project first (`./tuist-setup.sh --no-open`).

```bash
git show "$branch_base":firefox-ios/Client.xcodeproj/project.pbxproj > "$t/upstream.pbxproj"
plutil -convert json -o "$t/upstream.json" "$t/upstream.pbxproj"
git ls-tree -r --name-only "$branch_base" firefox-ios/ > "$t/upstream_files.txt"
python3 -I "$t/pbx_members.py" "$t/upstream.json" "$t/upstream_files.txt" > "$t/upstream_members.tsv"

plutil -convert json -o "$t/ours.json" firefox-ios/Client.xcodeproj/project.pbxproj
git ls-files firefox-ios/ > "$t/our_files.txt"
python3 -I "$t/pbx_members.py" "$t/ours.json" /dev/null > "$t/our_members.tsv"

python3 -I "$t/compare.py" "$t/upstream_members.tsv" "$t/our_members.tsv" "$t/our_files.txt" "$t/branch_added.txt"
```

Sections 3 (one source in two of our targets) and 4 (duplicate resource names in one target) are the ones that break builds or make a type ambiguous. To tell drift the upgrade introduced from drift `main` already had, run `pbx_members.py` on the old base's project too (`"$main_base"` instead of `"$branch_base"`) and compare the same files, and check whether the Tuist manifests changed: `git diff origin/main HEAD --stat -- firefox-ios/Tuist firefox-ios/Project.swift`.

Tuist drops a manifest path that matches nothing without a warning, so a missing resource only shows at runtime (the translations page in M1). List them:

```bash
python3 -I "$t/dead_manifest_paths.py" "$PWD"
```

## 4. Skipped tests that no longer exist (ticket 13)

Xcode ignores a skipped test that doesn't exist, so a renamed or deleted test stays in the scheme's skip list unnoticed. Uses the `our_members.tsv` from section 3.

```bash
python3 -I "$t/skipped_tests.py" "$PWD" "$t/our_members.tsv"
```

## 5. Strings users see from `Info.plist` (ticket 13)

A purpose string in `Info.plist` reaches users only in languages whose `InfoPlist.strings` lacks the key; languages without their own folder fall back to `en`.

```bash
bash "$t/plist_strings.sh" origin/main NSCameraUsageDescription | grep -E 'MISSING|Firefox'
```

## Helper scripts

### `blobs.sh`

```bash
#!/bin/bash
# Usage: blobs.sh <ref>... < paths
# Prints each path with the short blob id at every ref ("-" when absent).
refs=("$@")
while IFS= read -r f; do
  line="$f"
  for r in "${refs[@]}"; do
    b=$(git rev-parse -q --verify "$r:$f" 2>/dev/null || echo -)
    line="$line | $r=${b:0:8}"
  done
  echo "$line"
done
```

### `run_symbol_map.py`

```python
#!/usr/bin/env python3
"""Runs the 155.1 experiment's build_symbol_map.py unchanged, with its constants overridden.

Usage: run_symbol_map.py <repo> <old-ref> <new-ref> <manifest-dir> [extended]
<manifest-dir> holds ecosia_owned_files.txt and receives symbol-dependency-report.md.
"extended" widens the Firefox-core pathspecs to every firefox-ios module Ecosia code imports.
"""
import importlib.util
import sys
from pathlib import Path

here = Path(__file__).resolve().parent
spec = importlib.util.spec_from_file_location("bsm", here / "build_symbol_map.py")
bsm = importlib.util.module_from_spec(spec)
spec.loader.exec_module(bsm)

repo, old, new, manifest = sys.argv[1:5]
bsm.REPO = repo
bsm.OLD_TAG = old
bsm.NEW_TAG = new
bsm.MANIFEST_DIR = Path(manifest).resolve()
if len(sys.argv) > 5 and sys.argv[5] == "extended":
    bsm.CORE_PATHSPECS = bsm.CORE_PATHSPECS + [
        "firefox-ios/Providers", "firefox-ios/Account", "firefox-ios/RustFxA",
        "firefox-ios/Sync", "firefox-ios/Push", "firefox-ios/WidgetKit",
        "firefox-ios/Extensions", "firefox-ios/firefox-ios-tests/Tests/ClientTests",
    ]
bsm.main()
```

### `pbx_members.py`

```python
#!/usr/bin/env python3
"""List what each target of an Xcode project compiles and copies.

Usage: pbx_members.py <project.json> <synced-folder-listing>
  <project.json>: project.pbxproj converted with `plutil -convert json`.
  <synced-folder-listing>: `git ls-tree -r --name-only <ref> firefox-ios/` output, used to expand
  Xcode 16 synchronized folders (PBXFileSystemSynchronizedRootGroup) into files. Pass /dev/null
  for a project without them.
Prints one line per member: <target>\t<phase>\t<repo-relative path>
Paths are relative to the repository root (the project lives in firefox-ios/).
"""
import json
import posixpath
import sys
from pathlib import PurePosixPath

PROJECT_DIR = "firefox-ios"
COMPILED = {".swift", ".m", ".mm", ".c", ".cpp", ".h"}

doc = json.load(open(sys.argv[1]))
objs = doc["objects"]
listing = [l.strip() for l in open(sys.argv[2]) if l.strip()]

parent = {}
for oid, o in objs.items():
    for child in o.get("children", []):
        parent[child] = oid
root_group = objs[doc["rootObject"]]["mainGroup"]


def resolve(oid):
    """Repo-relative path of a file reference or group, or None when it isn't in the source tree."""
    o = objs[oid]
    tree = o.get("sourceTree", "<group>")
    own = o.get("path", "")
    if tree == "SOURCE_ROOT":
        return str(PurePosixPath(PROJECT_DIR) / own)
    if tree == "<absolute>":
        return own
    if tree != "<group>":
        return None
    if oid == root_group or oid not in parent:
        base = PROJECT_DIR
    else:
        base = resolve(parent[oid])
        if base is None:
            return None
    return str(PurePosixPath(base) / own) if own else base


def members_of_ref(ref):
    o = objs[ref]
    if o["isa"] == "PBXVariantGroup":
        return [p for c in o.get("children", []) if (p := resolve(c))]
    p = resolve(ref)
    return [p] if p else []


PHASES = {
    "PBXSourcesBuildPhase": "sources",
    "PBXResourcesBuildPhase": "resources",
    "PBXCopyFilesBuildPhase": "copy",
}

out = set()
for oid, o in objs.items():
    if o["isa"] != "PBXNativeTarget":
        continue
    name = o["name"]
    for ph in o.get("buildPhases", []):
        phase = objs[ph]
        kind = PHASES.get(phase["isa"])
        if not kind:
            continue
        for bf in phase.get("files", []):
            ref = objs[bf].get("fileRef")
            if not ref:
                continue
            for p in members_of_ref(ref):
                out.add((name, kind, p))
    for g in o.get("fileSystemSynchronizedGroups", []):
        folder = resolve(g)
        excluded = set()
        for ex in objs[g].get("exceptions", []):
            exo = objs[ex]
            if exo.get("target") == oid:
                excluded |= {f"{folder}/{m}" for m in exo.get("membershipExceptions", [])}
        for f in listing:
            if f.startswith(folder + "/") and f not in excluded:
                kind = "sources" if PurePosixPath(f).suffix in COMPILED else "resources"
                out.add((name, kind, f))

for t, k, p in sorted({(t, k, posixpath.normpath(p)) for t, k, p in out}):
    print(f"{t}\t{k}\t{p}")
```

### `compare.py`

```python
#!/usr/bin/env python3
"""Compare what upstream's Xcode project and Ecosia's Tuist project put into each target.

Usage: compare.py <upstream_members.tsv> <our_members.tsv> <our_files.txt> <ecosia_created.txt>
  *_members.tsv: output of pbx_members.py (target, phase, path)
  our_files.txt: files tracked on the branch (git ls-files firefox-ios/)
  ecosia_created.txt: files the branch adds on top of the upstream base
Sections:
  1 sources upstream compiles into a target we also build, which we compile elsewhere or nowhere
  2 sources we compile that upstream compiles into a different target, or into none
  3 sources we compile into more than one target
  4 resources: duplicate output names within one of our targets
  5 resources upstream copies into a target we build, which we don't copy there
  6 resources we copy that upstream doesn't copy into that target
"""
import collections
import posixpath
import sys

up_tsv, our_tsv, our_files_txt, created_txt = sys.argv[1:5]


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
for (k, p), ots in ours.items():
    if k == "sources" and len(ots) > 1:
        s3.append(f"{p}\tours:{','.join(sorted(ots))}\tupstream:{','.join(sorted(up.get(('sources', p), set()))) or '-'}")
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
```

### `dead_manifest_paths.py`

```python
#!/usr/bin/env python3
"""List path strings in the Tuist manifests that match no file (Tuist drops them without a warning).

Usage: dead_manifest_paths.py <repo-root>
Checks every string literal that looks like a path (contains "/" or a file extension) in
firefox-ios/Project.swift and firefox-ios/Tuist/ProjectDescriptionHelpers/*.swift, relative to
firefox-ios/. Globs (*, **, {a,b}) count as live when they match at least one file.
"""
import glob
import itertools
import os
import re
import sys

root = os.path.join(sys.argv[1], "firefox-ios")
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
    for lineno, line in enumerate(open(path), 1):
        code = line.split("//", 1)[0]
        for s in literal.findall(code):
            if "/" not in s or not pathlike.match(s) or s.startswith(("$(", "http")):
                continue
            if not matches(s):
                dead += 1
                print(f"{os.path.relpath(path, sys.argv[1])}:{lineno}: {s}")
print(f"{dead} manifest paths match nothing", file=sys.stderr)
sys.exit(1 if dead else 0)
```

### `skipped_tests.py`

```python
#!/usr/bin/env python3
"""List skipped tests in Schemes+Ecosia.swift that name no existing test class or method.

Usage: skipped_tests.py <repo-root> <our_members.tsv>
  our_members.tsv: pbx_members.py output for the generated project (decides which files each
  unit-test target compiles).
Exits 1 when an entry is stale.
"""
import re
import sys
from pathlib import Path

root = Path(sys.argv[1])
scheme = (root / "firefox-ios/Tuist/ProjectDescriptionHelpers/Schemes+Ecosia.swift").read_text()

targets = re.search(r"unitTestTargets: \[TestableTarget\] = \[(.*?)\]", scheme, re.S).group(1)
targets = set(re.findall(r'"(\w+)"', targets))
block = re.search(r"skippedTests: \[String\] = \[(.*?)\n    \]", scheme, re.S).group(1)
entries = [re.search(r'"([^"]+)"', l).group(1) for l in block.splitlines()
           if re.match(r'\s*"', l)]

sources = set()
for line in open(sys.argv[2]):
    t, k, p = line.rstrip("\n").split("\t")
    if t in targets and k == "sources" and p.endswith(".swift"):
        sources.add(p)

classes = {}
for p in sources:
    text = (root / p).read_text(errors="ignore")
    for m in re.finditer(r"^\s*(?:final\s+|open\s+|public\s+|@MainActor\s+)*class\s+(\w+)\s*:", text, re.M):
        classes.setdefault(m.group(1), []).append(text)

stale = 0
for e in entries:
    cls, _, method = e.partition("/")
    method = method.rstrip("()")
    if cls not in classes:
        print(f"missing class: {e}")
        stale += 1
    elif method and not any(re.search(rf"func\s+{re.escape(method)}\s*\(", t) for t in classes[cls]):
        print(f"missing method: {e}")
        stale += 1
print(f"{len(entries)} skipped entries, {stale} stale, targets: {', '.join(sorted(targets))}", file=sys.stderr)
sys.exit(1 if stale else 0)
```

### `plist_strings.sh`

```bash
#!/bin/bash
# Usage: plist_strings.sh <ref> <key>
# For every Client/*.lproj on <ref>, prints the localized value of <key> in InfoPlist.strings, or
# "MISSING" when that language falls back to Info.plist.
ref=$1
key=$2
git ls-tree -d --name-only "$ref" firefox-ios/Client/ | grep '\.lproj$' | while read -r dir; do
  lang=$(basename "$dir" .lproj)
  value=$(git show "$ref:$dir/InfoPlist.strings" 2>/dev/null \
    | iconv -f "$(git show "$ref:$dir/InfoPlist.strings" 2>/dev/null | file -b --mime-encoding -)" -t utf-8 2>/dev/null \
    | grep -E "^\"?$key\"? *=" | head -1 | sed -E 's/^[^=]*= *"(.*)";.*/\1/')
  echo "$lang	${value:-MISSING}"
done
```
