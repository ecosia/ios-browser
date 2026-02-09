---

## Ecosia Section Background Customization (Settings-ready)

We’ve prepared the homepage Ecosia section background to be customizable by users and to support non-bundled images. This is implemented using a compositional layout decoration view and a background manager that can source images from the asset catalog, local files, or remote URLs.

### Architecture
- Decoration view: `EcosiaSectionBackgroundDecorationView`
  - A `UICollectionReusableView` used as a section background (compositional layout decoration).
  - Observes configuration changes via NotificationCenter and refreshes automatically.
- Background manager: `EcosiaSectionBackgroundManager`
  - Singleton with persisted source selection and in-memory/disk caching.
  - Sources:
    - `.asset(name: String)` — use an image from the asset catalog (e.g., `EcosiaNTPBackground`).
    - `.file(path: String)` — use a local file (e.g., a downloaded image stored in the app’s caches directory).
    - `.remote(url: URL)` — download, cache (memory + disk), and serve.
  - Posts `EcosiaSectionBackgroundManager.Notifications.backgroundDidChange` when the source changes.

### Where it’s applied now
- Legacy homepage: Impact section (`.impact`) via `LegacyHomepageViewController`.
- Modern homepage: Header and Customize sections (placeholder) via `HomepageSectionLayoutProvider`.
- Extend to other sections (e.g., News, Account) by adding the decoration item to their layout sections.

### Settings Integration Plan
- Placement: Add a setting under either:
  - Settings > Home > Customize Firefox > “Section Background”, or
  - Ecosia Settings > Homepage > “Section Background”.
- Options to offer initially:
  - Default (App asset): calls `EcosiaSectionBackgroundManager.shared.setSource(.asset(name: "EcosiaNTPBackground"))`
  - Remote URL: text field to enter a URL, then `setSource(.remote(url: ...))`
  - Choose Photo: present a picker, save to app caches, then `setSource(.file(path: ...))`
  - Reset: revert to default asset
- Persistence and refresh:
  - Manager persists selection to `UserDefaults` and posts `backgroundDidChange`, which the decoration view listens to and refreshes.
- Analytics (optional):
  - Emit an event when users change the background (e.g., `Analytics.Category.ntp`, `Action.change`, `Label.NTP.customize`).

### Remote Download & Caching
- Manager downloads remote images via `URLSession`, caches them in-memory (NSCache) and to disk (`Caches/Ecosia/NTPBackground/`).
- On subsequent loads, it serves the cached image; remote source can be re-used without re-downloading.
- Future improvement:
  - Add TTL/expiration and a cleanup routine for old cached backgrounds.
  - Downsample large images to reduce memory usage.

### Accessibility & Theming
- Fallback color is a subtle green-tinted background that adapts to light/dark mode.
- Ensure sufficient contrast with overlaid text/icons; consider per-theme overlays if needed.
- Dynamic type is unaffected; the decoration view does not alter text sizing.

### Performance Considerations
- Use `scaleAspectFill` to fit various device sizes (iPhone/iPad) while maintaining visual quality.
- Prefer optimized assets for retina scales when using asset sources.
- Consider downsampling very large downloaded images before setting the source.

### Testing Strategy (Backgrounds)
- Unit tests (manager):
  - Persist/restore selected source across launches.
  - Remote download success/failure paths.
  - Cached file re-use.
- UI tests (settings):
  - Verify that selecting each option (asset, remote, file) updates the background.
  - Validate background refresh after relaunch.

### Example Code Snippets
- Programmatically changing the background source:
```swift
// Default asset
EcosiaSectionBackgroundManager.shared.setSource(.asset(name: "EcosiaNTPBackground"))

// Remote URL
if let url = URL(string: "https://example.com/backgrounds/forest.jpg") {
    EcosiaSectionBackgroundManager.shared.setSource(.remote(url: url))
}

// Local file (after saving to caches directory)
let path = "/path/to/Caches/Ecosia/NTPBackground/custom.jpg"
EcosiaSectionBackgroundManager.shared.setSource(.file(path: path))

