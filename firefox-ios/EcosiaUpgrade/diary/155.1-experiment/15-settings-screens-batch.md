# 15: Settings screens batch

**What to build:** Ecosia's settings customizations (search settings, homepage settings, general app settings, website data management, clear-private-data, and the Ecosia-specific settings/debug-settings extensions) continue to behave correctly.

**Blocked by:** 10

**Status:** done

- [x] Every Ecosia customization across this file group is reconciled per the intent-diff manifest
- [x] The `isFeatureEnabled` symbol flagged in the symbol-dependency report (tied to the confirmed `LegacyFeatureFlagManager` removal) is resolved in `AppSettingsTableViewController+Ecosia.swift` — **the flagged line was inert; the real break next to it was `isSearchBarLocationFeatureEnabled`. See Findings §2**
- [x] `AppSettingsTableViewControllerTests` and `VersionSettingTests` are updated alongside the production code

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

- **`LegacyFeatureFlagsManager` is confirmed deleted** — no `class LegacyFeatureFlagsManager` exists at `firefox-v155.1` or in the merged tree. Ticket 05 already had to remove a call to it from `SettingsCoordinatorTests.swift`. Expect the same in `AppSettingsTableViewController+Ecosia.swift` (this ticket's AC-2). The replacement is `FeatureFlagsProvider` / `featureFlagsProvider.isEnabled(_:)`, resolved from `AppContainer` and registered in `DependencyHelperMock` as `FeatureFlagProviding`.
- `SettingsCoordinatorTests.swift` is **already fully resolved** (ticket 05). One Ecosia removal was left intentionally: the commented-out `pressedTabs()` delegate test (~line 473). Whether upstream's `pressedBrowsing` equivalent should replace it is a question for this ticket.
- Ecosia's appearance-settings screen decision is settled: **adopt upstream's `AppearanceSettingsView`**; the legacy `ThemeSettingsController` was deleted upstream and is not being vendored.

**Google Lens search-settings row.** `SearchSettingsTableViewController.shouldShowGoogleLensSetting`
gates on `featureFlagsProvider.isEnabled(.googleLens)` **and** `defaultEngine.isGoogleEngine`. Both are
false for Ecosia (the flag is suppressed on all channels by ticket 10), so the row never renders. Keep
upstream's code and its gates — the decision was to suppress, not to remove.

---

# Findings (session completing ticket 15)

**Outcome:** 7 conflicted Swift files and 2 conflicted `.strings` files resolved, plus 3 XCUITests
taken from upstream and 10 auto-merged/clean files swept. Unmerged count 465 → 454. No commits.

## 1. Scope

| State | File | Resolution |
| --- | --- | --- |
| `UU` 1 | `Client/Frontend/Settings/HomepageSettings/HomePageSettingViewController.swift` | see §3 |
| `UU` 2 | `…/ClientTests/Settings/AppSettingsTableViewControllerTests.swift` | upstream + the one marked Ecosia customization, see §4 |
| `UU` 3 | `…/ClientTests/Settings/HomePageSettingViewControllerTests.swift` | upstream + Ecosia's removals re-applied, see §4 |
| `UU` 1 | `…/ClientTests/Settings/SearchBarSettingsViewModelTests.swift` | upstream (Ecosia delta was unmarked staleness only) |
| `UU` 1 | `…/ClientTests/Settings/SummarizeSettingsViewControllerTests.swift` | upstream, see §5 |
| `UU` 1 | `…/ClientTests/Settings/VersionSettingTests.swift` | upstream + the Ecosia app-version predicate, see §4 |
| `UU` 1 ×2 | `Shared/Supporting Files/{es-MX,th}.lproj/Settings.strings` | kept Ecosia's rebranded strings, see §6 |
| `UU` | `…/XCUITests/{DisplaySettingsTests,NewTabSettings,SettingsTests}.swift` | upstream — trap 6 |
| `M `/`A ` | 10 production files incl. `AppSettingsTableViewController.swift`, `SearchSettingsTableViewController.swift`, `SettingsTableViewController.swift`, `WebsiteDataManagement…`, `ClearPrivateData…`, `TopSites*Settings*`, `SearchEnginePicker.swift`, and the three Ecosia-owned `Client/Ecosia/Settings/*` files | swept, see §7 |
| — | `Coordinators/SettingsCoordinatorTests.swift` | inherited question answered, see §8 |

**Left for ticket 00** (unmerged, in this area by filename only, not settings screens): the
`.github/workflows/firefox-ios-update_remote_settings_data_script.yml` workflow and three
`Sticker/…/icon-settings-*.png` sticker icons.

## 2. AC-2 — the flagged symbol was inert; the real break was its neighbour

The symbol report pointed at `isFeatureEnabled` in `AppSettingsTableViewController+Ecosia.swift`. That
line is **inside an Ecosia comment block** (`/* Ecosia: inactiveTabs / TabsSetting removed … */`), so it
was never a compile error — but four lines below it, in **live** code, sat:

```swift
if isSearchBarLocationFeatureEnabled, let profile {
```

`isSearchBarLocationFeatureEnabled` **was deleted upstream in 155.1**. At 147.2 it lived on
`SearchBarLocationProvider` as `featureFlags.isFeatureEnabled(.bottomSearchBar, checking: .buildOnly) && !isiPad`;
in 155.1 the protocol survives but that member is gone, along with the whole
`featureFlags.isFeatureEnabled(_:checking:)` API (`isFeatureEnabled` does not exist anywhere at
`firefox-v155.1`). Upstream's replacement, in the general-settings section of the very class Ecosia is
extending, is a plain device check:

```swift
// Toolbar position cannot be changed on iPad
if let profile, UIDevice.current.userInterfaceIdiom != .pad {
```

Adopted verbatim, with a comment recording the provenance. Also rewrote the adjacent `.inactiveTabs`
comment block so it no longer quotes a deleted API — both `NimbusFeatureFlagID.inactiveTabs` and
`TabsSetting` are gone as of 155.1, so there is nothing left to gate on.

**Swept the rest of the tree for the same API while I was there.** Every other
`featureFlags.isFeatureEnabled` occurrence is already inert: inside Ecosia comment blocks in
`BrowserViewController.swift` (ticket 10), `HomePageSettingViewController.swift` (§3),
`SummarizerNimbusUtils.swift` (still `UU`, owned by no ticket — flagged in §9),
`PrivacyNoticeHelperTests.swift`, plus `TabManagerImplementation.swift.firefox` (the stray backup
ticket 19 deletes) and `ecosia-customizations-sample.json` (data). The other `isFeatureEnabled` hits
(`TermsOfServiceManager`, `RelayController`, `ContextualHintEligibilityUtility`, `AppLaunchUtil`) are
unrelated properties of the same name. **No live call site remains.**

## 3. HomePageSettingViewController — the removal had to grow a member

Upstream deleted its own `shouldHideSections` / `isStoriesRedesignV2Enabled` feature-flag guard, replaced
the pref-derived defaults with `userPreferences.getPreferenceFor(…)`, and **added a Tracker Blocker
module toggle inside the same `if let profile { … }` block** that Ecosia comments out.

Ecosia's stated reason — "Ecosia's NTP never shows Jump Back In or Bookmarks sections, so their settings
toggles must never appear" — applies verbatim to the new sibling: Ecosia's homepage adapter owns the
sections and never renders a tracker-blocker module either. So the whole block stays removed and the
comment was rewritten to say so, including that `.homepageTrackerBlockerModule` is **`enabled: true` on
the developer channel** (`nimbus-features/homepageTrackerBlockerModuleFeature.yaml`), which is exactly
when a dead toggle would otherwise have appeared.

## 4. Settings test files — upstream taken, three marked Ecosia customizations re-applied

The Ecosia deltas in these files were overwhelmingly unmarked staleness: sync `setUp`/`tearDown`,
`LegacyFeatureFlagsManager.shared.initializeDeveloperFeatures` (**class confirmed deleted**), a real
`TabManagerImplementation` and a real `GleanUsageReportingMetricsService` where upstream uses mocks,
renamed properties, deleted tests. Upstream's versions were taken and then the genuine customizations
put back:

- **`AppSettingsTableViewControllerTests`** — restored the marked `ecosia://deep-link?url=/action/show-intro-onboarding`
  assertion over upstream's `fennec://`.
- **`VersionSettingTests`** — restored the marked app-version predicate
  (`appVersionString?.contains("Ecosia")` over upstream's `"Firefox"`). **This one was nearly lost:**
  it only surfaced on the `intent-diff-check` pass after the file had been replaced, which is exactly
  what that step exists for.
- **`HomePageSettingViewControllerTests`** — upstream's four new tests assert on the very toggles §3
  removes. Three of them (`jumpBackInSectionDefaultValue_isFalse`, `bookmarksSectionDefaultValue_isFalse`,
  `trackerBlockerModule_whenFeatureEnabledDefaultValue_isTrue`) would fail on `XCTUnwrap` of a
  deliberately absent setting, so they are commented out with an Ecosia marker pointing at the
  production change. `trackerBlockerModule_whenFeatureDisabled_isHidden` asserts *absence* and still
  passes, so it is left live. Upstream's new `setUp` (which injects a `MockNimbusFeatureFlagLayer`,
  `FeatureFlagsProvider` and `UserFeaturePreferenceManager`) was taken — the remaining live tests need it.

## 5. `SummarizeSettingsViewControllerTests` — an XCTSkip whose reason expired

Ecosia had replaced `test_generateSettings_withShakeFeature_hasExpectedSections` with an `XCTSkip`
because "the shake-gesture flag … is driven solely by the Apple Intelligence summarizer … unavailable
in the test simulator".

Upstream 155.1 rewrote the whole file to inject a **`MockSummarizerNimbusUtils`** into
`SummarizeSettingsViewController(summarizeNimbusUtils:)`; section generation no longer touches the real
`SummarizerNimbusUtils`, Nimbus, or Apple Intelligence at all. The merged file was already
self-contradictory: the skipped test claimed the Gestures section "can't be produced here", while its
auto-merged sibling `test_generateSettings_withBothShakeAndLanguageExpansion_hasExpectedSections`
asserts that it *is* produced, from the same mock. Took upstream.

## 6. Two `Settings.strings` conflicts — kept Ecosia's brand

`es-MX` and `th` both conflict on one key, `Settings.Search.Suggest.PrivateSession.Description.v125`:
upstream's freshly imported translation says "Firefox"/"Firefox Suggest", Ecosia's says "Ecosia
Sugerir"/"Ecosia Suggest". Kept **Ecosia's** side in both — taking upstream would ship the word
"Firefox" in Ecosia's settings UI, and ticket 00's documented recipe (take upstream, then run
`ecosify-strings.py`) would rebrand it back to roughly what Ecosia already has. Both files pass
`plutil -lint`. Added to ticket 00's l10n batch so the eventual sweep treats them consistently with the
67 `InfoPlist.strings`.

## 7. Auto-merged sweep — all clean, one cross-ticket correction

`AppSettingsTableViewController.swift` is the heaviest Ecosia customization in the batch (whole
`generateSettings`, general, privacy, support and about sections replaced, plus the default-browser
nudge card and four Ecosia debug sections). It auto-merged cleanly and **symcheck resolves every
non-SDK symbol it reaches for** — `getSearchSection`/`getCustomizationSection`/`getGeneralSettings`/
`getPrivacySettings`/`getSupportSettings`/`getAboutSettings`, `EcosiaDefaultBrowserNudgeCardPlaceholder`,
`DefaultBrowserSettingsNudgeCardHeaderView`, `ThemeSetting`, `SiriPageSetting`, `OpenWithSetting`,
`BlockPopupSetting`, `NoImageModeSetting`, `PasswordManagerSetting`, `ClearPrivateDataSetting`,
`EcosiaSendAnonymousUsageDataSetting`, `ContentBlockerSetting`, `EcosiaPrivacyPolicySetting`,
`EcosiaTermsSetting`, `SupportSettingsDelegate`, `BrowsingSettingsDelegate`,
`PrefsKeys.Settings.closePrivateTabs`, `TabTrayActionType.closePrivateTabsSettingToggled`. The
appearance decision holds: `ThemeSetting.onClick` calls `settingsDelegate?.pressedTheme()`, which
`SettingsCoordinator` routes to `UIHostingController<AppearanceSettingsView>`.

The other Ecosia customizations in the batch are intact and reference only live symbols:
`ClearPrivateDataTableViewController`'s restored `Analytics.shared.clearsDataFromSection(.main)`
(MOB-4384), `TopSitesRowCountSettingsController`'s `defaultNumberOfRows = 1` (MOB-4331),
`SearchEnginePicker`'s per-engine accessibility identifiers, and
`TopSitesSettingsViewController`'s removal of the sponsored toggle and row-count selector (MOB-4331).

**Cross-ticket correction, now written into ticket 13 §7.** Ticket 13 said Ecosia's
sponsored-shortcuts default mattered because otherwise "the Top Sites settings toggle would default to
ON". There is no toggle — `TopSitesSettingsViewController` comments the whole `BoolSetting` out. That
makes the hardcoded default *more* important, not less: `TopSitesManager.shouldShowSponsoredShortcuts`
reads the preference directly and the user cannot change it, so the default is the shipped behaviour.

Google Lens untouched, per the ticket: `SearchSettingsTableViewController.shouldShowGoogleLensSetting`
keeps upstream's `isEnabled(.googleLens) && defaultEngine.isGoogleEngine` gates.

## 8. Inherited question answered: the commented-out `pressedTabs()` test

`GeneralSettingsDelegate.pressedTabs()` and `TabsSettingsViewController` are gone; the successor is
`pressedBrowsing()` → `BrowsingSettingsViewController`, both present. But **upstream 155.1 ships no
delegate test for `pressedBrowsing` either**, and the route-level equivalent is already covered by
`testTabsSettingsRoute_showsTabsSettingsPage`, which ticket 00 restored to drive `.browser` →
`BrowsingSettingsViewController`. So rather than invent an unrun test, the dead comment block — which
quoted the deleted `TabsSettingsViewController` — was replaced with a short note recording that
resolution. No new test was written.

## 9. Verification — all static, nothing executed

- `xcrun swiftc -parse` on all 22 touched Swift files — clean; zero conflict markers in the group.
  `plutil -lint` OK on both `Settings.strings`.
- `intent-diff-check.py` over the group. Every `missing` entry maps to a decision above; **it is what
  caught the `VersionSettingTests` app-version predicate** after that file was replaced wholesale.
- `symcheck.py` over the production files, the three Ecosia-owned `Client/Ecosia/Settings/*` files and
  all six settings test files — every unresolved name is UIKit/Foundation noise. Two spot-checked by
  hand and confirmed real: `Analytics.Label.DefaultBrowser.settingsNudgeCard` and `EcosiaLogger.accounts`
  (used across dozens of unchanged Ecosia files; symcheck's declaration regex just does not see it).
- `cd firefox-ios && tuist generate --no-open` — **Success**.
- `swiftlint lint --strict --quiet`, bare from the repo root — **no violation in any ticket-15 file**.
  Non-vendor count 93 → 83.

## 10. Handed to ticket 19

1. **`SummarizerNimbusUtils.swift` is still `UU` and owned by no ticket.** Its conflict is an Ecosia
   substitution (`isHostedSummarizerEnabled()` returns `false` — "Ecosia uses only Apple Intelligence")
   sitting against upstream's three new `featureFlagsProvider.isEnabled(…)` accessors. It is a summarizer
   file, not a settings file, so it was left alone — but it is the last place a commented-out
   `featureFlags.isFeatureEnabled` call lives, and ticket 18 or 19 should claim it.
2. **The three commented-out `HomePageSettingViewControllerTests`** are the only place Ecosia's homepage
   settings behaviour is asserted, and they are now inert. If someone re-enables the JBI/Bookmarks
   toggles, nothing will catch it.
3. **The two `Settings.strings` files** were resolved against ticket 00's *policy question*, not with
   `ecosify-strings.py`. If ticket 00 lands the documented recipe repo-wide, re-check these two so the
   wording matches the rest of the sweep.
