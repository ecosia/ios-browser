# 12: Symbol-dependency and missing-file checks

**Jira:** [MOB-5038](https://ecosia.atlassian.net/browse/MOB-5038)
**Milestone:** M2 Verification baseline
**Status:** ready-for-agent
**Blocked by:** 02

## What to build

Two whole-tree checks that catch silent losses a green build cannot. Both found real problems in the 155.1 experiment.

1. **Missing Ecosia files.** List every Ecosia-created file on `main` and on `upgrade/firefox`, and diff the two sets in both directions. In the experiment, `MultiplyImpact.swift` disappeared with no conflict and no build error (ticket 19, §9h).
2. **Symbol dependencies.** Re-run the symbol-dependency check (`build_symbol_map.py` from the experiment's manifest) against `upgrade/firefox`, and triage every flag.
3. **Build-system drift.** Diff the source and resource lists upstream's `Client.xcodeproj` compiles against what Tuist globs, in both directions (traps 4 and 5 from the experiment).

## Acceptance criteria

- [ ] The Ecosia file sets match, or each difference is explained
- [ ] Every symbol-dependency flag is triaged as true positive (fixed) or false positive (with a reason)
- [ ] The build-system diff shows no file compiled into the wrong target and no duplicated resources
- [ ] The commands used are written down so ticket 14 can turn them into scripts
- [ ] Diary entry written
