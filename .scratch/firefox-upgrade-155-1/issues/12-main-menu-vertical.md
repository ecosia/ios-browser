# 12: Main Menu vertical

**What to build:** The site/app menu continues to expose Ecosia's customizations correctly alongside the new menu entries upstream introduced for this release (Ad Blocker, Report Broken Site).

**Blocked by:** 10

**Status:** done

- [x] Every Ecosia customization in the main-menu file group is reconciled per the intent-diff manifest (menu configuration utility, coordinator, middleware, navigation destination)
- [x] The new upstream menu entries appear or don't appear consistent with the ticket 07 flag decisions (Ad Blocker present without a badge, no VPN entry) — **with one wording correction, see Findings §4**
- [x] Any main-menu-specific tests affected by this area are updated alongside the production code

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


## Inherited findings — one hard dependency

**`MenuNavigationDestination.swift` (currently `UU`, 2 conflicts) must keep BOTH sides' enum cases:** upstream's `.readerView` and `.translatePage`, **and** Ecosia's `.readingList`, `.help`, `.reportIssue`.

This is not optional. Ticket 04 already resolved `MainMenuMiddleware.swift`'s telemetry `switch`, which has **no `default:` clause**, keeping both upstream's `.readerView` case and Ecosia's `case .readingList, .help, .reportIssue: break`. If this enum drops either group, that switch stops being exhaustive and fails to compile.

Also: ticket 07 set the Ad Blocker flags so the **menu entry appears without a badge** (`enabled: true`, `badge-enabled: false`), which matches this ticket's AC. The badge is gated in `MainMenuViewController` on `isEnabled(.adBlocker) && isEnabled(.adBlockerBadge)`; the entry itself is separate and not suppressed.

**Google Lens is already decided — do not re-open it.** Upstream's Google Lens code stays intact and
reconciled; it is suppressed by flag, not commented out. `nimbus-features/googleLensFeature.yaml` is
`enabled: false` on every channel (ticket 10), and every entry point additionally requires
`defaultEngine.isGoogleEngine`, which is false for Ecosia. If you touch `AddressBarState.googleLensAction`,
`ToolbarMiddleware.isGoogleLensAvailable`, or the menu/settings surfaces that reference it, keep upstream's
code and its gates as-is — reconcile, don't remove.

## Scope snapshot (captured at handover, 496 files unmerged overall)

| Conflicts | File |
| --- | --- |
| 1 | `BrowserKit/Sources/MenuKit/MenuCell.swift` |
| 1 | `BrowserKit/Sources/MenuKit/MenuInfoCell.swift` |
| 2 | `Client/Frontend/Browser/MainMenu/MainMenuConfigurationUtility.swift` |
| 2 | `Client/Frontend/Browser/MainMenu/MainMenuCoordinator.swift` |
| **4** | `Client/Frontend/Browser/MainMenu/Redux/MenuNavigationDestination.swift` — **note: 4, not the 2 the inherited findings above say.** Recount before planning. |
| 1 | `Client/Frontend/Browser/MainMenu/Views/MainMenuViewController.swift` |
| 1 | `firefox-ios-tests/.../ClientTests/MainMenu/MainMenuCoordinatorTests.swift` |
| 2 | `firefox-ios-tests/.../ClientTests/MainMenu/MainMenuMiddlewareTests.swift` |
| 1 | `firefox-ios-tests/.../ClientTests/MainMenu/MainMenuStateTests.swift` |
| 3 | `firefox-ios-tests/.../ClientTests/Telemetry/MainMenuTelemetryTests.swift` |

**Auto-merged (`M `) files in this group — sweep these too, they are where the real defects were in
tickets 10 and 11:** `Redux/MainMenuMiddleware.swift` (ticket 04 resolved it; re-verify it still
matches), `Client/Helpers/MenuBuilderHelper.swift`,
`firefox-ios-tests/.../ClientTests/MainMenu/MainMenuViewControllerTests.swift`.

Ecosia also owns eight `menu-*.imageset` entries under `Client/Ecosia/UI/Ecosia.xcassets/` (staged
clean, `A `). If a menu entry's `iconName` resolves to one of those, keep it — those assets exist only
in the Ecosia catalog, which is the same class of dependency as ticket 11's `elipsis` and `incognito`.

---

# Findings (session completing ticket 12)

**Outcome:** all 10 conflicted files in the group resolved and staged, plus 3 auto-merged/clean files
corrected. Unmerged count 496 → 486. No commits.

## 1. Conflicted files — resolution per file

| File | Conflicts | Type | Resolution |
| --- | --- | --- | --- |
| `BrowserKit/Sources/MenuKit/MenuCell.swift` | 1 | substitution | Upstream's new `theme.isNova ? iconAccent : iconAccentBlue` line moved inside the `/* Ecosia: … */` block; Ecosia's `textAccent` tint kept. |
| `BrowserKit/Sources/MenuKit/MenuInfoCell.swift` | 1 | substitution | Same shape — upstream's two new Nova-ternary lines commented, Ecosia's `textInverted`/`textAccent` badge tint kept. |
| `MainMenuConfigurationUtility.swift` | 2 | addition + substitution | (a) `Icons`: took upstream's `share = shareApple` rename and new `reportBrokenSite`, kept Ecosia's `help`/`reportIssue`. Ecosia never customized `share`, so the rename wins. (b) `getSiteSection` gained a `localeProvider:` argument — took upstream's call, kept Ecosia's `getLibrarySection` substitution for `getHorizontalTabsSection`. |
| `MainMenuCoordinator.swift` | 2 | addition | Kept both: upstream's `.readerView` / `.translatePage` cases and Ecosia's `.readingList` / `.help` / `.reportIssue`. |
| `Redux/MenuNavigationDestination.swift` | **4** (snapshot correct, inherited findings' "2" was wrong) | addition | All four are pure both-sides additions. Enum and `allCasesForTests` both carry all 22 cases. |
| `Views/MainMenuViewController.swift` | 1 | substitution | Upstream's 4-line Nova background block commented inside Ecosia's marker; Ecosia's `layer1` line kept. |
| `MainMenuCoordinatorTests.swift` | 1 | substitution | `tearDown`: kept Ecosia's synchronous convention (precedent: ticket 00's `SettingsCoordinatorTests`) but folded in upstream's `resetStore()` and used `DependencyHelperMock().reset()`, which is *literally* `AppContainer.shared.reset()` (see `DependencyHelperMock.swift:88`). Without `resetStore()` the mock store would leak across test classes. |
| `MainMenuMiddlewareTests.swift` | 2 | — | **Took upstream 155.1 verbatim.** See §2. |
| `MainMenuStateTests.swift` | 1 | addition | Kept Ecosia's inline `AccountData(title: "Test", subtitle: nil)` (the auto-merge had already deleted the `let accountData` binding upstream's side referenced — taking upstream's side unchanged would have been an undefined-symbol error) and added upstream's new `translationConfiguration: nil` argument. |
| `MainMenuTelemetryTests.swift` | 3 | — | **Took upstream 155.1 verbatim.** See §2. |

## 2. Two test files taken wholesale from upstream

`MainMenuMiddlewareTests.swift` and `MainMenuTelemetryTests.swift` both carried an Ecosia "delta" that
is not a customization at all: Ecosia's copies are the *pre-rewrite upstream files*, from before Mozilla
migrated these suites to `MockGleanWrapper`. There is not one `// Ecosia:` marker in either, and the
squash's net effect on `MainMenuMiddlewareTests.swift` is `715 lines → 34` — it deletes the entire
telemetry suite and leaves a single `testDismissMenuAction`.

Taking Ecosia's side would also have been *incoherent* after the auto-merge: the class header merged to
Ecosia's form (no `StoreTestUtility` conformance, no `mockGleanWrapper`/`mockStore` properties, no
`setupStore()`) while the conflict region held upstream's body, which needs all of them. This is the
trap-2 shape again — the damage was in the auto-merged header, not the marked region.

Both files are now byte-identical to `firefox-v155.1`, which restores ~30 telemetry assertions.
Their dependencies were checked and all resolve: `MockGleanWrapper`, `MockStoreForMiddleware`,
`StoreTestUtilityHelper`, `WebCompatReporterTelemetry`, `MainMenuTelemetry(gleanWrapper:)`,
`MainMenuMiddleware(telemetry:webCompatTelemetry:)`, `mainMenuProvider.legacyMiddleware`.

## 3. Three defects found *outside* any conflict marker (trap 2)

**(a) `MockMainMenuCoordinatorDelegate.swift` — clean upstream file, would not have compiled.**
This mock is **new in 155.1** (it exists at neither `firefox-v147.2` nor `c5afa25d3b`), so it arrived
with no conflict, no Ecosia delta and nothing for the intent-diff to flag. But it conforms to
`MainMenuCoordinatorDelegate`, and Ecosia adds two members to that protocol (`showHelp()`,
`showFeedback(windowUUID:)`). Added both to the mock with call-count spies, plus `import Common` for
`WindowUUID`. Real implementations live in `Client/Ecosia/Extensions/BrowserCoordinator+Ecosia.swift`.

**(b) `Client/Helpers/MenuBuilderHelper.swift` — auto-merged to Ecosia's wholly stale copy.**
git took Ecosia's side for the entire body because upstream had *relocated* everything. That silently
reverted three upstream changes at once:
- upstream's extraction into `makeApplicationMenu()` / `makeFileMenu()` / … helpers (FXIOS-11340,
  a `function_body_length` fix) collapsed back into one long `mainMenu(for:)`;
- `@MainActor` on the class dropped (the class is constructed from `AppDelegate`, which is main-actor
  isolated — this is a Swift 6 isolation regression);
- three `($0 as? UIKeyCommand)?.…` safe casts reverted to `($0 as! UIKeyCommand).…` force casts, plus a
  resurrected dead `if #available(iOS 15, *)` guard.

There is **no Ecosia intent in this file**: comparing every `title:` / `action: #selector(…)` / `input:`
in the merged file against upstream 155.1 gives an exact match — the menus are identical. Took upstream's
file. The one genuine Ecosia delta, `import Shared`, was re-added with a marker: `String.KeyboardShortcuts`
is declared in `firefox-ios/Shared/Strings.swift`, and Ecosia's Tuist `Client` target resolves `Shared` as
a `.package(product:)`, so the import is required here even though upstream ships this one file without it
(it is the *only* file in upstream's `Client` that uses `.KeyboardShortcuts` without importing `Shared`).
**Hand-off to 19:** if that import turns out to be unnecessary, delete the two lines.

**(c) `Tuist/ProjectDescriptionHelpers/Targets+Client.swift` — stale source exclusion.**
The Ecosia-owned Client target excluded
`Client/Frontend/Browser/MainMenu/Redux/MainMenuDetailState.swift`, a file **upstream deleted** between
147.2 and 155.1. Removed the entry (trap 5: the reason expired). Checked the other five exclusions in
that list — all five paths still exist, so only the main-menu one was stale. `tuist generate --no-open`
succeeds after the edit.

## 4. AC 2 — Ad Blocker and VPN, with a wording correction

Verified against the code rather than the AC text, because the AC's phrasing does not match how 155.1
actually surfaces Ad Blocker in this menu:

- **There is no separate "Ad Blocker menu entry" in the main menu.** The Ad Blocker's *only* main-menu
  surface is the badge in the site-protections header: `MainMenuViewController.updateSiteProtectionsHeaderWith`
  builds a `MenuSiteAdBlockerBadgeData?` gated on `isEnabled(.adBlocker) && isEnabled(.adBlockerBadge)`, and
  `MenuSiteProtectionsHeader.setupDetails` adds `adBlockerBadge` to `badgesStack` only when that value is
  non-nil (`MenuSiteProtectionsHeader.swift:176-186`). The badge *is* the button — `adBlockerButtonCallback`
  is its `tapHandler`. So with ticket 07's `badge-enabled: false`, the Ad Blocker has no main-menu surface
  at all; the functional entry lives in Browsing settings (ticket 15).
- That is exactly what the handover's product decision says — "functional in Browsing settings, **no Site
  Menu badge**" — so the flags and the code agree, and **no code change was made**. The inherited-findings
  sentence "the entry itself is separate and not suppressed" is only true of the `.adBlocker` *navigation
  destination* and `presentAdBlockerSettings()`, both of which are reconciled and reachable; it is not true
  of a visible menu row, because none exists.
- **No VPN entry:** `grep -in vpn` over `Client/Frontend/Browser/MainMenu` and `BrowserKit/Sources/MenuKit`
  returns nothing. Consistent with the "VPN off on all channels" decision.
- **Report Broken Site** (the other new upstream entry) is reconciled and live: `Icons.reportBrokenSite`,
  `configureReportBrokenSiteItem`, the `.reportBrokenSite` destination and
  `BrowserCoordinator.presentReportBrokenSite(url:)` are all present and gated only by upstream's own
  `isReportBrokenSiteOn && canSendTechnicalData && url.isWebPage`.
- **Google Lens:** not touched, per instruction.

## 5. The hard constraint from the inherited findings — verified mechanically

Parsed `MenuNavigationDestination.swift` and both consuming switches:

- enum has **22 cases**, `allCasesForTests` lists exactly the same 22 (no drift in either direction);
- `MainMenuMiddleware.swift`'s `switch navigationDestination` — 0 unhandled cases, **no `default:`**;
- `MainMenuCoordinator.swift`'s `switch destination.destination` — 0 unhandled cases, **no `default:`**.

`MainMenuMiddleware.swift` (ticket 04's, auto-merged) re-verified: it is upstream 155.1 plus exactly the
three Ecosia lines `// Ecosia: Reading List, Help, and Report Issue telemetry — no-op for now` /
`case .readingList, .help, .reportIssue: break` / blank. Still correct.

## 6. Ecosia asset and symbol dependencies confirmed present

`AccessibilityIdentifiers.MainMenu.{readingList,help,reportIssue}`; `String.localized(.help)` /
`.reportIssueMenu` (`Ecosia/L10N/String.swift:241-242`); `Analytics.Label.Menu.{bookmarks,history,downloads,
readingList,help,reportIssue,settings}`; `StandardImageIdentifiers.Large.{helpCircle,readingList,shareApple,
report}` and `.Medium.translate`; `.MainMenu.ToolsSection.AccessibilityLabels.LibraryOptions` and
`.LegacyAppMenu.AppMenuReadingListTitleString` in `Shared/Strings.swift`; and the two Ecosia-catalog
imagesets the menu names by string, `bookmarksEmpty.imageset` and `reportIssue.imageset`.

Note on the ticket's asset paragraph: the main menu references **none** of the eight `menu-*.imageset`
entries. Only two of those eight are referenced anywhere in the tree (`menu-Copy-Link` from
`MultiplyImpact.swift`, `menu-ScanQRCode` from `AddressBarState.swift`, both other verticals); the other
six look dead. Pre-existing, not touched here — flagged for whoever does an asset audit.

## 7. Deliberate non-changes

- **`#file` vs `#filePath`** in `MainMenuCoordinatorTests.swift`: the Ecosia squash reverts upstream's
  `#filePath` sweep in 75 places across the test tree, unmarked. 79 files in the merged tree still carry
  `#file`, including files resolved in tickets 09-11. It compiles either way. Left alone for consistency;
  it is a repo-wide cleanup, not a ticket-12 decision.
- **Synchronous `setUp`/`tearDown`** in `MainMenuStateTests.swift` and `MainMenuViewControllerTests.swift`
  (auto-merged to Ecosia's form): kept, matching ticket 00's precedent.
- `MainMenuStateTests.swift`'s `XCTAssertTrue(…menuElements.isEmpty)` and `summarizerConfig: nil`: Ecosia's
  older test data, harmless, kept.

## 8. Verification — all static, nothing executed

Per the Verification standard, **every AC was verified statically**; none was verified by building or
running tests. What was actually run:

- `xcrun swiftc -parse` on all 13 touched files — clean; `grep` for `<<<<<<<` / `>>>>>>>` — 0 in the group.
- `intent-diff-check.py` over all 13 group files (conflicted **and** auto-merged). Every file reports
  `missing=0` except the three explained above: `MainMenuCoordinatorTests.swift` (1 — `AppContainer.shared.reset()`,
  replaced by the identical `DependencyHelperMock().reset()`) and the two files deliberately taken from
  upstream (16 and 12 — the stale pre-rewrite bodies).
- `symcheck.py` over the same 13 plus `MockMainMenuCoordinatorDelegate.swift`, `MenuSiteBadge.swift`,
  `MenuSiteProtectionsHeader.swift`, `WebCompatReportViewControllerTests.swift` — every unresolved name is
  UIKit/Foundation/XCTest noise (`addSubview`, `bottomAnchor`, `detents`, `fulfill`, …). No Firefox- or
  Ecosia-owned symbol is stale.
- `cd firefox-ios && tuist generate --no-open` — **Success**.
- `swiftlint lint --strict --quiet`, bare from the repo root — **no violation in any ticket-12 file**.
  (For the record: that bare run still emits 2299 lines, 2197 of them from `vendor/bundle`, which the root
  `excluded:` does not cover. Pre-existing; the 102 real ones are all in other verticals.)
- Upstream's add/delete set for this area was checked too: `MenuSiteBadge.swift` (A) and
  `WebCompatReportViewControllerTests.swift` (A) are present and clean; `MainMenuDetailState.swift` (D) is
  gone — which is what surfaced §3(c).

## 9. Handed to ticket 19

1. **`import Shared` in `MenuBuilderHelper.swift`** — kept on the reasoning in §3(b), but it is the one
   judgement call in this ticket that a real compile settles in seconds. If Client resolves
   `String.KeyboardShortcuts` without it, delete the import and its `// Ecosia:` line so the file becomes
   byte-identical to upstream.
2. **`@MainActor` restored on `MenuBuilderHelper`** — the caller (`AppDelegate`) is main-actor isolated, so
   this should be clean, but it is a concurrency change relative to what the merge produced.
3. **The two upstream test suites in §2** have not been executed. They are byte-identical to a Mozilla
   release tag, so the risk is confined to Ecosia's `case .readingList, .help, .reportIssue: break` in the
   middleware — which those tests do not exercise.
