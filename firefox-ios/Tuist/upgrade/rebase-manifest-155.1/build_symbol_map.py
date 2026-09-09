#!/usr/bin/env python3
"""
Heuristic symbol-dependency check: for every Ecosia-owned Swift file, find the
Firefox-core type/method names it references, and flag any that no longer
exist anywhere in the Firefox-core tree at firefox-v155.1.

This is a static, regex-based approximation (no real Swift type-checker), so
treat it as a high-recall triage list, not a proof: it will have some noise
(common short names, protocol conformance coincidences) but is very good at
catching the dangerous case a plain 3-way merge can miss entirely -- a symbol
Ecosia calls into that was quietly renamed or deleted somewhere else in the
tree, with no textual conflict anywhere near Ecosia's own lines.
"""
import re
import subprocess
import sys
from pathlib import Path

MANIFEST_DIR = Path(__file__).resolve().parent
REPO = str(MANIFEST_DIR.parents[3])  # firefox-ios/Tuist/upgrade/rebase-manifest-155.1 -> repo root
OLD_TAG = "firefox-v147.2"
NEW_TAG = "firefox-v155.1"

CORE_PATHSPECS = ["firefox-ios/Client", "BrowserKit/Sources", "firefox-ios/Shared", "firefox-ios/Storage"]

# Common Swift/Foundation/UIKit names too generic to be useful signal.
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

def run(cmd):
    return subprocess.run(cmd, cwd=REPO, shell=True, capture_output=True, text=True).stdout

def declared_symbols(tag):
    """All class/struct/enum/protocol/typealias names declared in the Firefox-core tree at `tag`, excluding Ecosia dirs."""
    out = run(
        f"git grep -h -oE '(class|struct|enum|protocol|typealias) [A-Za-z_][A-Za-z0-9_]*' "
        f"{tag} -- {' '.join(CORE_PATHSPECS)} ':(exclude)*/Ecosia/*' ':(exclude)*Ecosia*'"
    )
    names = set()
    for line in out.splitlines():
        m = re.search(r'(class|struct|enum|protocol|typealias) ([A-Za-z_][A-Za-z0-9_]*)', line)
        if m:
            names.add(m.group(2))
    return names

def declared_funcs(tag):
    out = run(
        f"git grep -h -oE 'func [A-Za-z_][A-Za-z0-9_]*' "
        f"{tag} -- {' '.join(CORE_PATHSPECS)} ':(exclude)*/Ecosia/*' ':(exclude)*Ecosia*'"
    )
    names = set()
    for line in out.splitlines():
        m = re.search(r'func ([A-Za-z_][A-Za-z0-9_]*)', line)
        if m:
            names.add(m.group(1))
    return names

def main():
    print("Collecting declared types at 147.1...", file=sys.stderr)
    types_old = declared_symbols(OLD_TAG)
    print(f"  {len(types_old)} types", file=sys.stderr)
    print("Collecting declared types at 155.1...", file=sys.stderr)
    types_new = declared_symbols(NEW_TAG)
    print(f"  {len(types_new)} types", file=sys.stderr)
    print("Collecting declared funcs at 147.1...", file=sys.stderr)
    funcs_old = declared_funcs(OLD_TAG)
    print(f"  {len(funcs_old)} funcs", file=sys.stderr)
    print("Collecting declared funcs at 155.1...", file=sys.stderr)
    funcs_new = declared_funcs(NEW_TAG)
    print(f"  {len(funcs_new)} funcs", file=sys.stderr)

    ecosia_files = [l.strip() for l in (MANIFEST_DIR / "ecosia_owned_files.txt").read_text().splitlines() if l.strip()]

    type_ref_re = re.compile(r'\b([A-Z][A-Za-z0-9_]{2,})\b')
    method_call_re = re.compile(r'\.([a-zA-Z_][A-Za-z0-9_]*)\s*\(')

    report_lines = []
    total_flagged = 0
    files_with_flags = 0

    for f in ecosia_files:
        path = Path(REPO) / f
        if not path.exists():
            continue
        try:
            src = path.read_text(errors="ignore")
        except Exception:
            continue

        type_refs = set(type_ref_re.findall(src)) - STOPLIST
        method_refs = set(method_call_re.findall(src))

        # A type reference is "Firefox-core" if it was declared in core at 147.1
        # but NOT declared inside this same Ecosia file itself (i.e. not a local type).
        local_decls = set(re.findall(r'\b(?:class|struct|enum|protocol|typealias)\s+([A-Za-z_][A-Za-z0-9_]*)', src))
        core_type_refs = (type_refs & types_old) - local_decls

        missing_types = sorted(t for t in core_type_refs if t not in types_new)

        # Method calls: only flag ones that existed as a declared func name somewhere
        # in core at 147.1 and have now vanished tree-wide at 155.1. High-recall,
        # noisy (common names like "reload", "close" will false-positive if ANY
        # instance in the whole tree was renamed) -- treat as a lead, not a verdict.
        core_method_refs = method_refs & funcs_old
        missing_methods = sorted(m for m in core_method_refs if m not in funcs_new)

        if missing_types or missing_methods:
            files_with_flags += 1
            total_flagged += len(missing_types) + len(missing_methods)
            report_lines.append(f"## {f}")
            if missing_types:
                report_lines.append(f"- **Possibly-removed/renamed types referenced:** {', '.join(missing_types)}")
            if missing_methods:
                report_lines.append(f"- **Possibly-removed/renamed methods called:** {', '.join(missing_methods)}")
            report_lines.append("")

    header = [
        "# Ecosia Symbol-Dependency Triage Report",
        "",
        f"Static heuristic scan of {len(ecosia_files)} Ecosia-owned files against the Firefox-core symbol table",
        f"at `{OLD_TAG}` (baseline) vs `{NEW_TAG}` (target). Flags any type or method name Ecosia references",
        "that existed in core at the baseline but can no longer be found anywhere in the core tree at the target.",
        "",
        "**This is a triage list, not a verdict.** Regex-based, no type-checker: false positives happen",
        "(a common method name like `reload` renamed on one unrelated class elsewhere flags everywhere it's",
        "called), and it can't catch a signature change that keeps the same name. Each flagged item still",
        "needs a human/agent to open the file and the corresponding upstream diff and confirm.",
        "",
        f"**Result: {files_with_flags} of {len(ecosia_files)} files have at least one flagged symbol, {total_flagged} flagged references total.**",
        "",
        "---",
        "",
    ]

    out_path = MANIFEST_DIR / "symbol-dependency-report.md"
    out_path.write_text("\n".join(header + report_lines))
    print(f"\nWrote report to {out_path}", file=sys.stderr)
    print(f"{files_with_flags} files flagged, {total_flagged} total flagged references", file=sys.stderr)

if __name__ == "__main__":
    main()
