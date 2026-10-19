# 11: Run snapshot tests against production references

**Jira:** [MOB-5037](https://ecosia.atlassian.net/browse/MOB-5037)
**Milestone:** M2 Verification baseline
**Status:** ready-for-human
**Blocked by:** 02

## What to build

Screen-by-screen evidence of how the upgrade differs from production, using the existing `EcosiaSnapshotTests` suite. No new tests or reference images are needed.

The reference images live in the `SnapshotArtifacts` submodule (`firefox-ios/EcosiaTests/SnapshotTests/SnapshotArtifacts`, from `ecosia/ios-snapshot-tests-files`, tracked with git-lfs). CI keeps them in line with `main`, so they already represent production. The 155.1 experiment couldn't run them only because git-lfs wasn't installed locally; CI fetches them with a deploy key (MOB-4907).

1. Run `EcosiaSnapshotTests` on `upgrade/firefox`, locally and in CI (ticket 05 adds the CI trigger).
2. For every failing snapshot, decide: regression (fix it, or file it under ticket 21) or intended change from the upgrade (record it in the diary, and in the Miro test plan if QA should see it).

Do not update reference images for the upgrade branch until every difference is triaged.

## Acceptance criteria

- [ ] `EcosiaSnapshotTests` runs on `upgrade/firefox` locally and in CI
- [ ] Every failing snapshot is triaged as regression or intended, with intended ones listed in the diary
- [ ] Regressions are fixed or have their own ticket
- [ ] Diary entry written
