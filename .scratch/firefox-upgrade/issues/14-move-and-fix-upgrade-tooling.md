# 14: Move and fix the upgrade tooling

**Jira:** [MOB-5040](https://ecosia.atlassian.net/browse/MOB-5040)
**Milestone:** M3 Move to Firefox 157
**Status:** ready-for-agent
**Blocked by:** 01

## What to build

The experiment's tooling (`firefox-ios/Tuist/upgrade/rebase-manifest-155.1/` on `origin/firefox-upgrade-155.1`) moved to `firefox-ios/EcosiaUpgrade/tools/`, made reusable for any upgrade target, and written so an agent can run it later: plain command-line scripts, readable output, non-zero exit code on failure.

Known defects to fix:

- `build_intent_diffs.sh` hard-codes `cd /Users/jehmann/workspace/ios-browser`. Resolve the repo root with `git rev-parse --show-toplevel`.
- It diffs against `firefox-v147.2`, which is ambiguous in some clones (a local branch has the same name) and isn't our real upstream base anyway. Read the base from `UPSTREAM_BASE` (ticket 03) and always use `refs/tags/...`.
- The input list `core_modified_files.txt` missed at least `NimbusFeatureFlagLayer.swift` and `BrowserKit/Package.swift`. Generate it from the tree by scanning for `Ecosia:` markers, instead of maintaining it by hand.
- Ecosia markers inside `/* Ecosia: */` blocks need comment-aware scanning: a plain `grep` cannot tell a live declaration from a commented-out one (experiment trap 8).
- Add the checks ticket 12 ran by hand: the Ecosia file-set difference, and the Xcode-project versus Tuist source-list diff.

## Acceptance criteria

- [ ] Tooling lives in `firefox-ios/EcosiaUpgrade/tools/`, outside every Tuist target, with a README listing each script, its inputs and outputs
- [ ] No hard-coded paths; base and target come from `UPSTREAM_BASE` and a parameter
- [ ] Running the manifest generator against `firefox-v155.1` on `upgrade/firefox` reproduces the experiment's file list plus the two known gaps
- [ ] Each script exits non-zero on a failed check
- [ ] Diary entry written
