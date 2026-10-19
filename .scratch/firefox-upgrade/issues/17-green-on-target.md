# 17: Green build and tests on the target

**Jira:** [MOB-5043](https://ecosia.atlassian.net/browse/MOB-5043)
**Milestone:** M3 Move to Firefox 157
**Status:** ready-for-human
**Blocked by:** 16

## What to build

`upgrade/firefox` on the upgrade target builds, passes every automated check, and still honours every M1 product decision.

- `sh tuist-setup.sh`, build the `Ecosia` scheme, and archive once (some scheme and provisioning problems only appear when archiving).
- Unit tests, characterization tests, the feature configuration tests from ticket 10, and snapshot tests.
- Re-run the checks from tickets 12 and 14 against the new tree.
- Configure any new upstream Nimbus flag found in ticket 15 per its decision, and add a test for it.
- Update `UPSTREAM_BASE` to the target.

## Acceptance criteria

- [ ] Build, archive, unit, characterization, feature configuration and snapshot tests all pass in CI
- [ ] Symbol, missing-file and build-system checks are clean or triaged
- [ ] `UPSTREAM_BASE` records the target tag and hash
- [ ] A main sync after this ticket merges and passes
- [ ] Diary entry written; M3 is done when this ticket is
