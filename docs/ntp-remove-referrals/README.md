# NTP: Remove Referrals, News and Bookmarks Sections (MOB-4150)

## Overview

Two sections of the NTP (New Tab Page) are being deactivated:

1. **Referral row** — the second cell inside the Impact UICollectionView (`NTPImpactRowView` with `ClimateImpactInfo.referral`)
2. **Ecosia News section** — the `ecosiaNews` section in the homepage collection view (3 × `NTPNewsCell`)

Both are **hidden by default** and re-enabled via the **Ecosia Debug settings section**.

The **Bookmarks section** is controlled entirely by the existing Firefox user setting (`HomepageSettings` → Bookmarks toggle). No additional debug gate is needed — the user setting is the source of truth.

Additional layout fixes applied in the same branch:

- **Consistent section widths** — news, referral, and shortcuts (top sites) now all use the same horizontal insets as other Ecosia sections, so they are the same width on iPad
- **Shortcuts row cap** — the shortcuts row is capped at **5 tiles per row** (previously could reach 7+) to avoid a cramped layout

---

## The Two Debug Menus

The app exposes **two separate debug menus**.

| Menu | Section header title | How to reveal | Contents |
|------|----------------------|---------------|----------|
| **Firefox DEBUG** | `DEBUG` (all caps) | Tap the version number 5 times in Settings | Firefox-internal tools: Force Crash, Copy logs, Experiments, etc. |
| **Ecosia Debug** | `Debug` | Same — tap version 5 times | Ecosia-specific tools including the new NTP toggles |

When debug mode is unlocked, **three Ecosia sections** appear below the regular Ecosia settings:
- `Debug` — general Ecosia debug tools
- `Debug - Unleash` — feature flag overrides
- `Debug - Accounts` — seed/level/auth testing

The new toggles are in the **`Debug`** section.

---

## New Debug Menu Entry Titles

Look for these exact strings in the **`Debug`** section (not `DEBUG`):

| Entry title | Status label | Default |
|-------------|--------------|---------|
| `Debug: Toggle - Show NTP Referral Row` | `Hidden (default)` or `Visible` | Hidden |
| `Debug: Toggle - Show NTP News Section` | `Hidden (default)` or `Visible` | Hidden |

---

## Root Fix: `generateSettings()` in `AppSettingsTableViewController.swift`

The Ecosia debug sections were **never shown** before this change because `generateSettings()` in `AppSettingsTableViewController.swift` (Firefox file) only built Firefox sections and never called `getEcosiaSettingsSectionsShowingDebug()`.

The fix replaces the Firefox settings generation with the Ecosia one:

```swift
// firefox-ios/Client/Frontend/Settings/Main/AppSettingsTableViewController.swift
override func generateSettings() -> [SettingSection] {
    setupDataSettings()
    /* Ecosia: Replace Firefox settings with Ecosia-specific sections
    ...
    */
    return getEcosiaSettingsSectionsShowingDebug(showDebugSettings)
}
```

`getEcosiaSettingsSectionsShowingDebug(showDebugSettings)` is defined in
`firefox-ios/Client/Ecosia/Extensions/AppSettingsTableViewController+Ecosia.swift` and returns:

```
Search
Customization
(optional) Default Browser nudge card
Ecosia General
Ecosia Privacy
Ecosia Support
Ecosia About
— (if debug unlocked) —
Debug                ← new toggles are here
Debug - Unleash
Debug - Accounts
```

---

## Architecture: What Is Being Hidden

### Referral row

```
HomepageViewController (UICollectionView)
  └── EcosiaHomepageAdapter.getItems(for: .ecosiaImpact)
        └── NTPImpactCellViewModel.infoItemSections
              ├── [0]: [totalTreesInfo, totalInvestedInfo]  ← trees + investment row (keep)
              └── [1]: [referralInfo]                       ← HIDDEN by default
```

Gate: `ToggleNTPReferralRow.isEnabled` (UserDefaults `"NTPShowReferralRow"`, default `false`) in `NTPImpactCellViewModel.infoItemSections`.

### News section

```
HomepageViewController (UICollectionView)
  └── EcosiaHomepageAdapter.getEcosiaSections()
        └── shouldShowNews() → ToggleNTPNewsSection.isEnabled → User.shared.showEcosiaNews
```

Gate: `ToggleNTPNewsSection.isEnabled` (UserDefaults `"NTPShowNewsSection"`, default `false`) in `EcosiaHomepageAdapter.shouldShowNews()`.

The `.ecosiaNews` case is also removed from the NTP customization row by overriding `CustomizableNTPSettingConfig.allCases` to return only `[.topSites, .climateImpact]`. The case itself stays in the enum for analytics and `User.shared.showEcosiaNews` persistence.

### Bookmarks section

Controlled by the existing Firefox user setting (`HomepageSettings` → Bookmarks toggle, backed by `BookmarksSectionState.shouldShowSection`). No Ecosia gate is applied — the user setting is the source of truth.

---

## Architecture: Layout Fixes

### Consistent section widths (iPhone landscape + iPad)

All Ecosia NTP sections — header, logo, library, impact, news, customization, and shortcuts — now use the same `getEcosiaSectionInsets` helper for horizontal padding:

- **iPhone portrait**: 16pt leading/trailing
- **iPhone landscape / iPad**: `window.bounds.width / 4` (centers content in the middle half)

Previously:
- News used a separate `newsSectionContentInsets` helper capping width at 544pt (wider than other sections on iPad)
- Shortcuts (top sites) used Firefox's `UX.leadingInset()` returning only 50pt on iPad (narrower than other sections)

Both are now intercepted in `HomepageSectionLayoutProvider+Ecosia.swift` and use `getEcosiaSectionInsets`.

### Shortcuts row cap (max 5 tiles)

The tile count was computed greedily — the algorithm filled the available width with 85pt cells until none fit, with no upper bound. On a full-width iPad this produced 7+ icons per row.

Fix: `TopSitesSectionLayoutProvider.UX.maxCards = 5` caps the result in `HomepageDimensionCalculator.numberOfTopSitesPerRow()`.

```
minCards = 4  ← floor (unchanged, Firefox)
maxCards = 5  ← ceiling (Ecosia, MOB-4150)
```

---

## Files Changed

| File | Change | Firefox file? |
|------|--------|---------------|
| `firefox-ios/Client/Frontend/Settings/Main/AppSettingsTableViewController.swift` | Replace `generateSettings()` body to call `getEcosiaSettingsSectionsShowingDebug(showDebugSettings)` | ⚠️ Yes |
| `firefox-ios/Client/Frontend/Home/Homepage/HomepageDimensionImplementation.swift` | Apply `maxCards` cap in `numberOfTopSitesPerRow()` | ⚠️ Yes |
| `firefox-ios/Client/Frontend/Home/Homepage/Layout/TopSitesSectionLayoutProvider.swift` | Add `static let maxCards = 5` to `UX` | ⚠️ Yes |
| `firefox-ios/Client/Ecosia/UI/NTP/Impact/NTPImpactCellViewModel.swift` | Gate `infoItemSections[1]` (referral) behind `ToggleNTPReferralRow.isEnabled` | Ecosia |
| `firefox-ios/Client/Ecosia/Frontend/Home/EcosiaHomepageAdapter.swift` | Gate `shouldShowNews()` behind `ToggleNTPNewsSection.isEnabled` | Ecosia |
| `firefox-ios/Client/Ecosia/UI/NTP/Customization/CustomizableNTPSettingConfig.swift` | Override `allCases` to exclude `.ecosiaNews` from the customization row | Ecosia |
| `firefox-ios/Client/Ecosia/Settings/EcosiaDebugSettings.swift` | Add `ToggleNTPReferralRow`, `ToggleNTPNewsSection` classes | Ecosia |
| `firefox-ios/Client/Ecosia/Extensions/AppSettingsTableViewController+Ecosia.swift` | Register both new settings in `getEcosiaDebugSupportSection()` | Ecosia |
| `firefox-ios/Client/Ecosia/Extensions/HomepageSectionLayoutProvider+Ecosia.swift` | Intercept `.ecosiaNews` and `.topSites` layouts to use `getEcosiaSectionInsets` for consistent width | Ecosia |

---

## Testing Plan

### How to access the debug toggles

1. Open **Settings** in the Ecosia app
2. Scroll to the **About** section and tap the **version number 5 times**
3. Three new sections appear: `Debug`, `Debug - Unleash`, `Debug - Accounts`
4. Scroll down to the **`Debug`** section (not `DEBUG`)
5. Find the entries starting with `Debug: Toggle - Show ...`

### Referral row

1. Launch app → open NTP → confirm the referral row is not visible in the Impact section (only trees and investment rows shown).
2. Settings → `Debug` → tap **"Debug: Toggle - Show NTP Referral Row"** → confirm status changes to "Visible" → navigate to NTP → confirm referral row appears.
3. Toggle back OFF → confirm row disappears.
4. Background/foreground with toggle ON → confirm state is preserved via `UserDefaults`.

### News section

1. Launch app → open NTP → confirm no news section is shown.
2. Settings → `Debug` → tap **"Debug: Toggle - Show NTP News Section"** → navigate to NTP → confirm news section appears.
3. Confirm NTP customization row no longer shows the news toggle.
4. Toggle OFF → news disappears again.

### Bookmarks section

Controlled by the user setting. Open **Settings → Homepage** and toggle Bookmarks on/off to verify it shows and hides correctly. No debug toggle is needed.

### Section widths (iPad)

1. Open NTP on iPad in both portrait and landscape.
2. Confirm shortcuts, impact/referral, and news sections all have the same left/right margins.

### Shortcuts row count

1. Open NTP on any device.
2. Confirm the shortcuts row shows at most 5 tiles per row, even on a wide iPad.

### Settings page

1. Open Settings without debug unlocked → confirm only Ecosia sections are visible (Search, Customization, General, Privacy, Support, About).
2. Tap version 5 times → confirm Ecosia `Debug`, `Debug - Unleash`, `Debug - Accounts` sections appear.
3. Confirm the old Firefox `DEBUG` section (Force Remote Settings Sync, Toggle China version, etc.) is **no longer shown** — replaced by Ecosia sections.

---

## Open Issues

- **Permanent removal**: Once referrals and news are confirmed to be decommissioned, the referral subsystem (`Referrals.swift`, `ClimateImpactInfo.referral`, `MultiplyImpact`) and news subsystem can be fully deleted. The debug toggles are a transitional step.
- **`MultiplyImpact` screen**: The invite-friends flow may remain accessible via other paths (deep link, account screen). Only the NTP entry is in scope here.
- **`User.shared.showEcosiaNews` persistence**: The existing user preference is preserved. The debug gate is layered on top.
- **Analytics**: Events that fire on news/referral interaction should be confirmed not to fire when sections are hidden.
- **Firefox account / sync settings**: The previous `generateSettings()` included a Firefox account section (`ConnectSetting`, `AccountStatusSetting`). These are now removed by the Ecosia override. Verify sync features still work if used elsewhere in the app.
- **Shortcuts (top sites) and row count are customer settings**: Unlike news/referrals — which are being decommissioned — the shortcuts section and its number-of-rows setting are user-facing customizations (`User.shared.showTopSites`, `TopSitesSectionState.numberOfRows`). If shortcuts need to be turned off by default in a future ticket, the approach should be to set the default to off while keeping the setting accessible to users in the NTP customization row (`.topSites` remains in `CustomizableNTPSettingConfig.allCases`). Do **not** remove the user-facing toggle the way `.ecosiaNews` was removed from `allCases`.

---

## Links

- Ticket MOB-4150 (referrals): https://ecosia.atlassian.net/browse/MOB-4150
- Ticket MOB-4151 (news): https://ecosia.atlassian.net/browse/MOB-4151
- PR #1060: https://github.com/ecosia/ios-browser/pull/1060
- Branch: `browse-MOB-4150/remove-referrrals`
- Debug section entry: `firefox-ios/Client/Ecosia/Extensions/AppSettingsTableViewController+Ecosia.swift` → `getEcosiaDebugSupportSection()`
- Debug setting classes: `firefox-ios/Client/Ecosia/Settings/EcosiaDebugSettings.swift`
- Settings generation fix: `firefox-ios/Client/Frontend/Settings/Main/AppSettingsTableViewController.swift` → `generateSettings()`
- Layout fixes: `firefox-ios/Client/Ecosia/Extensions/HomepageSectionLayoutProvider+Ecosia.swift`
- Shortcuts cap: `firefox-ios/Client/Frontend/Home/Homepage/Layout/TopSitesSectionLayoutProvider.swift` + `HomepageDimensionImplementation.swift`
