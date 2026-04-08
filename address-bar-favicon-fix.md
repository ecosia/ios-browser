# Address Bar Favicon Fix

## Goal

Make the site favicon visible on the left side of the URL address bar when browsing a page.

## Root Cause

Three compounding issues prevented the favicon from showing:

1. `LocationView.updateIconContainer()` called `updateUIForLockIconDisplay()` when browsing, which removed `searchEngineContentView` from the view hierarchy entirely and replaced it with `lockIconButton`.
2. `LocationView.animateIconAppearance()` hid `searchEngineContentView` (alpha 0) whenever `lockIconImageName != nil` — which is essentially all HTTPS pages.
3. `PlainSearchEngineView` had no `FaviconImageView` — only a static `UIImageView`. `ecosiaSearchEngineImage()` in `AddressToolbarContainerModel` also explicitly returns `nil` for non-home browsing, so no image was ever passed in.

## Files Changed

### `BrowserKit/Package.swift`
Added `SiteImageView` as a dependency of `ToolbarKit` so `PlainSearchEngineView` can use `FaviconImageView`.

### `BrowserKit/Sources/ToolbarKit/AddressToolbar/LocationView/SearchEngineView/PlainSearchEngineView.swift`
- Added `import SiteImageView`
- Added a `FaviconImageView` (16×16, Ecosia-themed corner radius) alongside the existing `searchEngineImageView`
- Added `updateFaviconDisplay(config:)` — shows the `FaviconImageView` and loads the favicon from `config.url` when browsing (`!isEditing && searchEngineImage == nil && url != nil`); shows the logo otherwise
- Both views share the center of the container and toggle `isHidden` based on state

### `BrowserKit/Sources/ToolbarKit/AddressToolbar/LocationView/LocationView.swift`
- `updateIconContainer()` — Ecosia-commented the `isURLTextFieldEmpty ? searchEngineDisplay : lockIconDisplay` branch; now always calls `updateUIForSearchEngineDisplay()` so the favicon/logo container is always in the stack
- `animateIconAppearance()` — Ecosia-commented the lock icon switching logic; now always sets `searchEngineContentView.alpha = 1` and `lockIconButton.alpha = 0`
- `locationTextFieldDidEndEditing()` — same fix applied when the keyboard dismisses; calls `updateUIForSearchEngineDisplay()` instead of `updateUIForLockIconDisplay()`

## Root Cause Investigation (why it wasn't working)

Two additional bugs were identified and fixed:

### Bug A — `isHome` calculation always `true` for regular URLs
In `AddressToolbarContainerModel.buildAddressToolbarConfig()`:
```swift
// BUG: flatMap produces nil for any https:// URL because InternalURL.init returns nil,
//      then nil?.isAboutHomeURL is nil, and nil ?? true = true for every page
let isHome = url.flatMap { InternalURL($0)?.isAboutHomeURL } ?? true

// FIX: map with ?? false so non-internal URLs evaluate to false (not home)
let isHome = url.map { InternalURL($0)?.isAboutHomeURL ?? false } ?? true
```
`InternalURL.init` only accepts `internal://` or `http://localhost:<port>/` URLs — for any `https://` page it returns `nil`. The original `flatMap` was then falling back to `?? true`, causing `ecosiaSearchEngineImage` to always return the search engine logo and never `nil` (the signal to show the favicon).

### Bug B — Icon not added to stack view with `.experiment` config
Ecosia uses `.experiment` UX config which hard-codes `isLocationTextCentered: true`.
`updateUIForSearchEngineDisplay` only adds the icon if `!isURLTextFieldCentered || isEditing`.
When browsing (`isEditing = false`, `isURLTextFieldCentered = true`): `!true || false = false` → icon never added to the stack view.

Fixed in `updateIconContainer` by computing `effectiveCentered = isURLTextFieldCentered && isURLTextFieldEmpty`:
- Empty URL field (home page overlay) → centered = true → icon stays hidden ✓
- Non-empty URL field (browsing) → centered = false → icon added ✓

Same fix applied in `locationTextFieldDidEndEditing` (pass `false` directly since we know URL is non-empty).

## Known Edge Case — `isURLTextFieldEmpty` with nil text

`isURLTextFieldEmpty` is defined as `urlTextField.text?.isEmpty == true`. When the text field text is `nil` (new tab, no URL), `nil?.isEmpty` evaluates to `nil`, and `nil == true` is `false` — so the field is treated as **not empty**.

This means `effectiveCentered = isURLTextFieldCentered && isURLTextFieldEmpty` evaluates to `false` on the home page (nil text), and the Ecosia logo is added to the icon stack there too. This is a visible **behaviour change from the pre-fix state** (before, no icon showed on the home page overlay). It is likely the correct Ecosia behaviour (matching legacy `URLBarView`), but if the icon needs to be suppressed on the home page, the condition should check `urlAbsolutePath != nil` instead:

```swift
let effectiveCentered = isURLTextFieldCentered && urlAbsolutePath == nil
```

`urlAbsolutePath` is set from `config.url?.absoluteString` in `configureURLTextField`, so it is nil on the new tab page and non-nil when browsing a real page.

## What Still Needs Attention

- **Build & visual verification**: Needs a full build + run on simulator to confirm the favicon loads correctly across HTTP/HTTPS/internal pages, and to validate home page icon appearance
- **Home page icon decision**: Decide whether the Ecosia logo should appear in the left slot on the home page overlay (see edge case above). If not, swap `isURLTextFieldEmpty` for `urlAbsolutePath == nil` in `updateIconContainer`
- **`DropDownSearchEngineView`**: The unified search variant (`isUnifiedSearchEnabled = true`) uses a separate view — may need the same `FaviconImageView` treatment if that experiment becomes the default
- **Accessibility**: `faviconImageView` has no `accessibilityLabel` for the browsing state — should be set to the site hostname
- **Tests**: `PlainSearchEngineViewTests` and `LocationViewTests` should be updated/added to cover the favicon display path
