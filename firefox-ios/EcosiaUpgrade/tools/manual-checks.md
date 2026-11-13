# Upgrade checks

Tickets 12 (MOB-5038) and 13 (MOB-5039) ran these checks by hand. Ticket 14 (MOB-5040) turned them into the scripts in this folder: inputs, outputs and exit codes are in the [README](README.md). This page says when to run each script and how to triage what it finds. The results of the hand-run checks are in the diary ([159.md](../diary/159.md), the 2026-11-04 entries for 12 and 13).

Run from the repository root. `<target>` is the Firefox release tag being merged, for example `firefox-v157.0`.

## Before the merge

```bash
tools=firefox-ios/EcosiaUpgrade/tools
out=$(mktemp -d)
$tools/build_intent_diffs.sh --out "$out/manifest" --target <target>
$tools/symbol_map.py --target <target> --extended --out "$out/symbols.md"
$tools/conflict_risk.py --target <target> --changed-only > "$out/conflict-risk.tsv"
$tools/core_modified_files.py --list unmarked > "$out/unmarked.txt"
git merge-tree --write-tree --name-only --merge-base="refs/tags/$(cut -f1 firefox-ios/EcosiaUpgrade/UPSTREAM_BASE)" HEAD <target>
```

- `intent-diff-index.tsv`: rows with `upstream` = `changed` are the Ecosia changes the merge can break. Keep the manifest folder until the merge is done; it is the reference for every conflict.
- `conflict-risk.tsv`: the order to work through the customized files. `silent` rows merge without a conflict and still need their intent diff checked: in 159.1 the Google Lens YAML took upstream's `enabled: true` on `beta` this way.
- `unmarked.txt`: Firefox files that differ from the base without an `Ecosia:` comment. Their changes still have to survive, but no marker shows where. Add a marker, or record why the change isn't Ecosia's.
- The `merge-tree` output lists the files that will conflict.

## After the merge

```bash
$tools/missing_ecosia_files.sh                     # once main has UPSTREAM_BASE; before that add --main-base firefox-v147.2
$tools/swallowed_declarations.py --worktree        # during conflict resolution; without the flag on a commit
$tools/symbol_map.py --base <old base> --target HEAD --extended
./tuist-setup.sh --no-open && $tools/build_drift.sh
$tools/skipped_tests.py
$tools/plist_strings.sh NSCameraUsageDescription NSMicrophoneUsageDescription NSFaceIDUsageDescription
git merge-tree --write-tree --name-only HEAD origin/main   # what the next main sync conflicts on
```

## Triage

### Missing Ecosia files

Check each `MISSING` path on every side (the blob columns). If the deletion is deliberate, add it to `missing-ecosia-files.allow` with a reason a reviewer can check. Otherwise restore the file from `main`. `on branch` is not a loss: upstream ships a file with the same path (for example `AGENTS.md`).

### Symbol flags

```bash
# where the name is declared now (Ecosia's own copies count)
git grep -n -E '(class|struct|enum|protocol|typealias|actor) NAME[^A-Za-z0-9_]' HEAD -- firefox-ios BrowserKit/Sources
git grep -n -E 'func NAME[^A-Za-z0-9_]' HEAD -- firefox-ios BrowserKit/Sources
# how the flagged file uses it
git grep -n -w NAME HEAD -- <flagged file>
# for a method flag: which Firefox declaration disappeared
git grep -n 'func NAME' <old base> -- firefox-ios/Client BrowserKit/Sources firefox-ios/Shared firefox-ios/Storage
```

Known false positives from ticket 12: `append` and `animate`, which are the standard library's and UIKit's; `position` (SwiftUI); `BookmarkItem` (Ecosia's own `Ecosia.BookmarkItem`); and `share` and `setTextWithoutSearching` (Ecosia's own methods). `SimpleToast` is a real removal that Ecosia vendored into `Client/Ecosia/UI/Toast/`.

### Build-system drift

`LINKED` rows in section 3 (one source in two of our modules, one importing the other) and every row in section 4 (duplicate resource names in one target) break builds or make a type ambiguous, so `build_drift.sh` fails on them. Before removing a source from a target, search for "already declared" and module-qualified names: a double compile leaves workarounds in other files (ticket 13). The other sections are drift to read. To tell drift the upgrade brought from drift `main` already had, run `build_drift.sh --upstream <old base>` and compare. Also check whether the Tuist manifests changed: `git diff origin/main HEAD --stat -- firefox-ios/Tuist firefox-ios/Project.swift`.

A dead manifest path changes nothing in the build. If a file was moved, though, it's missing from its target, and that only shows at runtime: in M1, the translations page wasn't bundled.

### Skipped tests

Remove a stale entry, or point it at the renamed test.

### `Info.plist` strings

A purpose string reaches users only in languages whose `InfoPlist.strings` lacks the key. Languages without their own folder fall back to `en`.
