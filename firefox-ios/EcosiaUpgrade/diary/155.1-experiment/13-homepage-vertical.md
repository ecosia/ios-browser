# 13: Homepage vertical

**What to build:** The homepage — including Ecosia's custom sections, top-sites handling, wallpaper background, and private-homepage message card — continues to render and behave correctly after upstream's homepage rearchitecture (the StoriesFeed-to-TrackerBlockerModule rework) and the section-layout-provider changes.

**Blocked by:** 10

**Status:** done

- [x] Every Ecosia customization in the homepage file group is reconciled per the intent-diff manifest (homepage view controller, diffable data source, section layout provider and top-sites layout, top-site cell, wallpaper background view and model, private homepage view controller and message card)
- [x] Ecosia's homepage extensions (adapter, section type, context menu, cell, and snapshot extensions) are reconciled against the upstream files, with every symbol they call into confirmed to still exist (static check — see Verification standard)
- [x] The NTP impact-counter characterization test (ticket 01) still compiles-by-inspection against the reconciled homepage code and every symbol it depends on is confirmed present; **executing it is ticket 19's job**
- [x] `HomepageViewControllerTests`, `HomepageDiffableDataSourceTests`, and `HomepageDimensionCalculatorTests` are updated alongside the production code

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


## Inherited findings

- `HomepageViewControllerTests.swift` and `HomepageDiffableDataSourceTests.swift` call `HomepageState.reducer(...)` as a **function**. `Reducer<State>` is now a tuple, so every such call site needs `.legacyReducer(...)`. Ticket 04 identified these two files but left them here (they only *call*, they don't declare).
- `hntSponsoredShortcutsFeature.yaml` is conflicted and is homepage/sponsored-shortcuts scope — it landed in no other ticket.
- Ticket 01's NTP impact-counter tests (`testImpactCounter*` in `FirefoxUpgradeCharacterizationTests.swift`) are this ticket's AC-3 oracle. The counter's *rendering* is explicitly documented as simulator-only.

---

# Findings (session completing ticket 13)

**Outcome:** 14 conflicted files resolved and staged, plus 12 auto-merged/clean files corrected.
Unmerged count 486 → 472. No commits. The ticket shipped without a scope snapshot, so one is
reconstructed below.

## 1. Scope actually found

| Conflicts | File | Resolution |
| --- | --- | --- |
| 10 | `Client/Frontend/Home/Homepage/HomepageViewController.swift` | see §2 |
| 9 | `…/ClientTests/Frontend/Browser/TopSitesHelperTests.swift` | see §4 |
| 6 | `…/Homepage/TopSites/TopSiteCell.swift` | see §3 |
| 4 | `WidgetKit/TopSites/TopSitesWidget.swift` | substitutions re-pointed at upstream's new theme-environment expressions |
| 2 | `…/Homepage/HomepageDiffableDataSource.swift` | see §2 |
| 2 | `…/Home/PrivateHome/PrivateHomepageViewController.swift` | see §5 |
| 2 | `…/ClientTests/Frontend/Homepage/HomepageDiffableDataSourceTests.swift` | `.reducer(` → `.reducer.legacyReducer(` (the inherited finding), plus upstream's `merinoStoryResponse:` shape |
| 2 | `…/ClientTests/Wallpaper/WallpaperSelectorViewModelTests.swift` | took upstream, see §6 |
| 1 | `…/Homepage/Wallpapers/v1/Interface/WallpaperManager.swift` | Ecosia's `#if ECOSIA` collection-id substitution kept; the non-ECOSIA branch now uses upstream's new `WallpaperCollection.classicFirefoxID` constant instead of the literal |
| 1 | `…/ClientTests/Wallpaper/WallpaperSettingsViewModelTests.swift` | took upstream, see §6 |
| 1 | `…/ClientTests/StartAtHome/StartAtHomeMiddlewareTests.swift` | kept upstream's `injectedProfile:`/`overrideWindows`, folded in Ecosia's `injectedTabManager:` (MOB-4384), dropped the `LegacyFeatureFlagsManager` line (**class confirmed deleted upstream**) |
| 1 | `…/XCUITests/HomePageSettingsUITest.swift` | took upstream — XCUITests is not a target in Ecosia's Tuist project (trap 6) |
| 0 markers, `UA` | `Ecosia/UI/Common.xcassets/NTP/Contents.json` | Ecosia-only asset folder; staged as-is |
| `DU` | `nimbus-features/hntSponsoredShortcutsFeature.yaml` | see §7 |

**Not taken (ticket 15's scope):** `Client/Frontend/Settings/HomepageSettings/HomePageSettingViewController.swift`
and `…/ClientTests/Settings/HomePageSettingViewControllerTests.swift` — ticket 15's "what to build" names
homepage settings explicitly. They are the only two conflicted files left in this area.

`StartAtHomeMiddlewareTests.swift` was owned by no ticket; taken here because start-at-home decides
whether the homepage is shown on launch. Noted in `00-unassigned-conflicts.md`.

## 2. HomepageViewController + HomepageDiffableDataSource — upstream rearchitected both

Upstream's changes that Ecosia's code had to be re-adapted to, not just merged with:

- **`HomeSection.topSites` grew a third associated value** (`ShouldShowSectionHeader`) and
  `getTopSites(with:and:)` now returns a `TopSitesSnapshotData` struct instead of a tuple. Ecosia's
  adapter branch in `updateSnapshot` used both old shapes; re-adapted to upstream's.
- **`updateSnapshot` gained `animatingDifferences:`** — which is exactly what Ecosia's own `animated:`
  parameter existed to provide (trap 4). Dropped Ecosia's parameter, its `// Ecosia:` marker and its
  default, and re-pointed both Ecosia call sites in `HomepageViewController+EcosiaSetup.swift`
  (`refreshEcosiaSnapshot(animated:)` → `animatingDifferences: animated`; the pref-change refresh →
  `animatingDifferences: false`, preserving its old non-animating behaviour exactly).
- **`configureCell(for:at:)` was refactored** from one monolithic switch into per-item
  `configureXCell` methods behind a `configuredCell(cellType:at:)` helper. Two of the conflicts sat
  *inside* `configureSyncedTabCell`/`configureMerinoCell` and carried Ecosia's stale copy of the old
  switch body. Took upstream's structure and **re-homed the two things Ecosia actually owns**: the five
  `.ecosia*` item cases into upstream's dispatcher, and `ecosiaGlassStyleEnabled = true` into the
  `.topSite` branch (and into the new `.addShortcutTile` branch, which renders the same `TopSiteCell`
  in the same row — a non-glass tile there would be visibly wrong). **This mattered:** the dispatcher
  had auto-merged from upstream *without* Ecosia's five cases, and it has no `default:`, so the switch
  was non-exhaustive over the 18-case `HomeItem` enum. Verified mechanically afterwards: 0 unhandled.
- **`updateCollectionViewContentInset()` was extracted** and is also called from `updateTopContentInset`.
  Moved Ecosia's `contentInset = .zero` substitution *into* the extracted method rather than leaving it
  at the old call site, so the pinned-header inset path can't reintroduce a top inset later.
- **The wallpaper constraint scheme was replaced** (`wallpaperTopConstraint`/`wallpaperHeightConstraint`
  + `updateWallpaperConstraints`). Ecosia's inset-card layout is kept and upstream's new code is
  commented inside the Ecosia block. `updateWallpaperConstraints` is left live: with Ecosia's layout its
  two constraint properties are nil, so it is a no-op rather than a hazard.
- **Supplementary-view header:** took upstream's `NewsTransitionHeaderCell` branch and
  `LabelButtonHeaderCell` rename, dropping upstream's inner `guard let section` because Ecosia hoisted
  that guard above the `switch` (needed for its `elementKindSectionFooter` case).
- **`section.canHandleLongPress` became `section.canHandleLongPress && item.canHandleLongPress`** —
  adopted, with Ecosia's `if case .topSites = section { return }` early return kept in front.

Every other switch over `HomeSection`/`HomeItem` in the group has a `default:`, so the five Ecosia cases
are safe there; `createLayoutSection` additionally intercepts them via `createEcosiaLayoutSection`.

## 3. Defects found outside any conflict marker (trap 2)

**(a) `NavigationBrowserActionType.tapOnCustomizeHomepageButton` was deleted upstream.**
Upstream removed the `customizeHomepage` section/item and `navigateToHomepageSettings()` with them, and
deleted that action-type case from `NavigationBrowserAction.swift` — a file that is **clean, unmodified
and not conflicted**. Ecosia still needs the method (its NTP customization cell calls it), so the method
is restored, but its action type no longer existed. Replaced with **`tapOnSettingsSection`**, which is the
successor for `.settings(_)` destinations: same `NavigationDestination(.settings(section))` shape, handled
in `BrowserViewControllerState`'s reducer, and already used by Ecosia's own
`HomepageViewController+EcosiaContextMenu.swift:229`.

**(b) `HomepageSectionLayoutProvider+Ecosia.swift` matched `.topSites` with two associated values.**
`case .topSites(_, let numberOfTilesPerRow):` against a now-three-value case. Ecosia-owned file, staged
clean (`A `), no conflict, nothing for the intent-diff to flag. Fixed to `(_, let numberOfTilesPerRow, _)`.

**(c) `TopSiteCell` — three Ecosia pin-badge customizations whose reason expired, one of them dangling.**
Upstream deleted `pinImageBackgroundView` entirely and replaced it with a plain 8×8 template
`pinImageView` anchored *inside* `rootContainer` (no more −4/−4 overhang), plus a new
`addShortcutImageView`/`configureAddShortcutTile`. Consequences:
- Ecosia's "move the pin badge to `contentView` so `rootContainer.clipsToBounds` doesn't clip it" no
  longer has anything to move, and the overhang it worked around is gone. Dropped; the
  `clipsToBounds = false` lines are kept (they still let the tile's shadow draw) with the comment
  corrected, since it no longer describes a pin badge.
- Ecosia's `guard !ecosiaGlassStyleEnabled else { return }` removal in `configurePinnedSite` is now what
  upstream does anyway. Dropped rather than left as a phantom marker.
- Ecosia's `UIImage(named: "pinBadgeFillSmall")` substitution existed because
  `StandardImageIdentifiers.Large.pinFill` "doesn't exist in the asset catalog". Both halves are now
  false: `pinFillLarge.imageset` **and** `pinExtraSmall.imageset` exist, and **`pinBadgeFillSmall` does
  not** — upstream deleted that imageset in 155.1 (it exists at `firefox-v147.2` and in the Ecosia
  squash, not at `firefox-v155.1`), so Ecosia's line was left pointing at a missing asset with no Swift
  conflict anywhere. Took upstream's `ExtraSmall.pin` + `.alwaysTemplate`, which fixes a real defect.
Also dropped the deleted `pinBackground*` UX constants and the pin-background shadow block from
`layoutSubviews`. Ecosia's glass-tile work (blur + tint + border + favicon inset + label colours) is
preserved in full.

**(d) `PrivateHomepageViewController` referenced `UX.defaultScrollContainerPadding`, which upstream split.**
Upstream replaced it with `scrollContainerTopPadding` (32) / `scrollContainerBottomPadding` (16).
Ecosia's three added constraints for the vertically centred message card still used the removed name —
two of them *outside* the conflict region. Added a marked `UX.ecosiaMessageCardHorizontalPadding = 16`,
which preserves the old value exactly and says why it exists.

**(e) `applyBackgroundGradient(to:theme:)` would have been dead-but-live code.** Upstream extracted it;
Ecosia comments out both of its call sites (it replaces the gradient with a solid colour). Folded the new
function into the same Ecosia removal block as `setupGradient`, so the removal stays complete.

## 4. TopSitesHelperTests — Ecosia's intent expressed through upstream's own constant

Ecosia's real customization here is that **Ecosia ships no default suggested sites**
(`DefaultSuggestedSites.defaultSites(...)` returns `[]`), so every count in this file changes.
Everything else in the Ecosia delta was stale-fork noise: the pre-`fromSite:` `createPinnedSite`
overload, `@unchecked Sendable`, `super.tearDown()` ordering, `@MainActor` removals, and two stray `//`
markers left on `func` lines.

Upstream 155.1 rewrote the file to derive every assertion from a new
`private static let defaultSuggestedSitesCount = 4`. So: took upstream's file, then **redefined that one
constant to `0`** behind an Ecosia marker. That reproduces Ecosia's expected counts (0, 2, 2, 2, 2) for
five of the seven tests with no per-assertion markers at all. The two tests whose upstream expression is
bare `defaultSuggestedSitesCount` needed `+ 1` (with no defaults, the frecency/pinned site is not
de-duplicated or replaced away, so one site survives) and carry their own markers.

Net effect: 5 Ecosia comment blocks reduced to 3, and the file otherwise tracks upstream.

## 5. PrivateHomepageViewController

Ecosia's whole delta is preserved and re-adapted: no gradient (solid
`ecosia.backgroundNeutralTertiary`), no logo header, vertically centred message card, Ecosia link text,
Ecosia support URL, and the single-`drawHierarchy` screenshot path. Upstream's `switchMode()` removal
from `PrivateHomepageDelegate` is safe — `grep` finds no reference anywhere.

## 6. Two wallpaper test files taken from upstream (5 Ecosia tests dropped — read this)

**`WallpaperSelectorViewModelTests.swift`** — Ecosia had commented out two telemetry tests to "remove
Glean dependency". Upstream 155.1 rewrote exactly those two tests onto a `MockWallpaperTelemetryUtility`
with **no Glean dependency at all**, so the reason is gone (trap 5) and upstream's version *is* Ecosia's
intent (trap 4). Took upstream.

**`WallpaperSettingsViewModelTests.swift`** — this one drops five Ecosia-authored tests, so the reasoning
is spelled out:
- `WallpaperSettingsViewModel` itself is **byte-identical to upstream** and carries no Ecosia delta, so
  upstream's behaviour is what ships. In 155.1 `collectionPresentation(for:)` was rewritten to key off
  `collection.id` and returns `collection.description ?? LimitedEditionDefaultDescription`.
- Under that implementation **Ecosia's `testSectionHeaderViewModel_headingWithoutDescription` asserts
  the wrong thing** — it expects a nil description where upstream now deliberately falls back to the
  default description. Keeping it would hand ticket 19 a red test.
- Upstream's four new tests (`limitedCollection_usesDescriptionFromMetadata`,
  `limitedCollectionWithoutMetadataDescription_usesDefaultDescription`,
  `descriptionIsNotDerivedFromSectionIndex`, plus the wrexham/a11y ones) cover the same concern Ecosia's
  tests were probing — description coming from metadata rather than from the section index.
- `WallpaperCollection.heading` is **not read by any production code** (only passed through in
  `WallpaperManager.swift:268`), so the two heading-specific tests were asserting nothing about
  behaviour.
If Ecosia wants heading-driven headers, that is a feature request against `collectionPresentation`, not
a test to preserve.

## 7. Sponsored shortcuts — the flag's mechanism was deleted, so the decision moved

`nimbus-features/hntSponsoredShortcutsFeature.yaml` was `DU`: **upstream deleted the whole Nimbus
feature** in 155.1 and made `hntSponsoredShortcuts` a user-setting-only flag —
`NimbusFeatureFlagLayer` now `fatalError`s if anyone asks Nimbus for it. Ecosia's side of the file
carried the product decision "*Sponsored shortcuts are disabled by default; no sponsored tiles on FTE*"
(`enabled: false` on every channel).

Accepted the deletion (`git rm`; also confirmed the file is not referenced from `nimbus.fml.yaml`), and
**carried the decision to its new home**: upstream hardcodes the default in
`UserFeaturePreferenceManager.checkDefaultValue(for:)` — and hardcodes it to **`true`** (its own comment
says "should be false", which is an upstream inconsistency). Added a marked substitution returning
`false` there. Without this the Top Sites settings toggle would have defaulted to ON, silently reversing
Ecosia's decision with no conflict anywhere in the tree.

`UserFeaturePreferenceManagerTests` does not assert this default (its tests set the pref explicitly), so
nothing breaks.

**Correction from ticket 15:** this finding originally said the Top Sites settings *toggle* would have
defaulted to ON. There is no toggle — Ecosia comments the sponsored-shortcuts `BoolSetting` out of
`TopSitesSettingsViewController` entirely (MOB-4331). That makes the default *more* load-bearing, not
less: `TopSitesManager.shouldShowSponsoredShortcuts` reads
`userPreferences.getPreferenceFor(.hntSponsoredShortcuts)` directly and the user has no way to change
it, so the hardcoded default **is** the shipped behaviour.

## 8. Other auto-merged corrections

- **`HomepageDimensionImplementation.swift`** — Ecosia's commented-out "original" was
  `return min(tilesPerRowCount, TopSitesSectionLayoutProvider.UX.maxCards)`, which was **never upstream
  code** (v147.2 already had a bare `return tilesPerRowCount`), and `maxCards` was a constant Ecosia
  added to `TopSitesSectionLayoutProvider` *only* so that fabricated comment would reference a real
  symbol. Corrected the comment to upstream's actual line and removed `maxCards` — which makes
  `TopSitesSectionLayoutProvider.swift` **byte-identical to upstream**. Ecosia's live cap of 4 and the
  matching `HomepageDimensionCalculatorTests` expectations are untouched.
- **`MockNotificationCenter.swift`** — worth knowing about, no change needed. Ecosia removed
  `observers.append(name)` from `publisher(for:)` and made it return a publisher for the real name
  instead of upstream's `"FakeNotification"` placeholder. That is why
  `HomepageViewControllerTests` drops the `observers == [.ThemeDidChange]` assertion: `Themeable`'s
  `listenForThemeChanges` registers only via `publisher(for:)`. Checked the blast radius — the other
  `observers`-asserting tests (`HomepageMiddlewareTests`, `BackgroundAudioHelperTests`) register through
  `Notifiable.startObservingNotifications`, which uses `addObserver` and still appends. Consistent.
- **`HomepageViewControllerTests`' `getCurrentThemeCallCount == 2`** verified by inspection rather than
  guessed: upstream expects 1, and Ecosia's `applyTheme` adds exactly one more read via
  `updateEcosiaTheme()` (`HomepageViewController+EcosiaSetup.swift:378`). Still a runtime count — see §10.
- **Three files reverted to byte-identical upstream** because Ecosia's difference was unmarked staleness
  with no intent: `Mock/MockSearchEngineManager.swift` and `Mock/MockThrottler.swift`
  (`MainActor.assumeIsolated` → upstream's `ensureMainThread`, which dispatches instead of trapping off
  the main thread) and `UnifiedAds/UnifiedAdsCallbackTelemetryTests.swift` (`===` → upstream's
  `asAnyHashable(_:)`).
- **Checked and left alone, all confirmed deliberate Ecosia removals, not merge damage:**
  `WallpaperMetadataTestProvider.swift`'s deleted `.newUpdates` case (upstream did not touch this file at
  all between 147.2 and 155.1; nothing references `.newUpdates`, and the switch has a `default:`),
  `WallpaperMetadataTrackerTests.swift`'s removal of `MockWallpaperStorageUtility` (which consumed
  `.newUpdates`, so the two removals are one coherent change; `storageUtility:` has a default so it still
  compiles), `WallpaperNetworkingModuleTests.swift`'s own `WallpaperURLSessionMock`, and the
  `@MainActor`/`@unchecked Sendable` class annotations across the homepage test files.

## 9. Verification — all static, nothing executed

Per the Verification standard, **every AC was verified statically**. What was run:

- `xcrun swiftc -parse` on all 27 touched files plus the nine Ecosia homepage extension/adapter files —
  clean; `grep` for conflict markers across the group — 0.
- `intent-diff-check.py` over the whole group (conflicted **and** auto-merged). Every `missing` entry
  maps to a decision recorded above; the largest lists are the two wallpaper test files (§6), the
  TopSitesHelperTests rewrite (§4) and TopSiteCell's expired pin customizations (§3c). Spot-checked that
  TopSitesHelperTests' `SiteCursorMock` / `PinnedSitesMock` / `defaultFrecencySites` helpers are all still
  present in upstream's version (they are, as `private … , @unchecked Sendable`) — nothing lost.
- `symcheck.py` over the same set — every unresolved name is UIKit/SwiftUI/Foundation/WidgetKit SDK
  noise. Spot-checked the two that looked Firefox-owned: `sponsoredSupport`
  (`HomepageTelemetry.swift:77`) and `Set.insert(_:).inserted` — both fine.
- Mechanical exhaustiveness check on `configureCell` (18/18 `HomeItem` cases, no `default:`) and
  `createLayoutSection` (all upstream `HomeSection` cases handled; Ecosia's five intercepted earlier;
  `default:` present). Also swept every `.topSites(` pattern in the tree for the old 2-value arity — none
  left.
- **AC-3:** every symbol the three `testImpactCounter*` tests depend on confirmed present —
  `ClimateImpactInfo.{totalTrees,totalInvested,referral,accessibilityIdentifier,destinationURL,rawValue}`,
  `EcosiaAccessibilityIdentifiers.NTP.ClimateImpact.{totalTreesCount,totalInvestedCount,friendsAndTreesInvitesCounter}`,
  and `URLProvider.{trees,financialReports}`. `FirefoxUpgradeCharacterizationTests.swift` reports
  `ecosia-added=0 missing=0` and parses. Not executed.
- `cd firefox-ios && tuist generate --no-open` — **Success**.
- `swiftlint lint --strict --quiet`, bare from the repo root — **no violation in any ticket-13 file**.
  Non-vendor violation count went 102 → 99 (the three byte-identical reverts). The remaining 99 are in
  other verticals; `vendor/bundle` still accounts for ~2197 lines that the root `excluded:` does not cover.

## 10. Handed to ticket 19

1. **`HomepageViewControllerTests.test_viewDidLoad_setsUpThemingAndNotifications` expects
   `getCurrentThemeCallCount == 2`.** Reasoned to be right (upstream's 1 + Ecosia's `updateEcosiaTheme`),
   but it is a runtime call count over a `viewDidLoad` upstream restructured heavily. If it fails, the
   number is the fix, not the code.
2. **Ecosia's adapter path now honours `animatingDifferences`.** Behaviour was preserved call-site by
   call-site, but the animation on the settings-return refresh is worth one look in the simulator.
3. **`updateWallpaperConstraints` is live but inert** under Ecosia's card layout (its constraints are
   nil). Harmless; if the wallpaper card misbehaves on rotation, this is where upstream expects to shift it.
4. **Two upstream tests in `HomepageDiffableDataSourceTests` carry the latent locale dependency Ecosia
   fixed elsewhere** (`test_updateSnapshot_withCategorizedStoriesAndNoSelection_…` and
   `…AndSelectedCategory_…` assert items in `.pocket(nil)` without enabling the section, and
   `MerinoState.shouldShowSection` is still gated on `MerinoProvider.isLocaleSupported`). Per Ecosia's own
   MOB-4384 note the CI runner is en-US, where they pass, so this was left as upstream wrote it rather
   than widened — but it will fail for anyone running locally on a non-supported locale.
5. **§7's sponsored-shortcuts default is a product-visible decision moved to new code.** Worth one
   confirmation that the Top Sites settings toggle still defaults to OFF.
