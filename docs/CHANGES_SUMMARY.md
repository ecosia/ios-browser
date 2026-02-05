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

## 🌿 Ecosia-Specific Customizations

### firefox-ios/Ecosia/ (159 files)

The core Ecosia customization layer containing all Ecosia-branded features.

#### **UI Components** (103 files)
- `UI/Account/` - User account system UI components
  - `EcosiaAccountProgressAvatar.swift` - Avatar with progress visualization
  - `EcosiaAccountSignedInView.swift` / `EcosiaAccountSignedOutView.swift`
  - `EcosiaWebViewModal.swift` - Modal for web-based account flows
  - `BalanceIncrementAnimationView.swift` - Animation for balance updates
  - `EcosiaSparkleAnimation.swift` - Sparkle effect animations
  - `EcosiaCachedAsyncImage.swift` - Async image loading with caching
  - `EcosiaSeedView.swift` - Seed counter visualization
  - `LevelSystem/GrowthPointsLevelSystem.swift` - User level progression

- `UI/NTP/` - New Tab Page customizations
  - `Header/EcosiaAISearchButton.swift` - AI search entry point button
  - `Header/EcosiaAccountNavButton.swift` - Account navigation button

- `UI/Common.xcassets/` - Ecosia-specific assets
  - `Account/` - Account-related images (avatar, seeds, impact flags)
  - `AI/` - AI search feature images (sparkle, twinkle effects)

#### **Account & Authentication** (24 files)
- `Account/Auth/` - Authentication infrastructure
  - `EcosiaAuthenticationService.swift` - Main auth service
  - `EcosiaBrowserWindowAuthManager.swift` - Browser-based auth management
  - `Auth0ProviderProtocol.swift` / `NativeToWebSSOAuth0Provider.swift` - Auth0 integration
  - `CredentialsManager/` - Secure credentials storage
  - `AuthError.swift` / `AuthNotifications.swift` - Error handling and notifications

#### **Core Services** (49 files)
- `Core/Accounts/` - Account data services
  - `AccountsProvider.swift` - Account data provider
  - `Service/AccountsService.swift` - API integration
  - `Service/AccountBalanceResponse.swift` / `AccountVisitResponse.swift` - API models

- `Core/Navigation/` - URL handling
  - `EcosiaAuthRedirector.swift` - Auth-related URL redirects
  - `EcosiaURLInterceptor.swift` - URL interception for Ecosia flows

- `Core/Cookie/` - Cookie management
  - `AIOverviewsCookieHandler.swift` - AI features cookie handling
  - `UnleashCookieHandler.swift` - Feature flag cookie sync
  - `AuthSessionCookieHandler.swift` - Session cookie management

- `Core/FeatureManagement/` - Feature flags
  - `Unleash/Unleash.swift` - Unleash integration
  - `Unleash/Unleash.Model.swift` - Feature flag models

#### **Analytics** (4 files)
- `Analytics/Analytics.swift` - Core analytics integration
- `Analytics/Analytics.Values.swift` - Analytics event values

#### **Experiments** (3 files)
- `Experiments/Unleash/AISearchMVPExperiment.swift` - AI search feature flag
- `Experiments/Unleash/DefaultBrowserExperiment.swift` - Default browser experiment
- `Experiments/Unleash/NativeSRPVAnalyticsExperiment.swift` - SRPV analytics (removed)

#### **Braze Integration** (2 files)
- `Braze/APNConsent.swift` - Push notification consent
- `Braze/BrazeService.swift` - Braze SDK integration

#### **Localization** (7 files)
- `L10N/String.swift` - Localized string definitions
- `L10N/[locale].lproj/Ecosia.strings` - Translations (de, en, es, fr, it, nl)

---

### firefox-ios/Client/Ecosia/ (88 files)

Integration points between Firefox codebase and Ecosia features.

#### **Account Integration**
- `Account/AccountsProviderWrapper.swift` - Wrapper for accounts API
- `Account/Auth/` - Browser-side auth components
  - `EcosiaAuth.swift` / `EcosiaAuthFlow.swift`
  - `InvisibleTabSession.swift` - Background tab for auth
  - `TabManagement/InvisibleTabManager.swift` / `TabAutoCloseManager.swift`

#### **NTP (New Tab Page) Customizations**
- `UI/NTP/Header/NTPHeader.swift` / `NTPHeaderViewModel.swift`
- `UI/NTP/ClimateImpactCounter/` - Seed/impact counter (legacy, mostly removed)
- `UI/NTP/Impact/` - Climate impact information
- `UI/NTP/News/` - Ecosia news integration
- `UI/NTP/Library/` - Library shortcuts
- `UI/NTP/NudgeCards/` - Promotional cards

#### **Extensions**
- `Extensions/AppSettingsTableViewController+Ecosia.swift` - Settings customization
- `Extensions/BrowserViewController+Ecosia.swift` - Browser customization
- `Extensions/BrowserViewController+EcosiaErrorHandling.swift`
- `Extensions/Tab+InvisibleTab.swift` / `TabManager+InvisibleTab.swift`
- `Extensions/SearchViewController+Ecosia.swift`

#### **Settings**
- `Settings/EcosiaSettings.swift` - Ecosia-specific settings
- `Settings/EcosiaDebugSettings.swift` - Debug/developer options

---

## 📁 Firefox Core Modifications

### firefox-ios/Client/ (37 files in Frontend, 9 in Configuration)

Limited modifications to Firefox's core functionality to integrate Ecosia features:

#### **Browser Integration**
- `Frontend/Browser/BrowserViewController/` - Core browser view extensions
- `Frontend/Browser/MainMenuActionHelper.swift` - Menu customizations
- `Frontend/Browser/TabDisplayManager.swift` - Tab management hooks
- `Frontend/Browser/Search/SearchViewController.swift` - Search integration

#### **Home/NTP Integration**
- `Frontend/Home/HomepageViewModel.swift` - Homepage data
- `Frontend/Home/LegacyHomepageViewController.swift` - Legacy NTP
- `Frontend/Home/LogoHeader/HomeLogoHeaderViewModel.swift` - Header integration

#### **Settings**
- `Frontend/Settings/Main/AppSettingsTableViewController.swift`
- `Frontend/Settings/Clearables.swift` - Data clearing integration
- `Frontend/Settings/ClearPrivateDataTableViewController.swift`

#### **Configuration**
- `Configuration/Common.xcconfig` - Version bumps
- `Configuration/Ecosia.xcconfig` / `EcosiaBeta.xcconfig` - Scheme configs
- `Configuration/EcosiaDebug.xcconfig` / `EcosiaBetaDebug.xcconfig`

---

## 🧪 Tests (52 files)

### firefox-ios/EcosiaTests/

- `Account/Auth/` - Authentication tests
- `Analytics/` - Analytics event tests
- `Core/` - Core service tests (Unleash, Cookie handlers)
- `ClimateImpactCounter/` - Seed counter tests
- `UI/Account/` - Account UI tests
- `SnapshotTests/` - Visual regression tests
- `Mocks/` - Test mocks

---

## 🎨 Assets (201 files in Images.xcassets)

### firefox-ios/Client/Assets/Images.xcassets/
- **App Icons** - Full set of Ecosia-branded app icons (all sizes)
- **UI Assets** - Various UI elements and icons

### firefox-ios/Ecosia/UI/Common.xcassets/
- `Account/` - User account assets (avatar, seed, impact flag, sign-out)
- `AI/` - AI search feature assets (sparkle effects)

---

## 📦 BrowserKit Changes (6 files)

- `Sources/Common/Theming/EcosiaThemeColourPalette.swift` - Ecosia color palette
- `Sources/ComponentLibrary/Buttons/ResizableButton.swift` - Button components
- `Sources/ComponentLibrary/Headers/` - Header components
- `Package.resolved` - Dependency updates

---

## 🚀 CI/CD & Configuration

### .circleci/ (3 files)
- `config.yml` - CircleCI configuration updates (M4Pro machine, test configurations)

### .github/workflows/ (7 files)
- `merge_tests.yml` - PR merge test workflow
- `snapshot_tests.yml` - Visual regression tests
- `swift_lint.yml` - SwiftLint checks
- `upload_release_notes_to_appstore.yml` - App Store automation
- `pr_agent.yml` (removed) - Qodo AI agent removal

### fastlane/ (18 files)
- `metadata/[locale]/release_notes.txt` - Localized release notes
  - Languages: ar, da, de-DE, en-AU, en-CA, en-GB, en-US, es-ES, es_MX, fr-FR, it, ja, nl-NL

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
