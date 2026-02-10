# Ecosia iOS Browser — Copilot Instructions

## Architecture Overview

This is a **fork of Mozilla Firefox iOS** with Ecosia-specific customizations layered on top. Code changes touch both Firefox core files and Ecosia-owned modules. Always consider this dual-origin when making changes — minimize modifications to Firefox core to reduce upstream merge conflicts.

### Key Directories

| Path | Purpose |
|---|---|
| `firefox-ios/Ecosia/` | **Ecosia Framework** — isolated Ecosia logic (analytics, core models, networking, experiments, UI components). New Ecosia code goes here. |
| `firefox-ios/Client/Ecosia/` | Ecosia code within the Client target (extensions on Firefox classes, NTP, settings, onboarding). Legacy location — prefer the framework when possible. |
| `firefox-ios/Client/` | Firefox Client app — Ecosia modifications are marked with `// Ecosia:` comments. |
| `firefox-ios/EcosiaTests/` | Ecosia unit tests and snapshot tests. |
| `BrowserKit/` | Shared Swift package (Common, Redux, SiteImageView, TabDataStore, WebEngine, etc.). |
| `docs/decisions/` | Architecture Decision Records (ADRs). |

### Core Ecosia Modules (inside `firefox-ios/Ecosia/`)

- **Core/** — `User`, `Environment`, `HTTPClient`, `Statistics`, `Referrals`, `SearchesCounter`, `Navigation`
- **Analytics/** — Snowplow-based analytics via `Analytics.shared` (do not reassign outside tests — enforced by SwiftLint)
- **Experiments/Unleash/** — Feature flags via Unleash (`Unleash.start(..., appVersion:)`)
- **Braze/** — Push notification integration (`BrazeService`)
- **UI/** — SwiftUI/UIKit design system, NTP components, settings, onboarding

### Extension Pattern for Firefox Customization

Ecosia extends Firefox classes via `+Ecosia` extension files in `firefox-ios/Client/Ecosia/Extensions/` (e.g., `BrowserViewController+Ecosia.swift`, `HomepageViewController+Ecosia.swift`). Use this pattern to add behavior to Firefox classes without modifying their original files.

### Environment Detection

Environments are detected by bundle ID in `firefox-ios/Ecosia/Core/Environment/Environment.swift`:
- `com.ecosia.ecosiaapp` → production
- `com.ecosia.ecosiaapp.firefox` → staging
- Any other → debug

## Commenting Guidelines for Ecosia Code in Firefox

When modifying Firefox core files for Ecosia customizations:

1. **One-liner** (`//`) — for introducing new Ecosia code:
   ```swift
   // Ecosia: Update appversion predicate
   let appVersionPredicate = (appVersionString?.contains("Ecosia") ?? false) == true
   ```

2. **Block comment** (`/* */`) — when commenting out original Firefox code:
   ```swift
   /* Ecosia: Swap Theme Manager with Ecosia's
   lazy var themeManager: ThemeManager = DefaultThemeManager(sharedContainerIdentifier: AppInfo.sharedContainerIdentifier)
    */
   lazy var themeManager: ThemeManager = EcosiaThemeManager(sharedContainerIdentifier: AppInfo.sharedContainerIdentifier)
   ```

This makes upstream merges easier — the original Firefox code is visible inside the block comment.

## Build & Development

1. **Bootstrap**: `sh ./bootstrap.sh` (installs hooks, resolves packages, updates content blockers, creates `Staging.xcconfig`)
2. **Xcode project**: Open `firefox-ios/Client.xcodeproj`, select the **Ecosia** scheme
3. **SwiftLint**: Runs on PR via GitHub Actions (`swiftlint --strict`). Config in `.swiftlint.yml` uses `only_rules` + `baseline` to avoid upstream noise. Lint locally: `swiftlint`
4. **User Scripts** (JS injected into WKWebView): Compiled with webpack.
   - Source: `firefox-ios/Client/Frontend/UserContent/UserScripts/`
   - Output: `firefox-ios/Client/Assets/` (`AllFramesAtDocumentEnd.js`, etc.)
   - Rebuild: `npm run build` from the project root
5. **Unit tests**: Run against the **EcosiaBeta** scheme (`Cmd+U` in Xcode). Test plan: `firefox-ios/EcosiaTests/UnitTest.xctestplan`
6. **CI**: Bitrise for full builds; GitHub Actions for SwiftLint, merge unit tests, and snapshot tests

## File Header Requirement

All Swift files must start with the MPL-2.0 header (enforced by SwiftLint `file_header` rule):
```swift
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/
```

## Testing

- Write comprehensive tests for all new Ecosia code in `firefox-ios/EcosiaTests/`
- **Snapshot tests**: Use `SnapshotTestHelper` for UI snapshot testing. Config in `firefox-ios/EcosiaTests/SnapshotTests/snapshot_configuration.json`. See `firefox-ios/Ecosia/Ecosia.docc/SNAPSHOT_TESTING_WIKI.md`
- **Analytics**: `Analytics.shared` must not be reassigned outside tests (SwiftLint custom rule `reassign_analytics_instance`)
- **Mocks**: Place test mocks in `firefox-ios/EcosiaTests/Mocks/`

## Translations

- Managed via **Transifex**
- Add new English strings to `firefox-ios/Client/Ecosia/L10N/en.lproj/Ecosia.strings`
- After upstream merges, rebrand Mozilla strings: `python3 ecosify-strings.py firefox-ios`

## PR & Branch Naming

- PR title: `[MOB-XXXX] {name of the feature}` (ticket reference from Jira)
- Branch name must include `MOB-XXXX` (e.g., `mob-1234/feature-name`)
- No ticket? Use `NOTICKET` in PR title and `noticket` in branch name

## Architecture Decision Records (ADRs)

- Store in `docs/decisions/` using MADR format
- Naming: `NNNN-short-title.md` (e.g., `0001-swiftlint-configuration-for-upstream-fork.md`)
- Update `docs/decisions/README.md` index when adding new ADRs
- Document unsolved issues and considered alternatives

## Documentation

- Keep `firefox-ios/Ecosia/Ecosia.docc/Ecosia.md` up to date with architecture changes
- Do **not** update the root `/README.md` — it belongs to Firefox core
- Add `README.md` files to folders that are created or heavily modified during feature work
