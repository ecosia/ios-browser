# M0 publish checklist

Remote actions to take when Dario decides to publish M0. Everything up to here happened locally on `upgrade/firefox`; nothing has been pushed.

## Before pushing

- [x] **Add `-skipMacroValidation` to every CI `xcodebuild` that builds the app** (done on `upgrade/firefox` 2026-10-20): `.github/actions/perform_unit_tests/action.yml` (`build-for-testing`) and `perform_snapshot_tests.sh` (`build-for-testing`, around line 422), both of which now run on PRs into the branch. The upgrade brings the `ModifiedCopy` macro package, and an unattended Xcode stops with `Macro "ModifiedCopyMacros" … must be enabled before it can be used`. `verify.sh` already passes the flag.

## Push and protect

- [ ] Push `upgrade/firefox` to `origin`.
- [ ] A ruleset for `upgrade/firefox` (not classic protection, which cannot exempt the sync app), otherwise matching `main`:
  - no direct pushes;
  - PRs need an approving review, with the sync GitHub App as a bypass actor (bypass mode "pull requests only"), so clean syncs merge without a person. Unverified: whether auto-merge honours a bypass actor; the first clean sync shows it. If it waits, a person approves the sync PR (the app is its author, so anyone can);
  - the same required status checks as `main` (copy the check names from `main`'s protection in GitHub settings at publish time; `merge_tests.yml`, `swift_lint.yml`, `snapshot_tests.yml` and `snapshot_update_check.yml` now run on PRs into `upgrade/firefox`). **Leave the snapshot checks out of the required checks until M2** (Dario, 2026-10-19): snapshot differences on 155.1 are expected until ticket 11 triages them, and requiring them would block every PR, including the automatic sync PR, whose auto-merge would then never fire;
  - allowed merge methods: merge commit only (squash or rebase would break the shared history with `main`);
  - linear history **not** required (the branch takes merge commits from `main`).
- [ ] **Disable `assign-tech-lead-review.yml` right after pushing.** It is a Mozilla workflow kept byte-identical to upstream, so future Firefox upgrades merge its changes without conflicts. On non-draft, human-authored PRs into `upgrade/firefox` over 800 changed lines, it adds a label and requests Mozilla's tech leads as reviewers, which fails on Ecosia's repo. Sync PRs opened by the GitHub App are skipped (bot author).
  - GitHub cannot disable it yet: it lists a workflow only once it exists on the default branch or has run (checked 2026-10-20: not found).
  - To register it without effect, open a **draft** PR into `upgrade/firefox` (any one-line change). The workflow runs and skips its job, because it ignores drafts. Close the PR.
  - Then disable it: Actions → "Assign Tech Lead Review" in the sidebar → "…" → **Disable workflow**, or `gh workflow disable assign-tech-lead-review.yml --repo ecosia/ios-browser`.
- [ ] **`check-kingfisher-dependency.yml`: nothing to do until M5.** It only runs on a schedule or by hand, and both work only from the default branch, so it cannot run while `main` lacks the file. Disable it the same way right after the M5 migration brings it onto `main`.
- `contribution-guardrails.yml` and `security-pr-reminder.yml` can stay enabled: they only act on labels Ecosia does not use or on PRs that mention Bugzilla.

## CircleCI

- [ ] Nothing required. CircleCI's branch filters only gate deploy jobs (Firebase and BrowserStack ad-hoc builds on `main`, `develop`, `main-N`, `patch/*`; TestFlight on `beta*` tags), not PR checks. Pushes to `upgrade/firefox` therefore produce no ad-hoc builds; add the branch to those filters only when the team wants them (M5 beta at the latest).

## On `main`

- [x] Fix `firefox-ios/EcosiaTests/Account/Auth/AuthTests.swift:332`: done on `main` in #1342 (`322db779bf`), identical to `upgrade/firefox`'s `96cbca736c`.
- [x] Allow merge commits in the repository settings (done 2026-10-20). `main` stays squash-only through the ruleset "main: squash merges only" (id 25501329; repository admins can bypass, as with the classic protection) and its classic "Require linear history".
- [ ] Decide on the ruleset's `require_extra_approval_for_unattributed_changes`, which GitHub turned on by default when the ruleset was created; switching it off was not done (Settings → Rules → Rulesets).

## Main sync (step 6)

- [ ] Create a GitHub App for the sync (organisation owner, Settings → Developer settings → GitHub Apps):
  - repository permissions: Contents read and write, Pull requests read and write, Workflows read and write, Metadata read; nothing else;
  - no webhook; installable only on this account;
  - install it on `ecosia/ios-browser` only;
  - generate a private key.
  Pull requests opened with the default `GITHUB_TOKEN` do not trigger other workflows, so CI would never run on the sync PR; an app token does. Workflows write is needed because sync PRs often change `.github/workflows/`.
- [ ] Store the app's ID as the repository variable `UPGRADE_SYNC_APP_ID` and its private key as the repository secret `UPGRADE_SYNC_APP_PRIVATE_KEY`.
- [x] "Allow auto-merge" is on in the repository settings (checked 2026-10-20).
- [ ] Merge `.github/workflows/upgrade_main_sync.yml` into `main` through a normal PR, byte-identical to the copy on `upgrade/firefox` (any review change goes to both branches, or the first sync conflicts on this file) (it only runs on pushes to `main` when it lives there; it touches no app code). Push `upgrade/firefox` first: the workflow calls `firefox-ios/EcosiaUpgrade/tools/sync-main.sh` from that branch and does nothing while the branch is missing.

## Jira

- [ ] Update the M0 tickets (MOB-5026 to MOB-5032): action items and statuses, with links to the diary entries in `firefox-ios/EcosiaUpgrade/diary/157.md`.
