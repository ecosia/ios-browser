# M0 publish checklist

Remote actions to take when Dario decides to publish M0. `upgrade/firefox` was built locally and pushed on 2026-10-20.

## Before pushing

- [x] **Add `-skipMacroValidation` to every CI `xcodebuild` that builds the app** (done on `upgrade/firefox` 2026-10-20): `.github/actions/perform_unit_tests/action.yml` (`build-for-testing`) and `perform_snapshot_tests.sh` (`build-for-testing`, around line 422), both of which now run on PRs into the branch. The upgrade brings the `ModifiedCopy` macro package, and an unattended Xcode stops with `Macro "ModifiedCopyMacros" … must be enabled before it can be used`. `verify.sh` already passes the flag.

## Push and protect

- [x] Push `upgrade/firefox` to `origin` (2026-10-20, at `d1a89b7803`).
- [x] A ruleset for `upgrade/firefox` (created 2026-10-20: "upgrade/firefox: merge commits, reviewed PRs", id 25503494; the sync app `Ecosia iOS Upgrade Sync` (id 5408346) bypasses its review rule for pull requests since 2026-10-21. "Execute Merge Tests" is required by a separate ruleset, "upgrade/firefox: required checks" (id 25534429), which only admins can bypass, so clean syncs wait for CI. Up to date is not required, because a sync PR's head is `main`. Documentation-only PRs never start the merge tests (`paths-ignore`), so their required check stays pending; an admin merges those with the bypass). Not classic protection, which cannot exempt the sync app; otherwise matching `main`:
  - no direct pushes;
  - PRs need an approving review, with the sync GitHub App as a bypass actor (bypass mode "pull requests only"), so clean syncs merge without a person. Unverified: whether auto-merge honours a bypass actor; the first clean sync shows it. If it waits, a person approves the sync PR (the app is its author, so anyone can);
  - the same required status checks as `main` (copy the check names from `main`'s protection in GitHub settings at publish time; `merge_tests.yml`, `swift_lint.yml`, `snapshot_tests.yml` and `snapshot_update_check.yml` now run on PRs into `upgrade/firefox`). **Leave the snapshot checks out of the required checks until M2** (Dario, 2026-10-19): snapshot differences on 155.1 are expected until ticket 11 triages them, and requiring them would block every PR, including the automatic sync PR, whose auto-merge would then never fire;
  - allowed merge methods: merge commit only (squash or rebase would break the shared history with `main`);
  - linear history **not** required (the branch takes merge commits from `main`).
- [x] **Mozilla workflows: nothing to disable before M5** (checked 2026-10-20). `assign-tech-lead-review.yml`, `contribution-guardrails.yml` and `security-pr-reminder.yml` use `pull_request_target`, which GitHub now runs only from the default branch's copy of a workflow file, and `check-kingfisher-dependency.yml` runs only on a schedule or by hand, both of which also need the default branch. None of them is on `main`, so none can run on `upgrade/firefox`. Evidence: draft PR #1345 into `upgrade/firefox` started only the `pull_request` checks, and GitHub does not list the four workflows. The files stay byte-identical to upstream, so future Firefox upgrades merge their changes without conflicts.
- [ ] **At M5, right after the migration brings these files onto `main`:** disable `assign-tech-lead-review.yml` (it requests Mozilla's tech leads on human PRs over 800 lines) and `check-kingfisher-dependency.yml` (it opens Kingfisher update PRs): Actions → workflow → "…" → **Disable workflow**, or `gh workflow disable <file> --repo ecosia/ios-browser`. `contribution-guardrails.yml` and `security-pr-reminder.yml` can stay enabled: they only act on labels Ecosia does not use or on PRs that mention Bugzilla.

## CircleCI

- [ ] Nothing required. CircleCI's branch filters only gate deploy jobs (Firebase and BrowserStack ad-hoc builds on `main`, `develop`, `main-N`, `patch/*`; TestFlight on `beta*` tags), not PR checks. Pushes to `upgrade/firefox` therefore produce no ad-hoc builds; add the branch to those filters only when the team wants them (M5 beta at the latest).

## On `main`

- [x] Fix `firefox-ios/EcosiaTests/Account/Auth/AuthTests.swift:332`: done on `main` in #1342 (`322db779bf`), identical to `upgrade/firefox`'s `96cbca736c`.
- [x] Allow merge commits in the repository settings (done 2026-10-20). `main` stays squash-only through the ruleset "main: squash merges only" (id 25501329; repository admins can bypass, as with the classic protection) and its classic "Require linear history".
- [x] The `main` ruleset's `require_extra_approval_for_unattributed_changes` is off, so the ruleset adds nothing to `main`'s protection beyond squash-only (2026-10-20).

## Main sync (step 6)

- [x] Create a GitHub App for the sync (2026-10-21: `Ecosia iOS Upgrade Sync`, app id 5408346, owned by `ecosia`) (organisation owner, Settings → Developer settings → GitHub Apps):
  - repository permissions: Contents read and write, Pull requests read and write, Workflows read and write, Metadata read; nothing else;
  - no webhook; installable only on this account;
  - install it on `ecosia/ios-browser` only;
  - generate a private key.
  Pull requests opened with the default `GITHUB_TOKEN` do not trigger other workflows, so CI would never run on the sync PR; an app token does. Workflows write is needed because sync PRs often change `.github/workflows/`.
- [x] Store the app's client ID as the repository variable `UPGRADE_SYNC_APP_CLIENT_ID` and its private key as the repository secret `UPGRADE_SYNC_APP_PRIVATE_KEY` (the earlier `UPGRADE_SYNC_APP_ID` was replaced on 2026-10-21, because `create-github-app-token` deprecated `app-id`).
- [x] No named owner: GitHub requests a review from `@ecosia/ios` on every PR into `upgrade/firefox`, sync PRs included, through the root `CODEOWNERS` on that branch (2026-10-21). The app cannot request team reviews itself without the organisation permission Members: read.
- [ ] **At M5:** decide whether `main` keeps the root `CODEOWNERS` (`* @ecosia/ios`) when `upgrade/firefox` becomes `main`.
- [x] "Allow auto-merge" is on in the repository settings (checked 2026-10-20).
- [x] Merge `.github/workflows/upgrade_main_sync.yml` into `main` through a normal PR (#1346, merged 2026-10-21; first sync #1348), byte-identical to the copy on `upgrade/firefox` (any review change goes to both branches, or the first sync conflicts on this file) (it only runs on pushes to `main` when it lives there; it touches no app code). Push `upgrade/firefox` first: the workflow calls `firefox-ios/EcosiaUpgrade/tools/sync-main.sh` from that branch and does nothing while the branch is missing.

## Jira

- [ ] Update the M0 tickets (MOB-5026 to MOB-5032): action items and statuses, with links to the diary entries in `firefox-ios/EcosiaUpgrade/diary/157.md`.
