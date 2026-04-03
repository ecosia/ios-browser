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

## What Still Needs Attention

- **Build & visual verification**: Build hasn't been run yet — needs a full build + run on simulator to confirm the favicon loads correctly across HTTP/HTTPS/internal pages
- **`DropDownSearchEngineView`**: The unified search variant (`isUnifiedSearchEnabled = true`) uses a separate view — may need the same `FaviconImageView` treatment if that experiment becomes the default
- **Accessibility**: `faviconImageView` has no `accessibilityLabel` for the browsing state — should be set to the site hostname
- **`ecosiaSearchEngineImage` intent**: The function in `AddressToolbarContainerModel` returns `nil` for browsing, which is now the correct signal for "show favicon". Could use an explicit comment clarifying this intent
- **Tests**: `PlainSearchEngineViewTests` and `LocationViewTests` should be updated/added to cover the favicon display path
