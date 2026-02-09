# Alternate App Icons Support

* Status: accepted
* Deciders: Ecosia iOS Team
* Date: 2026-02-07

## Context and Problem Statement

Users want to personalize their Ecosia browser experience by choosing from different app icons. Apple provides the ability to offer alternate app icons via `UIApplication.setAlternateIconName(_:)` and Xcode asset catalog configuration. The original Firefox iOS codebase does not include this capability. We need to add infrastructure for alternate app icon selection in the Ecosia browser.

* https://developer.apple.com/documentation/uikit/uiapplication/setalternateiconname(_:completionhandler:) is the core API used
* https://developer.apple.com/documentation/xcode/configuring-your-app-to-use-alternate-app-icons#Configure-the-asset-catalog-compiler the general overview

## Decision Drivers

* User personalization and engagement
* Apple's recommended approach via asset catalog alternate icons (Xcode 14+)
* Minimal impact on existing build configuration
* Consistent with existing Ecosia settings architecture

## Considered Options

* **Option 1**: Traditional approach with standalone icon files and manual `CFBundleIcons` in Info.plist
* **Option 2**: Modern asset catalog approach with `ASSETCATALOG_COMPILER_ALTERNATE_APPICON_NAMES` build setting (Xcode 14+)
* **Option 3**: No alternate icons (status quo)

## Decision Outcome

Chosen option: **Option 2** — Modern asset catalog approach.

Alternate icon sets are placed in `Images.xcassets` alongside the primary `AppIcon.appiconset`. The Xcode build setting `ASSETCATALOG_COMPILER_ALTERNATE_APPICON_NAMES` must list the alternate icon set names so Xcode generates the required `CFBundleIcons` entries in the compiled Info.plist automatically.

### Positive Consequences

* Follows Apple's recommended configuration pattern
* Icons live in the asset catalog, consistent with the primary icon
* No manual Info.plist editing for icon entries
* Supports dark/tinted icon variants per alternate icon if needed in the future

### Negative Consequences

* Requires Xcode 14 or later (already satisfied)
* Placeholder images need to be replaced with final designs

## Implementation Details

### Architecture

* `AppIcon` enum (in `Ecosia/Core/AppIconManager.swift`) — defines available icons, their raw values matching asset catalog names, and localized title keys
* `AppIconManager` — singleton that wraps `UIApplication.setAlternateIconName(_:)` and persists the user's choice via `User.shared.appIcon`
* `AppIconSettingsViewController` — settings screen listing available icons with checkmark selection
* `AppIconSettings` — setting row in the Customization section of the main settings table

### Xcode Build Configuration

All Client target build configurations in `Client.xcodeproj` include:

```
ASSETCATALOG_COMPILER_ALTERNATE_APPICON_NAMES = AppIconGreen AppIconBlack
```

This tells Xcode to include these icon sets as alternate icons in the compiled app.

### Asset Catalog Structure

```
Images.xcassets/
├── AppIcon.appiconset/          # Primary icon (existing)
├── AppIconGreen.appiconset/     # Alternate: Green variant
├── AppIconBlack.appiconset/     # Alternate: Black variant
├── AppIconPreview.imageset/     # Preview for default icon in settings
├── AppIconGreenPreview.imageset/ # Preview for green icon in settings
└── AppIconBlackPreview.imageset/ # Preview for black icon in settings
```

## Open Issues

* Final icon designs for Green and Black variants need to be provided by the design team (current files are solid-color placeholders)
* Analytics tracking for icon changes can be added once the analytics event schema is defined
