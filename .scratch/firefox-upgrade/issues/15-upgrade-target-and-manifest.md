# 15: Fix the upgrade target and build its manifest

**Jira:** [MOB-5041](https://ecosia.atlassian.net/browse/MOB-5041)
**Milestone:** M3 Move to Firefox 157
**Status:** ready-for-human
**Blocked by:** 03, 14

## What to build

The decision on which Firefox release we move to, and the inventory that guides the move.

1. **Fix the upgrade target:** the latest Firefox release tag on the day this ticket starts (`firefox-v157.0` on 2026-10-01; `157.1` may have shipped by then). Record it in the diary. Releases that ship afterwards wait for the next upgrade.
2. **Change inventory:** what Firefox changed between `firefox-v155.1` and the target, release by release, in the style of the 147 → 155.1 analysis: user-facing features, new and retired Nimbus flags, architectural changes.
3. **Intent-diff manifest and conflict-risk ranking:** run the tooling from ticket 14 to rank every Ecosia-customized file by upstream churn, and flag new upstream features that need a product decision.

## Acceptance criteria

- [ ] Upgrade target recorded in the diary, with the date it was fixed
- [ ] Change inventory written, with every new user-facing feature or Nimbus flag marked keep, out, or "needs product decision"
- [ ] Any "needs product decision" item has an answer from product before ticket 16 starts
- [ ] Intent-diff manifest and conflict-risk ranking generated for the target
- [ ] Diary entry written
