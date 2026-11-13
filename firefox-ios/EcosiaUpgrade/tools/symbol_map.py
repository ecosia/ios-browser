#!/usr/bin/env python3
"""Flag Firefox types and methods that Ecosia's own Swift files use and the target release lacks.

Usage: symbol_map.py --target <ref> [--base <ref>] [--ref <ref>] [--files <list>] [--extended]
                     [--out <report.md>]

For every Ecosia-owned Swift file, collects the type names it references and the methods it calls,
and flags each one that is declared in Firefox code at the base but nowhere at the target. A name
that disappeared with no textual conflict near Ecosia's lines is exactly what a 3-way merge misses.

Comments and string literals are ignored on both sides: a name only mentioned in a comment is not
a reference, and a declaration inside an `/* Ecosia: */` block is not a declaration.

  --target    Firefox release to check against (a tag before the merge, the merged tree after)
  --base      Firefox release the Ecosia code was written against (default: UPSTREAM_BASE)
  --ref       tree holding the Ecosia files (default: HEAD)
  --files     Ecosia files to check (default: ecosia_owned_files.py for <ref>, against the
              UPSTREAM_BASE recorded at <ref>, or <base> when <ref> records none)
  --extended  also count types declared in Providers, Account, RustFxA, Sync, Push, WidgetKit,
              Extensions and ClientTests as Firefox code (the default knows Client, BrowserKit,
              Shared and Storage only)
  --out       write the Markdown report there instead of stdout

A heuristic triage list, not a verdict: no type checker, so a common method name renamed on an
unrelated class flags every call, and a changed signature with the same name is not caught.

Exit codes: 0 nothing flagged, 1 flags to triage, 2 could not run, 64 usage error.
"""

import re
import sys
from pathlib import Path

sys.dont_write_bytecode = True
sys.path.insert(0, str(Path(__file__).resolve().parent))

import ecosia_owned_files  # noqa: E402
import source_scan  # noqa: E402
import upgrade_common as uc  # noqa: E402

CORE_FOLDERS = ["firefox-ios/Client", "BrowserKit/Sources", "firefox-ios/Shared", "firefox-ios/Storage"]
EXTENDED_FOLDERS = ["firefox-ios/Providers", "firefox-ios/Account", "firefox-ios/RustFxA",
                    "firefox-ios/Sync", "firefox-ios/Push", "firefox-ios/WidgetKit",
                    "firefox-ios/Extensions", "firefox-ios/firefox-ios-tests/Tests/ClientTests"]

# Swift, Foundation and UIKit names too generic to be a useful signal.
STOPLIST = set("""
String Int Bool Double Float CGFloat CGRect CGSize CGPoint Array Dictionary
Set Optional Any AnyObject Data URL URLRequest URLSession Error NSError
UIView UIViewController UIColor UIImage UIButton UILabel UIStackView
UITableView UITableViewCell UICollectionView UICollectionViewCell
UIScrollView UIWindow UIEdgeInsets UIFont NSObject NSAttributedString
DispatchQueue NotificationCenter Notification Bundle Codable Equatable
Hashable Identifiable ObservableObject Published State Binding View Text
VStack HStack ZStack Image Color Font Task MainActor Sendable Void
Result Void True False Self Type Never Character Sequence Collection
IndexPath NSLayoutConstraint UIStackViewDistribution UIStackViewAlignment
JSONEncoder JSONDecoder UserDefaults FileManager Thread OperationQueue
UUID Locale TimeZone Calendar DateFormatter Date TimeInterval
""".split())

TYPE_DECL = re.compile(r"\b(?:class|struct|enum|protocol|typealias|actor)\s+([A-Za-z_][A-Za-z0-9_]*)")
FUNC_DECL = re.compile(r"\bfunc\s+([A-Za-z_][A-Za-z0-9_]*)")
TYPE_REF = re.compile(r"\b([A-Z][A-Za-z0-9_]{2,})\b")
METHOD_CALL = re.compile(r"\.([a-zA-Z_][A-Za-z0-9_]*)\s*\(")


def firefox_declarations(ref, folders, root):
    """(type names, func names) declared in live Firefox Swift code at `ref`."""
    listing = uc.git("ls-tree", "-r", "-z", "--name-only", ref, "--", *folders, cwd=root)
    paths = [p for p in listing.split("\0")
             if p.endswith(".swift") and "Ecosia" not in p]
    types, funcs = set(), set()
    for text in uc.read_blobs(ref, paths, root).values():
        code = source_scan.code_only(text)
        types.update(TYPE_DECL.findall(code))
        funcs.update(FUNC_DECL.findall(code))
    return types, funcs


def main():
    parser = uc.Parser(description=__doc__.split("\n")[1])
    parser.add_argument("--target", required=True)
    parser.add_argument("--base")
    parser.add_argument("--ref", default="HEAD")
    parser.add_argument("--files")
    parser.add_argument("--extended", action="store_true")
    parser.add_argument("--out")
    args = parser.parse_args()

    root = uc.repo_root()
    base = uc.base_ref(args.base, root)
    target = uc.resolve_ref(args.target, root)
    ref = uc.resolve_ref(args.ref, root)
    folders = CORE_FOLDERS + (EXTENDED_FOLDERS if args.extended else [])

    if args.files:
        try:
            files = [l.strip() for l in open(args.files) if l.strip()]
        except OSError as e:
            uc.die(f"cannot read {args.files}: {e}", uc.USAGE)
    else:
        # Ecosia's files are what <ref> adds on top of its own Firefox base, which is not <base>
        # when checking a merged tree against the release the Ecosia code was written for.
        own_base = uc.upstream_base(root, at=ref) or base
        files = ecosia_owned_files.owned_files(own_base, ref, root)

    print(f"symbol_map: collecting Firefox declarations at {base} and {target}", file=sys.stderr)
    types_old, funcs_old = firefox_declarations(base, folders, root)
    types_new, funcs_new = firefox_declarations(target, folders, root)
    print(f"symbol_map: {len(types_old)} -> {len(types_new)} types, "
          f"{len(funcs_old)} -> {len(funcs_new)} funcs", file=sys.stderr)

    sources = uc.read_blobs(ref, files, root)
    report, flagged_files, flagged_refs = [], 0, 0
    for path in files:
        if path not in sources:
            continue
        code = source_scan.code_only(sources[path])
        local = set(TYPE_DECL.findall(code))
        used_types = (set(TYPE_REF.findall(code)) - STOPLIST - local) & types_old
        missing_types = sorted(t for t in used_types if t not in types_new)
        called = set(METHOD_CALL.findall(code)) & funcs_old
        missing_methods = sorted(m for m in called if m not in funcs_new)
        if missing_types or missing_methods:
            flagged_files += 1
            flagged_refs += len(missing_types) + len(missing_methods)
            report.append(f"## {path}")
            if missing_types:
                report.append(f"- **Types no longer declared:** {', '.join(missing_types)}")
            if missing_methods:
                report.append(f"- **Methods no longer declared:** {', '.join(missing_methods)}")
            report.append("")

    header = [
        "# Ecosia symbol-dependency report",
        "",
        f"{len(sources)} Ecosia files at `{ref}`, checked against Firefox declarations at `{base}` "
        f"(base) and `{target}` (target), in {', '.join(f'`{f}`' for f in folders)}.",
        "Flags every type or method an Ecosia file uses that is declared at the base and nowhere at "
        "the target. A triage list: open each file and the upstream change before acting.",
        "",
        f"**Result: {flagged_files} of {len(sources)} files flagged, {flagged_refs} references.**",
        "",
    ]
    text = "\n".join(header + report) + "\n"
    if args.out:
        Path(args.out).write_text(text)
        print(f"symbol_map: report at {args.out}", file=sys.stderr)
    else:
        sys.stdout.write(text)
    print(f"symbol_map: {flagged_files} files flagged, {flagged_refs} references", file=sys.stderr)
    return uc.FAILED if flagged_refs else uc.OK


if __name__ == "__main__":
    sys.exit(main())
