# 16: Tracking Protection vertical

**What to build:** Ecosia's tracking-protection UI customization continues to behave correctly. This is the smallest, most isolated vertical — a good one to complete first once ticket 10 lands, to validate the overall reconciliation approach before tackling the larger verticals.

**Blocked by:** 10

**Status:** done

- [x] The tracking-protection view controller's Ecosia customization is reconciled per the intent-diff manifest
- [x] Confirmed this is distinct from the separate legacy Enhanced Tracking Protection details screen upstream deleted — that deletion doesn't affect this file (see Findings §4)

## Verification standard (applies to every AC in this ticket)

Nothing in the repo compiles until ticket 19 — the rebase is in progress with hundreds of files
still carrying conflict markers inside the same `Client` target, so `xcodebuild` fails on the first
unresolved file and never reaches this vertical. **Do not read "compiles", "passes" or "behaves
correctly" in an AC as requiring a build or a test run.** They are satisfied by the static
substitutes the earlier tickets established:

- `xcrun swiftc -parse <file>` on every file touched, plus a check that no conflict markers remain.
- A symbol-dependency sweep: every non-SDK symbol the reconciled code references still resolves in
  the tree (this is what catches the silent losses a clean auto-merge produces).
- `cd firefox-ios && tuist generate --no-open` when the file set or module imports changed.
- `swiftlint --strict` — run it bare from the repo root, not with explicit paths (see ticket 10's
  tooling notes for why).
- `plutil -lint` for plists/`.strings`; `bin/nimbus-fml.sh` for Nimbus manifest work.

Actual compilation and test execution are ticket 19's job. State plainly in your findings which ACs
were verified statically rather than executed, and hand any runtime risk you could not settle to
ticket 19.


---

# Findings (session completing ticket 16)

**Outcome:** 7 conflicted files resolved and 3 auto-merged files corrected. Unmerged count 454 → 447.
No commits. Not the smallest vertical the ticket description expected — the Ecosia customization is one
coherent removal, but upstream rewrote a great deal around it.

## 1. Scope

| State | File | Resolution |
| --- | --- | --- |
| `UU` 2 | `Client/Frontend/TrackingProtection/TrackingProtectionViewController.swift` | see §2 |
| `UU` 1 | `Client/ContentBlocker/ContentBlocker.swift` | **now byte-identical to upstream** — see §3 |
| `UU` 1 | `…/ClientTests/ContentBlockerTests.swift` | upstream |
| `UU` 1 | `…/ClientTests/Coordinators/EnhancedTrackingProtectionCoordinatorTests.swift` | upstream |
| `UU` 1 | `…/ClientTests/TrackingProtectionTests/TrackingProtectionModelTests.swift` | upstream |
| `UU` 1 | `…/ClientTests/TrackingProtectionTests/TrackingProtectionStateTests.swift` | upstream |
| `UU` 3 | `…/XCUITests/TrackingProtectionTests.swift` | upstream — trap 6 |
| `M ` | `…/ClientTests/TrackingProtectionTests/{BlockedTrackersTableViewControllerTests,CertificatesViewModelTests}.swift` | upstream (staleness only) |
| `M ` | `…/UITests/TrackingProtectionTests.swift` | upstream — `Tests/UITests` is **also not a Tuist target here**, same class as XCUITests |

`grep -rn "Tests/UITests" firefox-ios/Tuist firefox-ios/Project.swift` is empty, so trap 6 covers
`Tests/UITests` as well as `Tests/XCUITests`. Worth remembering for later tickets.

## 2. TrackingProtectionViewController — one removal, re-adapted to a rewritten screen

Ecosia's whole customization is: **remove the "Firefox is on Guard" connection-details header**
(`connectionDetailsHeaderView`) and re-round/re-anchor the trackers container that becomes the panel's
top card. Upstream rewrote a lot around it in 155.1 — certificate fetching moved to
`CertificatesFetcher`, `ScreenAction` became `ComponentAction`,
`enhancedTrackingProtectionMenuDelegate` was renamed `trackingProtectionMenuDelegate`, and a Nova
background alpha and new accessibility identifiers were added.

Both conflicts were the removal meeting an expanded upstream call:

- `connectionStatusView.setConnectionStatus(…)` gained `isInternalCertErrorURL:` and
  `isManuallyTrusted:`. Took upstream's three lines; Ecosia's comment block opens immediately after.
- `setupAccessibilityIdentifiers()` gained `scrollView`/`baseView` identifiers and a five-argument
  `headerContainer.setupAccessibility(…)`, and `connectionDetailsHeaderView.setupAccessibilityIdentifiers(…)`
  grew from 1 argument to 5. Kept upstream's new live lines and commented out **only** the
  `connectionDetailsHeaderView` call, updated to its new 5-argument form so the removal records what it
  is removing.

Verified the removal is complete with a Swift-comment-aware scan of the file: **zero live references**
to `connectionDetailsHeaderView` or `setupConnectionHeaderView` outside comment blocks (13 textual hits,
all inside `/* Ecosia: … */` or `//`). Both `TPMenuUX.UX` constants Ecosia's replacement uses
(`connectionDetailsHeaderMargins`, and now `newStyleCornerRadius`) still exist. The renamed delegate has
no stale references anywhere in the tree.

**One deliberate visual adaptation — please sanity-check.** Ecosia rounds the top corners of
`trackersConnectionContainer` with the flat `TPMenuUX.UX.viewCornerRadius` (8). In 155.1 upstream gives
the panel's top card — the very `connectionDetailsHeaderView` Ecosia removes — and its sibling
`toggleView` a `newStyleCornerRadius` of **24 on iOS 26**. Left as-is, Ecosia's panel would show an 8pt
top card next to a 24pt toggle card on iOS 26. Switched to `TPMenuUX.UX.newStyleCornerRadius`, which is
defined as `24` on iOS 26 and falls back to `viewCornerRadius` below it — so **no change below iOS 26**,
and consistency with upstream's own styling on it. This is the one place in the ticket where pixels move.

## 3. ContentBlocker.swift — upstream adopted Ecosia's fix

Ecosia had marked `listsCompiledCount` / `errorCount` as `nonisolated(unsafe)` so the `@Sendable`
closures in `compileListsNotInStore` could capture them. **Upstream 155.1 made exactly the same change**
(`nonisolated(unsafe) var listsCompiledCount = 0` at 155.1 vs plain `var` at 147.2), which is why the
conflict's HEAD side was empty and the `nonisolated(unsafe)` lines had already auto-merged in below it.
Ecosia's `/* Ecosia: … */` block was therefore a phantom documenting a change upstream now makes itself,
so it was removed — and the file is **byte-identical to upstream**, the ideal outcome. Textbook trap 4.

## 4. AC-2 confirmed: the deleted legacy screen is a different directory

Upstream deleted five files from `Client/Frontend/Browser/EnhancedTrackingProtection/`
(`EnhancedTrackingProtectionDetailsVC`, `…DetailsVM`, `…VC`, `…VM`, `SlideoverPresentationController`)
plus `EnhancedTrackingProtectionMenuVMTests`. Ecosia's customized file lives in
`Client/Frontend/TrackingProtection/` — a different directory, untouched by those deletions. All six
are gone from disk and **nothing in the tree references any of the deleted types**.

One near-miss worth recording: `CertificatesHandler.swift` also shows as `D`, and
`CertificatesHandlerTests.swift` still references `CertificatesHandler` — which looked like a stale
reference. It is not: upstream **renamed the file** to `CertificatesHelpers/CertificatesFetcher.swift`
and kept the `CertificatesHandler` class inside it. Both the class and its test are present and clean.

## 5. Test files taken from upstream

Every Ecosia delta across the six test files was unmarked staleness — sync `setUp`/`tearDown`,
class-level `@MainActor`, `@unchecked Sendable`, `AppContainer.shared.reset()` in place of
`DependencyHelperMock().reset()`, dropped assertions, and
`LegacyFeatureFlagsManager.shared.initializeDeveloperFeatures` (**class confirmed deleted**). Checked
first, per trap 4d: `git diff firefox-v147.2 c5afa25d3b` mentions "Ecosia" **zero times** in all six.

The production types they cover — `TrackingProtectionModel`, `TrackingProtectionState`,
`EnhancedTrackingProtectionCoordinator` — are each **byte-identical to upstream with a zero-line Ecosia
delta**, and `ContentBlocker.swift` now is too (§3). So this is the same "tests covering unchanged
upstream files" case as tickets 13–15.

Two of them would not have compiled:

- **`TrackingProtectionModelTests`** — `TrackingProtectionModel.init` gained a required first parameter
  `userDefaults:`; Ecosia's call omits it.
- **`ContentBlockerTests`** — upstream's rewrite injects a `MockNimbusFeatureFlags` and stubs
  `ContentBlocker.shared.adBlockerListFetcher` (`AdBlockerListFetcherProtocol`, new in 155.1 with the
  remote-settings ad-blocker work). Ecosia's version predates all of it.

And `TrackingProtectionStateTests` loses nothing: Ecosia's five tests are **renames** of upstream's
(`testDismissSurveyAction` ← `testDismissTrackingProtectionAction`,
`testShowTrackingProtectionSettingsAction` ← `testNavigateToSettingsAction`, and so on) with some
assertions dropped. Upstream 155.1 has all five plus `testUpdateBlockedTrackerStatsAction` and
`testUpdateConnectionStatusAction`, so taking upstream restores two tests and several assertions.

## 6. Verification — all static, nothing executed

- `xcrun swiftc -parse` on all 10 touched files — clean; zero conflict markers in the group.
- A Swift-comment-aware scan of `TrackingProtectionViewController.swift` confirming no live reference to
  the removed header (§2) — a plain `grep` would have reported 13 false positives here.
- `intent-diff-check.py` over the group. Every `missing` entry maps to a decision above: the
  `newStyleCornerRadius` adoption and the expanded a11y comment in the view controller, the phantom
  comment removed from `ContentBlocker.swift`, and the staleness dropped from the test files.
- `symcheck.py` over the same set — every unresolved name is UIKit/WebKit/XCTest/KIF noise.
- `cd firefox-ios && tuist generate --no-open` — **Success**.
- `swiftlint lint --strict --quiet`, bare from the repo root — **no violation in any ticket-16 file**.
  Non-vendor count 83 → 82.

## 7. Handed to ticket 19

1. **The iOS 26 corner radius in §2** is the only pixel change in this ticket. It matches upstream's
   treatment of the card it replaces, but it is worth one look on an iOS 26 simulator.
2. **`ContentBlocker` now conforms to `Notifiable` and observes `.remoteSettingsDidSync`** to refresh
   ad-blocker lists from remote settings — new upstream behaviour Ecosia inherits unchanged. Given
   ticket 07 set `adBlocker: enabled: true`, this path is live for Ecosia and has never run here.
3. **`ContentBlockerTests` compiles two live rule-store round trips** (`removeAllRulesInStore`,
   `compileListsNotInStore`). Upstream raised the timeouts; Ecosia's older copy had raised them too.
   If these turn flaky in 19, the timeout is the knob.
