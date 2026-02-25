// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import CoreImage
import UIKit

// MARK: - UIImage + Gaussian Blur

extension UIImage {
    /// Returns a copy blurred with `CIGaussianBlur` at the given radius.
    /// Matches CSS `backdrop-filter: blur(Npx)` — see ADR 0003.
    nonisolated func gaussianBlurred(radius: CGFloat) -> UIImage? {
        guard let ciImage = CIImage(image: self) else { return nil }
        guard let filter = CIFilter(name: "CIGaussianBlur") else { return nil }
        filter.setValue(ciImage, forKey: kCIInputImageKey)
        filter.setValue(radius, forKey: kCIInputRadiusKey)
        guard let output = filter.outputImage else { return nil }
        // Crop back to original extent to remove blurred-edge artefacts
        let cropped = output.cropped(to: ciImage.extent)
        let context = CIContext(options: [.useSoftwareRenderer: false])
        guard let cgImage = context.createCGImage(cropped, from: cropped.extent) else { return nil }
        return UIImage(cgImage: cgImage, scale: scale, orientation: imageOrientation)
    }
}

// MARK: - NTPImpactGlassBackgroundView

/// A view that provides an exact `backdrop-filter: blur(24px)` glassmorphism effect
/// for NTP impact rows sitting over a wallpaper.
///
/// **Technique (ADR 0003 — Option 2):**
/// The full wallpaper is blurred once with Core Image and stored in a lightweight cache.
/// The blurred image is sized to match `WallpaperBackgroundView` and its origin is offset
/// by the *negative* of this view's position in the wallpaper's coordinate space —
/// the "counter-movement" trick — so the visible slice always corresponds to the
/// wallpaper pixels directly behind the row.
///
/// Coordinates are expressed relative to `WallpaperBackgroundView` (not the window) because
/// `HomepageViewController` extends the wallpaper *above* the safe area by `safeAreaInsets.top`,
/// so the wallpaper's coordinate origin does not coincide with the window origin.
/// A KVO observer on the parent `UIScrollView` keeps the offset current while scrolling.
@MainActor
final class NTPImpactGlassBackgroundView: UIView {

    // MARK: - Blur Constants

    static let blurRadius: CGFloat = 24
    static let darkTintAlpha: CGFloat = 0.2

    // MARK: - Cache (shared; one blurred image per wallpaper)

    // Weak keys so the cache self-cleans when the original wallpaper image is released.
    private static let blurCache = NSMapTable<UIImage, UIImage>.weakToStrongObjects()

    // MARK: - Notifications

    var notificationCenter: NotificationProtocol = NotificationCenter.default

    // MARK: - Subviews

    private let backgroundImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        return iv
    }()

    private let tintView: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(white: 0, alpha: darkTintAlpha)
        return v
    }()

    // MARK: - State

    private var scrollViewObservation: NSKeyValueObservation?
    // Ecosia: Cached reference to the wallpaper view for pixel-accurate coordinate alignment (ADR 0003)
    private weak var cachedWallpaperView: WallpaperBackgroundView?

    // MARK: - Public API

    /// Per-device tuning offset applied on top of the computed counter-movement.
    /// Positive values shift the blur down; negative values shift it up.
    /// Useful for validating alignment across iPhone form factors.
    var wallpaperYAdjustment: CGFloat = 0

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        clipsToBounds = true
        addSubview(backgroundImageView)
        addSubview(tintView)
        startObservingNotifications(
            withNotificationCenter: notificationCenter,
            forObserver: self,
            observing: [.WallpaperDidChange]
        )
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    // MARK: - Layout

    override func layoutSubviews() {
        super.layoutSubviews()
        tintView.frame = bounds
        syncImageToWallpaperCoordinates()
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        scrollViewObservation = nil
        // Reset cached wallpaper view; it will be re-discovered after re-attachment
        cachedWallpaperView = nil
        guard window != nil else { return }
        syncImageToWallpaperCoordinates()
        observeParentScrollView()
    }

    // MARK: - Public API

    /// Fetches the current wallpaper from `WallpaperManager`, blurs it at 24 px (cached),
    /// and updates the view. Safe to call every time `applyTheme` runs.
    func loadCurrentWallpaper() {
        let wallpaper = WallpaperManager().currentWallpaper
        let isLandscape = UIDevice.current.orientation.isLandscape
        let radius = Self.blurRadius

        Task.detached(priority: .userInitiated) { [weak self] in
            // File I/O — fetch portrait or landscape image off the main thread
            let source: UIImage? = isLandscape ? wallpaper.landscape : wallpaper.portrait
            guard let source else { return }

            // Check cache before running the expensive blur
            if let cached = await MainActor.run(body: { Self.blurCache.object(forKey: source) }) {
                await MainActor.run { [weak self] in self?.apply(blurredImage: cached) }
                return
            }

            let blurred = source.gaussianBlurred(radius: radius)
            await MainActor.run { [weak self] in
                guard let blurred else { return }
                Self.blurCache.setObject(blurred, forKey: source)
                self?.apply(blurredImage: blurred)
            }
        }
    }

    // MARK: - Private

    private func apply(blurredImage: UIImage) {
        backgroundImageView.image = blurredImage
        syncImageToWallpaperCoordinates()
    }

    /// Shifts the inner image so the visible portion aligns with the wallpaper behind the row.
    ///
    /// Coordinates are expressed relative to `WallpaperBackgroundView` so that the blurred image
    /// uses the same origin and size as the actual wallpaper — eliminating the `safeAreaInsets.top`
    /// offset introduced by `HomepageViewController`'s wallpaper constraints (ADR 0003).
    private func syncImageToWallpaperCoordinates() {
        guard backgroundImageView.image != nil else { return }

        // Lazily discover and cache the WallpaperBackgroundView
        if cachedWallpaperView == nil {
            cachedWallpaperView = findWallpaperView()
        }

        if let wallpaperView = cachedWallpaperView {
            // Express this view's origin in the wallpaper's coordinate space
            let origin = convert(CGPoint.zero, to: wallpaperView)
            backgroundImageView.frame = CGRect(
                origin: CGPoint(x: -origin.x, y: -origin.y + wallpaperYAdjustment),
                size: wallpaperView.bounds.size
            )
            return
        }

        // Fallback: window coordinates (used when wallpaper view is not yet in the hierarchy)
        guard let window else { return }
        let origin = convert(CGPoint.zero, to: window)
        backgroundImageView.frame.size = UIScreen.main.bounds.size
        backgroundImageView.frame.origin = CGPoint(x: -origin.x, y: -origin.y + wallpaperYAdjustment)
    }

    /// Walks the view tree from the window root to find `WallpaperBackgroundView`.
    /// Called at most once per window attachment (result is cached in `cachedWallpaperView`).
    private func findWallpaperView() -> WallpaperBackgroundView? {
        // Walk up to the root of the window hierarchy
        var root: UIView = self
        while let parent = root.superview { root = parent }
        return findDescendant(ofType: WallpaperBackgroundView.self, in: root)
    }

    private func findDescendant<T: UIView>(ofType type: T.Type, in view: UIView) -> T? {
        if let match = view as? T { return match }
        for subview in view.subviews {
            if let found = findDescendant(ofType: type, in: subview) { return found }
        }
        return nil
    }

    /// Adds a KVO observer on the nearest parent scroll view so the offset stays current
    /// while the NTP collection view is being scrolled.
    private func observeParentScrollView() {
        var candidate: UIView? = superview
        while let view = candidate {
            if let scrollView = view as? UIScrollView {
                scrollViewObservation = scrollView.observe(
                    \.contentOffset,
                    options: .new
                ) { [weak self] _, _ in
                    Task { @MainActor [weak self] in self?.syncImageToWallpaperCoordinates() }
                }
                return
            }
            candidate = view.superview
        }
    }
}

// MARK: - Notifiable

extension NTPImpactGlassBackgroundView: Notifiable {
    nonisolated func handleNotifications(_ notification: Notification) {
        guard notification.name == .WallpaperDidChange else { return }
        Task { @MainActor [weak self] in
            // Flush the shared cache so the new wallpaper gets blurred fresh
            Self.blurCache.removeAllObjects()
            self?.cachedWallpaperView = nil
            self?.loadCurrentWallpaper()
        }
    }
}
