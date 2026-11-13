# Upgrade tools

Command-line scripts for moving the app to a new Firefox release. Like everything in `EcosiaUpgrade/`, they are outside every Tuist target. When to run each check, and how to triage what it finds, is in [manual-checks.md](manual-checks.md).

## Conventions

- Run from anywhere inside the repository: each script finds the root with `git rev-parse --show-toplevel`.
- **Base:** the Firefox release the tree is built on, read from [`UPSTREAM_BASE`](../README.md#upstream_base). The scripts fail when the tag is missing or no longer points at the recorded hash. `--base` overrides it.
- **Target:** the Firefox release being upgraded to, always a parameter (`--target`).
- **Refs:** a bare Firefox tag name resolves to `refs/tags/...` first, because some clones also have a branch called `firefox-v147.2`.
- **Output:** results go to stdout, one item per line or as Markdown, and summaries go to stderr.
- **Exit codes:** `0` the check passed, `1` the check failed (the output lists what needs a look), `2` the script could not run (git failed, an input is missing), `64` usage error.
- Python scripts use the standard library only. Run them as `python3 -I <script>` or directly. They write no `__pycache__`.
- Tests: `python3 -I firefox-ios/EcosiaUpgrade/tools/tools.test.py` and `firefox-ios/EcosiaUpgrade/tools/sync-main.test.sh`.

## Before the merge: what Ecosia changed

### `core_modified_files.py`

Lists the Firefox files Ecosia modified, generated from the tree. It replaces the experiment's hand-kept `core_modified_files.txt`. A Firefox file is one that exists at the base. It counts as modified when it differs at `--ref` (rename detection off), and it is listed when it has an `Ecosia:` marker inside a comment. Markers inside string literals don't count.

- **Inputs:** `--base <ref>` (default: `UPSTREAM_BASE`), `--ref <ref>` (default: `HEAD`), `--list marked|unmarked|deleted` (default: `marked`), `--counts`.
- **Output:** paths on stdout, or `<path>\t<marker lines>` with `--counts`. `unmarked` lists the modified Firefox files without a marker. `deleted` lists the Firefox files that are gone at `--ref`. The summary on stderr gives the count of each.
- **Exit:** 0, or 2/64 when it cannot run.

### `ecosia_owned_files.py`

Lists the Swift files Ecosia created: everything in `Client/Ecosia`, `Ecosia` and `EcosiaTests`, plus every Swift file `--ref` adds on top of the base elsewhere. Tuist manifests and XCUITests are left out.

- **Inputs:** `--base`, `--ref` (as above).
- **Output:** paths on stdout.
- **Exit:** 0, or 2/64.

### `build_intent_diffs.sh`

Writes the intent-diff manifest, the diff of what Ecosia changed in each Firefox file. It is the ground truth of what must survive the merge.

- **Inputs:** `--out <dir>` (required), `--base`, `--ref`, `--target <ref>` (optional), `--files <list>` (optional; the default is `core_modified_files.py`'s list).
- **Output:** `<dir>/core_modified_files.txt`, `<dir>/intent-diffs/<path with / as _>.diff` (paths starting with a dot give hidden files), and `<dir>/intent-diff-index.tsv` with the columns `file`, `ecosia_markers`, `added_lines`, `removed_lines`, `status` (`OK`, `NO_BASELINE`, `MISSING`, `NO_ECOSIA_DIFF`), plus `upstream` (`changed`, `unchanged`, `deleted`) with `--target`. Files that upstream changed between the base and the target are the ones the merge can break.
- **Exit:** 0 when every listed file has an Ecosia diff, 1 when one doesn't (only possible with `--files`).

### `conflict_risk.py`

Ranks every Firefox file Ecosia customized by the risk the merge to `--target` brings: the marked, unmarked and deleted files of `core_modified_files.py`. It runs `git merge-tree` against the base, which writes nothing to the work tree.

- **Inputs:** `--target <ref>` (required), `--base`, `--ref` (as above), `--changed-only` (leave out the files upstream did not touch).
- **Output:** a TSV with the columns `rank`, `file`, `kind` (`marked`, `unmarked`, `deleted`), `risk`, `upstream_commits`, `upstream_lines`, `ecosia_lines`. `risk` is `conflict` (the merge stops on the file), `silent` (upstream changed it and the merge takes both sides without a conflict) or `none`. Files are ordered by risk, then by upstream churn (lines added plus removed from the base to the target), then by upstream commits. The summary on stderr counts each kind and risk.
- **Exit:** 0, or 2/64.

### `symbol_map.py`

Flags Firefox types and methods that Ecosia's own Swift files use and the target no longer declares. A name that disappeared with no conflict near Ecosia's lines is what a 3-way merge misses. Comments and strings are ignored on both sides, so a name only mentioned in a comment is no reference, and a declaration inside an `/* Ecosia: */` block is no declaration.

- **Inputs:** `--target <ref>` (required: a tag before the merge, `HEAD` after it), `--base`, `--ref`, `--files <list>` (default: `ecosia_owned_files.py` for `--ref` against its own `UPSTREAM_BASE`), `--extended` (also knows types in `Providers`, `Account`, `RustFxA`, `Sync`, `Push`, `WidgetKit`, `Extensions` and `ClientTests`), `--out <file>`.
- **Output:** a Markdown report, one section per flagged file.
- **Exit:** 0 when nothing is flagged, 1 when there are flags to triage. It is a heuristic: a common method name renamed on an unrelated class flags every call, and a changed signature with the same name is not caught.

## After the merge: what the merge lost or broke

### `missing_ecosia_files.sh`

Lists the files Ecosia created on `main` that the branch no longer has. A file that only Ecosia created has no upstream counterpart, so a merge can delete it without a conflict (in the 155.1 experiment, `MultiplyImpact.swift`).

- **Inputs:** `--main <ref>` (default: the merge base of `--ref` and `origin/main`), `--main-base <ref>` (default: the `UPSTREAM_BASE` on `--main`; `main` before the 157 upgrade has none, so pass `firefox-v147.2`), `--ref` (default: `HEAD`, compared against its own `UPSTREAM_BASE`), `--allow <file>` (default: [`missing-ecosia-files.allow`](missing-ecosia-files.allow)), `--branch-only`.
- **Output:** `<path>\t<blob on each side>\t<verdict>`. The verdict is `on branch` (the file is there, but upstream ships it too), `allowed: <reason>`, or `MISSING`.
- **Exit:** 0 when nothing unexplained is missing, 1 otherwise.

### `swallowed_declarations.py`

Finds functions declared only inside a comment that live code in the same file still calls. Upstream methods inserted where an `/* Ecosia: */` block opens end up inside the comment.

- **Inputs:** `--ref <ref>` (default: `HEAD`) or `--worktree` (for a merge in progress), plus optional repository-relative paths (default: every Swift file with an `Ecosia:` comment).
- **Output:** `<path>:<line>: <name>() is called here but declared only inside a comment (line N)`.
- **Exit:** 0 when nothing is found, 1 otherwise.

### `build_drift.sh`

Compares upstream's `Client.xcodeproj` with the project Tuist generates, target by target and build phase by build phase, then lists Tuist manifest paths that match nothing. Generate the project first with `./tuist-setup.sh --no-open`.

- **Inputs:** `--upstream <ref>` (default: `UPSTREAM_BASE`), `--keep <dir>` (keeps the intermediate files).
- **Output:** the six sections of `compare_targets.py`, then the output of `dead_manifest_paths.py`.
- **Exit:** 1 if any of these holds: a source is `LINKED` (see below), a resource name is duplicated within one target, or a manifest path is dead. 2 when there is no generated project. 0 otherwise.

It is built from three scripts that can also run on their own:

- **`pbx_members.py <project.pbxproj | project.json> [<listing>]`**: prints `<target>\t<sources|resources|copy>\t<path>` for every member of every target. `<listing>` is `git ls-tree -r --name-only <ref> firefox-ios/` and expands Xcode 16 synchronized folders. With `--dependencies <project>`, it prints `<target>\t<module>` for each framework or library a target depends on. Exits 0, or 2.
- **`compare_targets.py <upstream_members.tsv> <our_members.tsv> <our_files.txt> <ecosia_created.txt> <our_dependencies.tsv>`**: prints six sections: (1) sources upstream compiles into a target we build that we don't; (2) non-Ecosia sources we compile into a target upstream doesn't; (3) sources in more than one of our targets; (4) duplicate resource names in one target; (5) resources upstream copies that we don't; (6) non-Ecosia resources we copy that upstream doesn't. In section 3, `LINKED` marks a source compiled into two targets where one imports the other and upstream doesn't do the same. The type then exists in two modules and becomes ambiguous (ticket 12's RustFxA in Client and Account). Sharing a source between the app and its extensions, or between test targets, is how both projects work, so it isn't marked. Exits 1 when a row is `LINKED` or section 4 is non-empty.
- **`dead_manifest_paths.py [<repo-root>]`**: prints `<manifest>:<line>: <path>` for each path literal in `Project.swift` and `Tuist/ProjectDescriptionHelpers/*.swift` that matches no file. Paths in comments are skipped. Exits 1 when there is one. Tuist drops such paths without a warning. Run it on a set-up checkout, because some paths, like `Client/Generated`, only exist after bootstrap.

### `skipped_tests.py [<our_members.tsv>]`

Lists the entries in `Schemes+Ecosia.swift`'s `skippedTests` that name no existing test class or method in the scheme's unit-test targets. Xcode ignores those entries silently.

- **Inputs:** the generated project, or a `pbx_members.py` listing of it.
- **Output:** `missing class: <entry>` or `missing method: <entry>`.
- **Exit:** 0 when every entry exists, 1 otherwise.

### `plist_strings.sh [--ref <ref>] [--word <word>] <key>...`

Shows what users see for `Info.plist` strings, such as purpose strings, in every `Client/*.lproj` language: the `InfoPlist.strings` value, or `(Info.plist) <value>` when the language's file lacks the key.

- **Output:** `<key>\t<language>\t<value>`. The offending lines are repeated on stderr.
- **Exit:** 0 when no value contains `<word>` (default: `Firefox`), 1 otherwise.

## Main sync and verification

- **`sync-main.sh [--base-ref <ref>]`**: merges `main` into the upgrade branch. See its header for exit codes. Tested by `sync-main.test.sh`.
- **`verify.sh`**: generates the project, builds, runs the unit tests and lints the way CI does, then runs `check-feature-config.sh`. See its header for exit codes.
- **`check-feature-config.sh [--fml <path to nimbus-fml>]`**: checks Ecosia's decisions about Firefox's features (translations on; hosted summarizer, App Attest, Google Lens, Quick Answers, VPN, ad blocker and Nova off) on the developer, beta and release Nimbus channels. Unit tests (`FeatureConfigurationTests`) only see developer.
  - **Input:** `nimbus-features/*.yaml`, and the `nimbus-fml` binary a build caches under `firefox-ios/build/nimbus/`.
  - **Output:** one line per decision that doesn't hold: `<channel> <feature> <variable>: expected X, found Y`.
  - **Exit:** 0 when every decision holds, 1 when one doesn't, 2 when `nimbus-fml` fails or a feature is missing from its output, 64 on a usage error or when there's no `nimbus-fml` binary yet.

## Shared modules

- **`upgrade_common.py`**: git access, reading `UPSTREAM_BASE`, ref resolution and exit codes. Shell scripts call `upgrade_common.py base [<ref>]` and `upgrade_common.py ref <ref>` to resolve refs the same way.
- **`source_scan.py`**: comment- and string-aware reading. It splits a file into code, comment and string characters: Swift with nested `/* */`, multi-line, raw and interpolated strings; C-like files; `#` comments; XML comments.
- **`missing-ecosia-files.allow`**: the Ecosia files that are missing on purpose, each with a reason.
