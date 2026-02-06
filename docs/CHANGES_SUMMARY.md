# Ecosia iOS Browser - Changes Summary (Last 9 Months)

> **Date Range:** May 7, 2025 – February 5, 2026  
> **Repository:** [ecosia/ios-browser](https://github.com/ecosia/ios-browser) (Fork of firefox-ios)  
> **Total Commits:** 67  
> **Total Unique Files Changed:** 621

This document summarizes the files and folders that were modified in the Ecosia iOS Browser over the last 9 months. As a fork of firefox-ios, this project customizes the user experience while inheriting the core browser functionality from Mozilla's Firefox for iOS.

---

## Overview by Top-Level Folders

| Folder | Files Changed |
|--------|--------------|
| `firefox-ios/` | 577 |
| `fastlane/` | 18 |
| `.github/` | 7 |
| `BrowserKit/` | 6 |
| `.circleci/` | 3 |
| `docs/` | 2 |
| Root config files | 8 |

---

## 📊 Detailed Folder Analysis

### firefox-ios/ Subfolder Breakdown

| Subfolder | Files Changed | Description |
|-----------|---------------|-------------|
| `Client/` | 344 | Main app code including Ecosia customizations |
| `Ecosia/` | 159 | Core Ecosia module (shared library code) |
| `EcosiaTests/` | 52 | Ecosia-specific test coverage |
| `firefox-ios-tests/` | 11 | Firefox test modifications |
| `Client.xcodeproj/` | 5 | Project configuration |
| `WidgetKit/` | 3 | Widget customizations |
| `Shared/` | 2 | Shared utilities |
| `Storage/` | 1 | Storage modifications |

### firefox-ios/Client/ Subfolder Breakdown

| Subfolder | Files | Status |
|-----------|-------|--------|
| `Assets/` | 202 | ✅ Modified (App icons, UI assets) |
| `Ecosia/` | 88 | ✅ Modified (Ecosia integration layer) |
| `Frontend/` | 37 | ✅ Modified (Browser, Home, Settings) |
| `Configuration/` | 9 | ✅ Modified (Build configs) |
| `Coordinators/` | 3 | ✅ Modified (Navigation) |
| `TabManagement/` | 3 | ✅ Modified (Tab handling) |
| `Application/` | 1 | ✅ Modified (AppDelegate) |
| `ContentBlocker/` | 0 | ❌ Untouched |
| `Entitlements/` | 0 | ❌ Untouched |
| `Experiments/` | 0 | ❌ Untouched |
| `Extensions/` | 0 | ❌ Untouched |
| `FeatureFlags/` | 0 | ❌ Untouched |
| `Helpers/` | 0 | ❌ Untouched |
| `Nimbus/` | 0 | ❌ Untouched |
| `Protocols/` | 0 | ❌ Untouched |
| `Redux/` | 0 | ❌ Untouched |
| `Telemetry/` | 0 | ❌ Untouched |
| `Utils/` | 0 | ❌ Untouched |

### firefox-ios/Client/Frontend/ Breakdown (37 files modified)

| Subfolder | Files | Key Changes |
|-----------|-------|-------------|
| `Browser/` | 15 | BrowserViewController, MainMenuActionHelper, TabDisplayManager, Search |
| `Home/` | 9 | HomepageViewModel, LegacyHomepageViewController, LogoHeader |
| `Settings/` | 7 | AppSettingsTableViewController, Clearables, ThemeSettings |
| `Library/` | 3 | LegacyBookmarksPanel, LibraryViewController |
| `Components/` | 1 | ContentContainer |
| `Theme/` | 2 | photon-colors, ThemedTableViewCells |

### firefox-ios/Client/Ecosia/ Breakdown (88 files)

| Subfolder | Files | Purpose |
|-----------|-------|---------|
| `UI/` | 62 | NTP components, Assets, Onboarding, Theme |
| `Extensions/` | 10 | AppSettings, BrowserViewController, Tab extensions |
| `Account/` | 6 | Auth flow, Tab management for invisible auth |
| `Settings/` | 3 | EcosiaSettings, EcosiaDebugSettings |
| `Frontend/` | 2 | Home section customizations |
| `Experiments/` | 1 | SeedCounterNTPExperiment |
| `Network/` | 1 | Network customizations |
| `Bookmarks/` | 1 | Bookmark handling |
| `PersistedGenerated/` | 1 | Generated persistence |
| `RecoveredFromUpgrade/` | 1 | Upgrade recovery |

### firefox-ios/Ecosia/ Breakdown (159 files - Core Module)

| Subfolder | Files | Purpose |
|-----------|-------|---------|
| `UI/` | 103 | Account views, NTP components, Common assets |
| `Core/` | 49 | Services, Cookie handlers, Feature management |
| `Account/Auth/` | 24 | Auth0, Authentication service, Credentials |
| `L10N/` | 7 | Localization strings (de, en, es, fr, it, nl) |
| `Analytics/` | 4 | Analytics integration |
| `Experiments/` | 3 | Feature flags (AI Search, Default Browser) |
| `Braze/` | 2 | Push notification integration |
| `Helpers/` | 6 | Utility functions |
| `Extensions/` | 4 | Swift extensions |
| `Entitlements/` | 2 | App capabilities |

#### firefox-ios/Ecosia/UI/ Details (103 files)

| Subfolder | Files | Description |
|-----------|-------|-------------|
| `Common.xcassets/` | 43 | Account icons, AI assets, general images |
| `Account/` | 25 | Progress avatar, signed in/out views, seed view |
| `NTP/Header/` | 3 | AI Search button, Account nav button |
| `Settings/` | 3 | Default browser settings |
| `FeedbackView/` | 8 | User feedback UI |
| `DesignSystem/` | 6 | Colors, typography |
| `Components/` | 2 | Reusable UI components |
| `Toast/` | 1 | Toast notifications |

#### firefox-ios/Ecosia/Core/ Details (49 files)

| Subfolder | Files | Description |
|-----------|-------|-------------|
| `MMP/` | 12 | Mobile measurement partner integration |
| `FeatureManagement/` | 11 | Unleash feature flags |
| `Cookie/` | 8 | AI Overviews, Auth, Unleash cookie handlers |
| `HTTPClient/` | 6 | Network layer |
| `Accounts/Service/` | 5 | Account balance, visits API |
| `Referrals/` | 5 | Referral system |
| `Bookmarks/` | 5 | Bookmark syncing |
| `Statistics/` | 4 | Impact statistics |
| `Environment/` | 3 | Environment configuration |
| `Navigation/` | 2 | URL interception, auth redirects |
| `News/` | 2 | Ecosia news integration |
| `Pages/` | 2 | Page utilities |
| `Tabs/` | 2 | Tab utilities |

---

### firefox-ios/EcosiaTests/ Breakdown (52 files)

| Subfolder | Files | Description |
|-----------|-------|-------------|
| `Core/` | 14 | Unleash, Cookie handlers, Environment tests |
| `SnapshotTests/` | 13 | Visual regression tests |
| `Account/Auth/` | 11 | Authentication flow tests |
| `UI/Account/` | 10 | Account UI component tests |
| `Mocks/` | 8 | Mock objects for testing |
| `ClimateImpactCounter/` | 2 | Seed counter tests |
| `Analytics/` | 2 | Analytics event tests |
| `IntegrationTests/` | 1 | Integration test suite |

### BrowserKit/ Breakdown (6 files modified)

| Subfolder | Files | Status |
|-----------|-------|--------|
| `Sources/Common/Theming/` | 1 | ✅ Modified (EcosiaThemeColourPalette) |
| `Sources/ComponentLibrary/Buttons/` | 1 | ✅ Modified (ResizableButton) |
| `Sources/ComponentLibrary/Headers/` | 2 | ✅ Modified (HeaderView, NavigationHeaderView) |
| `Package.resolved` | 1 | ✅ Modified (dependency updates) |
| `Sources/ContentBlockingGenerator/` | 0 | ❌ Untouched |
| `Sources/ExecutableContentBlockingGenerator/` | 0 | ❌ Untouched |
| `Sources/MenuKit/` | 0 | ❌ Untouched |
| `Sources/Redux/` | 0 | ❌ Untouched |
| `Sources/SiteImageView/` | 0 | ❌ Untouched |
| `Sources/TabDataStore/` | 0 | ❌ Untouched |
| `Sources/ToolbarKit/` | 0 | ❌ Untouched |
| `Sources/WebEngine/` | 0 | ❌ Untouched |
| `Tests/*` | 0 | ❌ Untouched (all test directories) |

---

## 🗂️ Untouched Firefox Folders

The following Firefox-inherited folders were **not modified** during this period:

### firefox-ios/Client/ - Untouched Subfolders
- `ContentBlocker/` - Content blocking rules
- `Entitlements/` - App entitlements
- `Experiments/` - Firefox experiments (Ecosia uses own)
- `Extensions/` - App extensions
- `FeatureFlags/` - Firefox feature flags
- `Helpers/` - General helper utilities
- `Nimbus/` - Firefox Nimbus integration
- `Protocols/` - Protocol definitions
- `Redux/` - State management
- `Telemetry/` - Firefox telemetry
- `Utils/` - Utility functions

### Other Untouched firefox-ios/ Folders
- `Account/` - Firefox account (Ecosia has own)
- `CredentialProvider/` - Password autofill extension
- `Extensions/` - Share, Notification extensions
- `FxA/` - Firefox Accounts
- `Providers/` - Data providers
- `Push/` - Push notifications (Firefox)
- `RustFxA/` - Rust Firefox Accounts
- `Storage/` - Local storage
- `Sync/` - Firefox Sync
- `ThirdParty/` - Third-party libraries

---

## 🚀 CI/CD & Configuration

### .circleci/ (3 files)
- `config.yml` - CircleCI configuration updates (M4 Pro machine, test configurations)

### .github/workflows/ (7 files)
- `merge_tests.yml` - PR merge test workflow
- `snapshot_tests.yml` - Visual regression tests
- `swift_lint.yml` - SwiftLint checks
- `upload_release_notes_to_appstore.yml` - App Store automation
- `pr_agent.yml` (removed) - Qodo AI agent removal

### fastlane/ (18 files)
- `metadata/[locale]/release_notes.txt` - Localized release notes
  - Languages: ar, da, de-DE, en-AU, en-CA, en-GB, en-US, es-ES, es-MX, fr-FR, it, ja, nl-NL

### Root Configuration
- `.swiftlint.yml` - SwiftLint configuration
- `swiftlint_baseline.json` - SwiftLint baseline (new)
- `.tx/release_notes_integration_config.yml` - Transifex configuration
- `.gitignore` - Updated ignore patterns

---

## 🔑 Key Features Implemented

Based on commit messages and file changes:

1. **Accounts Feature Integration** - Complete user account system with Auth0
2. **AI Search Access Points** - AI-powered search entry points and branding
3. **AI Brand Update** - Unified AI feature visual identity
4. **Global Counter Adjustments** - Seed/impact counter refinements
5. **Braze Push Notifications** - Push notification support
6. **User Feedback System** - Dedicated feedback section
7. **Snowplow Analytics** - Enhanced analytics integration
8. **App Store Rating Prompts** - Improved rating prompt flow
9. **SwiftUI Previews** - Developer experience improvements
10. **Critical Health Checks** - CI monitoring improvements

---

## Version History (This Period)

| Version | Date |
|---------|------|
| 11.1.1 | May 2025 |
| 11.2.0 | June 2025 |
| 11.2.1 | June 2025 |
| 11.3.0 | July 2025 |
| 11.4.0 | August 2025 |
| 11.4.1 | August 2025 |
| 11.5.0 | September 2025 |
| 11.5.1 | October 2025 |
| 11.6.0 | February 2026 |

---

*This summary was generated on February 5, 2026*
