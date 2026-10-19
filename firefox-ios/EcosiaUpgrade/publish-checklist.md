# M0 publish checklist

Remote actions to take when Dario decides to publish M0. Everything up to here happened locally on `upgrade/firefox`; nothing has been pushed.

## Before pushing

- [ ] **Remove the four Mozilla workflows that arrived with the 155.1 graft** (they are new in 155.1, so the experiment's deletion of Mozilla's workflows missed them). Three run on `pull_request_target`, which uses the workflow file from the PR's *base* branch, so they would run on every PR into `upgrade/firefox`, including the sync PR, with no repository guard:
  - `.github/workflows/assign-tech-lead-review.yml` (adds labels and requests reviews)
  - `.github/workflows/contribution-guardrails.yml` (comments on and closes PRs labelled `does-not-meet-guidelines` / `outside-approved-scope`)
  - `.github/workflows/security-pr-reminder.yml` (comments on every PR opened by a person)
  - `.github/workflows/check-kingfisher-dependency.yml` (weekly cron that opens Kingfisher update PRs; schedules only run on the default branch, so it starts firing once `main` migrates in M5)
- [ ] **Add `-skipMacroValidation` to CI's unit-test build** (`.github/actions/perform_unit_tests/action.yml`, `build-for-testing` step) on `upgrade/firefox`. The upgrade brings the `ModifiedCopy` macro package, and an unattended Xcode stops with `Macro "ModifiedCopyMacros" … must be enabled before it can be used`. `verify.sh` already passes the flag.

## Push and protect

- [ ] Push `upgrade/firefox` to `origin`.
- [ ] Branch protection for `upgrade/firefox` matching `main`:
  - no direct pushes;
  - PRs need an approving review;
  - the same required status checks as `main` (copy the check names from `main`'s protection in GitHub settings at publish time; `merge_tests.yml`, `swift_lint.yml`, `snapshot_tests.yml` and `snapshot_update_check.yml` now run on PRs into `upgrade/firefox`);
  - merge commits allowed;
  - linear history **not** required (the branch takes merge commits from `main`).

## CircleCI

- [ ] Nothing required. CircleCI's branch filters only gate deploy jobs (Firebase and BrowserStack ad-hoc builds on `main`, `develop`, `main-N`, `patch/*`; TestFlight on `beta*` tags), not PR checks. Pushes to `upgrade/firefox` therefore produce no ad-hoc builds; add the branch to those filters only when the team wants them (M5 beta at the latest).

## On `main`

- [ ] Fix `firefox-ios/EcosiaTests/Account/Auth/AuthTests.swift:332`: `renewCredentialsIfNeeded()` → `renewCredentials()`. `main` at `7137bd6c30` does not compile its tests (MOB-4861's new test against MOB-5082's rename). `upgrade/firefox` carries the same one-line fix (`96cbca736c`), so an identical fix on `main` merges cleanly.

## Main sync (step 6)

<!-- Items added in step 6. -->

## Jira

- [ ] Update the M0 tickets (MOB-5026 to MOB-5032): action items and statuses, with links to the diary entries in `firefox-ios/EcosiaUpgrade/diary/157.md`.
