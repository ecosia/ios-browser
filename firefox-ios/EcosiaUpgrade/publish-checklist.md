# M0 publish checklist

Remote actions to take when Dario decides to publish M0. Everything up to here happened locally on `upgrade/firefox`; nothing has been pushed.

## Before pushing

- [ ] **Disable two Mozilla workflows in GitHub's Actions settings** (Actions → workflow → "Disable workflow"); the files stay byte-identical to upstream so future Firefox upgrades merge their changes without conflicts:
  - `assign-tech-lead-review.yml` (`pull_request_target`): on non-draft PRs over 800 changed lines it adds a label and requests Mozilla's tech leads as reviewers, which fails on Ecosia's repo; the sync PR is often that big.
  - `check-kingfisher-dependency.yml` (weekly cron): inert while `upgrade/firefox` is not the default branch; disable it before `main` migrates in M5 at the latest, or it tries to open Kingfisher update PRs.
  - Unverified: GitHub may only list a workflow for disabling after it has run or once it is on the default branch, so the first large PR into `upgrade/firefox` may trigger `assign-tech-lead-review` once.
  - `contribution-guardrails.yml` and `security-pr-reminder.yml` can stay enabled: they only act on labels Ecosia does not use or on PRs that mention Bugzilla.
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

- [ ] Create the `UPGRADE_SYNC_TOKEN` repository secret: a PAT or GitHub App token with `contents: write` and `pull_requests: write`. Pull requests opened with the default `GITHUB_TOKEN` do not trigger other workflows, so CI would never run on the sync PR.
- [ ] Enable "Allow auto-merge" in the repository settings if it is off (the workflow enables auto-merge with a merge commit on clean syncs).
- [ ] Confirm the `OWNER` GitHub handle in `.github/workflows/upgrade_main_sync.yml` (currently `dariocarlomagno`); conflicting syncs request that person's review.
- [ ] Merge `.github/workflows/upgrade_main_sync.yml` into `main` through a normal PR (it only runs on pushes to `main` when it lives there; it touches no app code). Push `upgrade/firefox` first: the workflow calls `firefox-ios/EcosiaUpgrade/tools/sync-main.sh` from that branch and does nothing while the branch is missing.

## Jira

- [ ] Update the M0 tickets (MOB-5026 to MOB-5032): action items and statuses, with links to the diary entries in `firefox-ios/EcosiaUpgrade/diary/157.md`.
