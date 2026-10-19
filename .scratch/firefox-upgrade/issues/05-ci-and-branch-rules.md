# 05: CI and branch rules for `upgrade/firefox`

**Jira:** [MOB-5031](https://ecosia.atlassian.net/browse/MOB-5031)
**Milestone:** M0 Upgrade branch established
**Status:** ready-for-human
**Blocked by:** 01

## What to build

`upgrade/firefox` gets the same protection and checks as `main`.

Today the GitHub Actions workflows only trigger on PRs to specific branches. For example, `merge_tests.yml` triggers on `main`, `patch/**` and `develop`, so PRs into `upgrade/firefox` would run no unit tests. Add `upgrade/firefox` to the `pull_request.branches` of `merge_tests.yml`, `swift_lint.yml`, `snapshot_tests.yml` and `snapshot_update_check.yml`, and check the CircleCI config for the same.

Branch rules: no direct pushes, PRs need review, required status checks match `main`.

Firebase builds stay manual or label-triggered, as today; no new automation.

## Acceptance criteria

- [ ] A test PR into `upgrade/firefox` runs unit tests, SwiftLint and the snapshot checks
- [ ] Direct pushes to `upgrade/firefox` are rejected, and PRs need an approving review
- [ ] The trigger changes live on `upgrade/firefox` (pull request runs read the workflow from the merge commit, so `main` does not need them)
- [ ] Diary entry written
