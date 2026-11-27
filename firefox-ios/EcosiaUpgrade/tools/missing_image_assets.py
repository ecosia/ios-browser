#!/usr/bin/env python3
"""Lists the image names in `StandardImageIdentifiers` / `ImageIdentifiers` that no asset catalog
of the Client app provides.

`UIImage(named:)` returns nil for a name without an asset, and most callers fall back to no image,
so a missing asset is a silent blank icon. The 147 upgrade replaced Firefox's `Images.xcassets`
with Ecosia's, and every icon Firefox added later (`summarizerLarge` in 160.1, MOB-5309) arrives as
an identifier without an asset.

  missing_image_assets.py [--ref <ref> | --worktree] [--allow <file>]

  --ref       tree to check (default: HEAD)
  --worktree  check the files on disk instead (for a merge in progress)
  --allow     names missing on purpose, "<name><TAB><reason>" per line
              (default: missing-image-assets.allow next to this script)

Prints each name without an asset as `<name>\t<identifier>\t<verdict>`, where the verdict is
`allowed: <reason>` or `MISSING`. Allow-list entries that now have an asset, or that no identifier
uses any more, are reported on stderr so the list can be trimmed.

Exit codes: 0 nothing unexplained is missing, 1 something is, 2 could not run, 64 usage error.
"""

import os
import re
import sys
from pathlib import Path

sys.dont_write_bytecode = True
sys.path.insert(0, str(Path(__file__).resolve().parent))

import source_scan as ss  # noqa: E402
import upgrade_common as uc  # noqa: E402

IDENTIFIER_FILES = (
    "BrowserKit/Sources/Common/Constants/StandardImageIdentifiers.swift",
    "firefox-ios/Client/Application/ImageIdentifiers.swift",
)

# Asset catalogs bundled into the Client app (Tuist: Targets+Client.swift). `UIImage(named:)`
# without a bundle, which BrowserKit and Client use for these names, looks only in the app bundle.
# OnboardingKit is the exception: it loads the `ImageIdentifiers.Onboarding` names from its own
# module bundle, so its catalog counts too.
CATALOG_ROOTS = ("firefox-ios/Client/Assets/", "firefox-ios/Client/Ecosia/",
                 "BrowserKit/Sources/OnboardingKit/")

ASSET_DIR = re.compile(r"\.xcassets/(?:[^/]+/)*?([^/]+)\.(?:imageset|symbolset)(?:/|$)")
DECLARATION = re.compile(r"static\s+let\s+(\w+)\s*(?::\s*String\s*)?=\s*\"([^\"]+)\"")


def identifiers(text):
    """[(dotted Swift name, asset name)] for each live `static let x = "name"` in `text`. Lines
    inside comments (an `/* Ecosia: */` block) don't count."""
    kinds = ss.classify(text, "swift")
    code = ss.keep(text, kinds, ss.CODE)
    found = []
    for m in DECLARATION.finditer(text):
        if kinds[m.start()] != ss.CODE:
            continue
        found.append((_scope(code, m.start()) + m.group(1), m.group(2)))
    return found


def _scope(code, pos):
    """`Outer.Inner.` for the enums or structs enclosing `pos` in comment-free `code`."""
    stack, depth = [], 0
    for m in re.finditer(r"\b(?:enum|struct|class|extension)\s+(\w+)[^{]*\{|\{|\}", code[:pos]):
        if m.group(0) == "}":
            depth -= 1
            while stack and stack[-1][1] > depth:
                stack.pop()
        else:
            depth += 1
            if m.group(1):
                stack.append((m.group(1), depth))
    return "".join(f"{name}." for name, _ in stack)


def asset_names(paths):
    """Asset names of every imageset or symbolset among `paths` (files inside the catalogs)."""
    names = set()
    for path in paths:
        if not path.startswith(CATALOG_ROOTS):
            continue
        for m in ASSET_DIR.finditer(path):
            names.add(m.group(1))
    return names


def read_allow(path):
    allowed = {}
    for number, line in enumerate(Path(path).read_text().splitlines(), 1):
        if not line.strip() or line.startswith("#"):
            continue
        name, sep, reason = line.partition("\t")
        if not sep or not reason.strip():
            uc.die(f"{path}:{number}: expected '<name><TAB><reason>'", uc.USAGE)
        allowed[name.strip()] = reason.strip()
    return allowed


def check(ids, assets, allowed):
    """(rows, failed, stale): one row per identifier without an asset, whether any is unexplained,
    and the allow-list names that no longer need an entry."""
    rows, failed, seen = [], False, set()
    for swift_name, name in sorted(ids, key=lambda pair: (pair[1], pair[0])):
        if name in assets:
            continue
        seen.add(name)
        if name in allowed:
            verdict = f"allowed: {allowed[name]}"
        else:
            verdict, failed = "MISSING", True
        rows.append((name, swift_name, verdict))
    stale = sorted(set(allowed) - seen)
    return rows, failed, stale


def main():
    tools = Path(__file__).resolve().parent
    parser = uc.Parser(description=__doc__.split("\n\n")[0])
    where = parser.add_mutually_exclusive_group()
    where.add_argument("--ref", default="HEAD")
    where.add_argument("--worktree", action="store_true")
    parser.add_argument("--allow", default=str(tools / "missing-image-assets.allow"))
    args = parser.parse_args()
    if not os.path.isfile(args.allow):
        uc.die(f"no allow list at {args.allow}", uc.USAGE)

    root = uc.repo_root()
    if args.worktree:
        texts = {p: (root / p).read_text() for p in IDENTIFIER_FILES if (root / p).exists()}
        paths = []
        for top in CATALOG_ROOTS:
            for dirpath, dirnames, _ in os.walk(root / top):
                rel = os.path.relpath(dirpath, root)
                paths.extend(f"{rel}/{d}/" for d in dirnames)
    else:
        ref = uc.resolve_ref(args.ref, root)
        texts = uc.read_blobs(ref, list(IDENTIFIER_FILES), root)
        paths = uc.git("ls-tree", "-r", "--name-only", "-z", ref, "--", *CATALOG_ROOTS,
                       cwd=root).split("\0")
    missing_files = [p for p in IDENTIFIER_FILES if p not in texts]
    if missing_files:
        uc.die(f"not found: {', '.join(missing_files)}")

    ids = [pair for path in IDENTIFIER_FILES for pair in identifiers(texts[path])]
    rows, failed, stale = check(ids, asset_names(paths), read_allow(args.allow))
    for row in rows:
        print("\t".join(row))
    for name in stale:
        print(f"stale allow entry: {name} has an asset or no identifier uses it", file=sys.stderr)
    unexplained = sum(1 for row in rows if row[2] == "MISSING")
    print(f"{len(ids)} identifiers, {len(rows)} without an asset, {unexplained} unexplained",
          file=sys.stderr)
    return uc.FAILED if failed else uc.OK


if __name__ == "__main__":
    sys.exit(main())
