# Architecture & Firefox Fork Conventions

This is a **fork of Mozilla Firefox iOS** with Ecosia customizations layered on top. Minimize modifications to Firefox core to reduce upstream merge conflicts.

## Key Directories

| Path | Purpose |
|---|---|
| `Ecosia/` | **Ecosia Framework** — isolated Ecosia logic (analytics, core models, networking, experiments, UI). New Ecosia code goes here. |
| `firefox-ios/Client/Ecosia/` | Ecosia code within the Client target (extensions on Firefox classes, NTP, settings, onboarding). Legacy location — prefer the framework when possible. |
| `firefox-ios/Client/` | Firefox Client app — Ecosia modifications are marked with `// Ecosia:` comments. |
| `firefox-ios/EcosiaTests/` | Ecosia unit tests and snapshot tests. |
| `BrowserKit/` | Shared Swift package (Common, Redux, SiteImageView, TabDataStore, WebEngine, etc.). |
| `docs/decisions/` | Architecture Decision Records (ADRs). |

## Core Ecosia Modules (inside `Ecosia/`)

- **Core/** — `User`, `Environment`, `HTTPClient`, `Statistics`, `Referrals`, `SearchesCounter`, `Navigation`
- **Analytics/** — Snowplow-based analytics via `Analytics.shared`
- **Experiments/Unleash/** — Feature flags via Unleash
- **Braze/** — Push notification integration (`BrazeService`)
- **UI/** — SwiftUI/UIKit design system, NTP components, settings, onboarding

## Extension Pattern for Firefox Customization

Ecosia extends Firefox classes via `+Ecosia` extension files in `firefox-ios/Client/Ecosia/Extensions/` (e.g., `BrowserViewController+Ecosia.swift`). Use this pattern to add behavior to Firefox classes without modifying their original files.

## Commenting Rules for Ecosia Code in Firefox Files

When modifying Firefox core files for Ecosia customizations:

### One-liner (`//`) — for introducing new Ecosia code

```swift
// Ecosia: Update appversion predicate
let appVersionPredicate = (appVersionString?.contains("Ecosia") ?? false) == true
```

### Block comment (`/* */`) — when commenting out original Firefox code

```swift
/* Ecosia: Swap Theme Manager with Ecosia's
lazy var themeManager: ThemeManager = DefaultThemeManager(sharedContainerIdentifier: AppInfo.sharedContainerIdentifier)
 */
lazy var themeManager: ThemeManager = EcosiaThemeManager(sharedContainerIdentifier: AppInfo.sharedContainerIdentifier)
```

### Swapping Firefox behavior with Ecosia behavior

Always:
1. Comment out the original Firefox code in a block comment starting with `/* Ecosia: <reason>`
2. Keep the commented-out Firefox code visible inside that block
3. Add the Ecosia replacement code immediately after the closing `*/`

### Adding Ecosia items to shared declarations

When adding an Ecosia-specific item to a list that ends with Firefox code (e.g. protocol conformances):
1. Block comment: `/* Ecosia: Add <Item>` then the original last line, then `*/`
2. Replacement: repeat the last Firefox line with a trailing comma, then add the Ecosia line with the closing

```swift
/* Ecosia: Add WelcomeDelegate
OnboardingServiceDelegate {
 */
OnboardingServiceDelegate,
WelcomeDelegate {
```

This makes upstream merges easier — the original Firefox code is visible inside the block comment.

## Environment Detection

Environments are detected by bundle ID in `Ecosia/Core/Environment/Environment.swift`:
- `com.ecosia.ecosiaapp` → production
- `com.ecosia.ecosiaapp.firefox` → staging
- Any other → debug
