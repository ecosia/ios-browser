#!/usr/bin/env python3
"""List the Swift files Ecosia created: the input of symbol_map.py.

Usage: ecosia_owned_files.py [--base <ref>] [--ref <ref>]

Every Swift file in Ecosia's own folders (Client/Ecosia, Ecosia, EcosiaTests), plus every Swift
file <ref> adds on top of the upstream base elsewhere. Tuist manifests and XCUITests are left out:
they don't call into the app's Firefox code.

  --base  Firefox release the tree is built on (default: UPSTREAM_BASE, as refs/tags/...)
  --ref   tree to list (default: HEAD)

Prints one path per line. Exits 0, or 2/64 when it cannot run.
"""

import re
import sys
from pathlib import Path

sys.dont_write_bytecode = True
sys.path.insert(0, str(Path(__file__).resolve().parent))

import upgrade_common as uc  # noqa: E402

OWN_FOLDERS = ("firefox-ios/Client/Ecosia/", "firefox-ios/Ecosia/", "firefox-ios/EcosiaTests/")
LEFT_OUT = re.compile(r"^firefox-ios/(Project|Tuist)\.swift$|^firefox-ios/Tuist/|/XCUITests/")


def owned_files(base, ref, root):
    tracked = uc.git("ls-tree", "-r", "-z", "--name-only", ref, "--", *OWN_FOLDERS, cwd=root)
    files = {p for p in tracked.split("\0") if p.endswith(".swift")}
    added = uc.changed_files(base, ref, root, "A")
    files |= {p for p in added if p.endswith(".swift") and not LEFT_OUT.search(p)}
    return sorted(files)


def main():
    parser = uc.Parser(description=__doc__.split("\n")[1])
    parser.add_argument("--base")
    parser.add_argument("--ref", default="HEAD")
    args = parser.parse_args()
    root = uc.repo_root()
    base = uc.base_ref(args.base, root)
    ref = uc.resolve_ref(args.ref, root)
    files = owned_files(base, ref, root)
    for path in files:
        print(path)
    print(f"ecosia_owned_files: {base}..{ref}: {len(files)} Swift files", file=sys.stderr)
    return uc.OK


if __name__ == "__main__":
    sys.exit(main())
