# 02: Resolve sync conflicts and get a green build

**Jira:** [MOB-5028](https://ecosia.atlassian.net/browse/MOB-5028)
**Milestone:** M0 Upgrade branch established
**Status:** ready-for-human
**Blocked by:** 01

## What to build

The first main sync: merge today's `origin/main` into `upgrade/firefox`, resolve conflicts, and get the app and the unit tests passing.

A dry run on 2026-10-01 conflicted in 4 files: `TabManagerImplementation.swift` (3 hunks), `TabManager.swift` (1), `MockTabManager.swift` (1) and `Gemfile.lock` (2). `main` keeps moving, so recount at the time of the merge. The conflicting tab-management changes come from the invisible auth tab work on `main` (MOB-4867, MOB-4990), so `InvisibleTabSession`, `TabAutoCloseManager` and `TabManager+InvisibleTab` need checking too, even where they merged cleanly.

Also check the 9 Firefox-core files `main` changed since the squash point, which merged without conflicts but may not behave correctly against 155.1: `AppDelegate.swift`, `BrowserViewController.swift`, `BrowserViewController+WebViewDelegates.swift`, `TopTabDisplayManager.swift`, `WallpaperManager.swift`, `TabManager.swift`, `TabManagerImplementation.swift`, `MockTabManager.swift`, `.taskcluster.yml`.

## Acceptance criteria

- [ ] `origin/main` merged into `upgrade/firefox` through a reviewed PR, with no conflict markers left
- [ ] `sh tuist-setup.sh` succeeds and the `Ecosia` scheme builds
- [ ] The `EcosiaBeta` unit test plan passes, including the 155.1 characterization tests (`EcosiaTests/FirefoxUpgradeCharacterizationTests.swift`) and `InvisibleTabManagerTests`
- [ ] `swiftlint --strict` is clean from the repo root
- [ ] Diary entry written, listing every conflict and how it was resolved (removal, substitution or addition)
