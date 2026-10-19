# 29: Release impact assessment and recommendation

**Jira:** [MOB-5055](https://ecosia.atlassian.net/browse/MOB-5055)
**Milestone:** M6 Release-watching agent
**Status:** needs-triage
**Blocked by:** 14, 27

## What to build

For a release, from `UPSTREAM_BASE` to the new tag, the agent runs the upgrade tooling and writes one report:

- Change inventory: user-facing features, new and retired Nimbus flags, architectural changes, security fixes.
- Every new feature or flag marked keep, out, or needs product decision, based on the product decisions so far.
- The Ecosia-customized files the release touches, ranked by conflict risk, plus a `git merge-tree` dry run showing predicted conflicts.
- Symbol-dependency and missing-file checks against the new release.
- Matches against the trap list.
- A recommendation, take now or wait and bundle, with its reasons, following the criteria in the design ADR (ticket 27).

The agent changes no code; its only outputs are the report and a diary entry.

## Acceptance criteria

- [ ] Report format agreed with the team and product
- [ ] Backtest: run on the 155.1 to 157 hop, and the predicted conflicts and decisions match what the diary recorded
- [ ] Every recommendation states its reasons and the criteria it applied
- [ ] The agent writes nothing to the code; only the report and a diary entry
- [ ] Diary entry written
