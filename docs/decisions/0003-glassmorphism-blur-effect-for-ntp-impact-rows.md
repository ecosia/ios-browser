# Glassmorphism Blur Effect for NTP Impact Rows

* Status: accepted
* Deciders: Ecosia iOS Team
* Date: 2026-02-25

## Context and Problem Statement

The NTP impact rows (`NTPImpactRowView`) sit over the wallpaper on the New Tab Page.
The design system specifies a **`backdrop-filter: blur(24px)`** glassmorphism effect so the
wallpaper colours bleed through the rows while maintaining text readability.

We need to decide how to approximate — or exactly replicate — a 24 px Gaussian blur in UIKit,
given that `UIVisualEffectView` does not expose a controllable blur radius.

Reference design: **Figma** › Web / Glassmorphism / Glass, Blur 24px

## Decision Drivers

* Exact match to the Figma spec (`backdrop-filter: blur(24px)`)
* Text must remain readable over any wallpaper
* Performant enough for 3–4 rows visible at once in a scrolling collection view
* Correct visual alignment as the user scrolls (blur must appear to be a "window" into the wallpaper)

## Considered Options

### Option 1 — Native `UIVisualEffectView` (maintainable, approximate)

Uses Apple's hardware-accelerated blur via `UIBlurEffect`. No exact radius control; presets range
roughly from 10 px (`.systemUltraThinMaterial`) to 30 px (`.systemThickMaterial`).

**Advantages**
* Zero custom code — one line of UIKit
* Automatically adapts to dynamic wallpaper changes and theme switches
* Hardware-accelerated with no extra memory cost

**Disadvantages**
* Cannot specify `24 px` exactly — closest is `.systemMaterial` (~20–25 px)
* Internal `_UIVisualEffectSubview` tint layers may add unwanted opacity on top of coloured wallpapers
* No hook to adjust the blur intensity between presets

### Option 2 — Core Image `CIGaussianBlur` + Counter-Movement (chosen, exact)

Pre-blurs the full wallpaper image with `CIGaussianBlur(radius: 24)` on a background thread,
then displays the blurred image inside the row, offset in the **opposite** direction of the view's
position in window coordinates.  This makes the visible slice always correspond to the wallpaper
pixels directly behind the row — the "window" effect — even as the collection view scrolls.

```
┌──────────────────────────────── screen ────────────────────────────────┐
│                         [wallpaper]                                     │
│   ┌──── NTPImpactRowView (glass) ────┐                                  │
│   │  blurred image, origin offset by │                                  │
│   │  -windowOrigin.x / -windowOrigin.y                                  │
│   └─────────────────────────────────┘                                  │
└────────────────────────────────────────────────────────────────────────┘
```

**Advantages**
* Exact `24 px` radius as specified in the design
* Fine-grained control over tint, border, and blur radius
* Predictable visual output independent of iOS version material presets

**Disadvantages**
* Requires async blur computation on first display
* Cache invalidation needed when the wallpaper changes
* Scroll synchronisation requires a KVO observer on the parent `UIScrollView`

## Decision Outcome

**Chosen option: Option 2 — Core Image Gaussian blur + Counter-Movement.**

Implementing an exact 24 px blur is architecturally straightforward and the performance cost
(one async `CIContext` render, cached per wallpaper) is negligible for 3–4 static rows.

### Implementation

#### `NTPImpactGlassBackgroundView`

A `UIView` subclass that:
1. Loads the current wallpaper via `WallpaperManager().currentWallpaper` on a detached `Task`
2. Blurs it with `UIImage.gaussianBlurred(radius: 24)` (Core Image extension)
3. Caches the result by original-image pointer identity to avoid re-blurring the same wallpaper
4. Sizes the inner `UIImageView` to the full screen and offsets it by `-windowOrigin` so the
   visible slice matches the wallpaper beneath the row
5. Observes the parent `UIScrollView.contentOffset` via KVO to keep the offset in sync while scrolling
6. Conforms to `Notifiable` and observes `.WallpaperDidChange` — on receipt it flushes the shared
   blur cache and calls `loadCurrentWallpaper()` so the new wallpaper is immediately reflected

```swift
// Counter-movement: as the row moves down the screen (origin.y increases),
// the inner image moves up by the same amount so the "window" stays aligned.
imageView.frame.origin = CGPoint(x: -windowOrigin.x, y: -windowOrigin.y)
```

#### `UIImage.gaussianBlurred(radius:)`

```swift
extension UIImage {
    nonisolated func gaussianBlurred(radius: CGFloat) -> UIImage? {
        guard let ciImage = CIImage(image: self) else { return nil }
        guard let filter = CIFilter(name: "CIGaussianBlur") else { return nil }
        filter.setValue(ciImage, forKey: kCIInputImageKey)
        filter.setValue(radius, forKey: kCIInputRadiusKey)
        guard let output = filter.outputImage else { return nil }
        let cropped = output.cropped(to: ciImage.extent)
        let ctx = CIContext(options: [.useSoftwareRenderer: false])
        guard let cg = ctx.createCGImage(cropped, from: cropped.extent) else { return nil }
        return UIImage(cgImage: cg, scale: scale, orientation: imageOrientation)
    }
}
```

#### `NTPImpactRowView` changes

* Replaces `UIVisualEffectView` with `NTPImpactGlassBackgroundView`
* Calls `glassBackground.loadCurrentWallpaper()` from `applyTheme(theme:)`
* Retains a thin white `layer.border` (0.5 pt, 25 % alpha) for the glass-edge highlight

### Unsolved Issues / Future Work

* **Orientation changes** — the wallpaper switches between `.portrait` and `.landscape` images on
  rotation. The glass view currently loads once on `applyTheme`. A rotation observer would be needed
  for pixel-perfect accuracy; in practice the blur is soft enough that this is not visible.

* **Wallpaper changes at runtime** — resolved. `NTPImpactGlassBackgroundView` now observes
  `.WallpaperDidChange` via `Notifiable`, flushes the blur cache, and reloads immediately.

* **No wallpaper** — when the user has selected a plain-colour background (`WallpaperManager`
  returns `nil` portrait image) the glass view is invisible/empty; the row falls back to a
  transparent view with only the dark tint overlay, which is acceptable.

## Links

* Figma reference: Web / Glassmorphism / Glass, Blur 24px
* Related files:
  * `firefox-ios/Client/Ecosia/UI/NTP/Impact/NTPImpactGlassBackgroundView.swift`
  * `firefox-ios/Client/Ecosia/UI/NTP/Impact/NTPImpactRowView.swift`
