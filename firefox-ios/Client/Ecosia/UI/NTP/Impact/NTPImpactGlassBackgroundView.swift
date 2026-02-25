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
/// The blurred image is sized to the full screen and its origin is offset by the *negative*
/// of the view's position in window coordinates — the "counter-movement" trick — so the visible
/// slice always corresponds to the wallpaper pixels directly behind the row.
/// A KVO observer on the parent `UIScrollView` keeps the offset current while the user scrolls.
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

    private var fullScreenSize: CGSize = .zero
    private var scrollViewObservation: NSKeyValueObservation?

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
        syncImageToWindowCoordinates()
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        scrollViewObservation = nil
        guard window != nil else { return }
        syncImageToWindowCoordinates()
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
                await MainActor.run { [weak self] in self?.apply(blurredImage: cached, source: source) }
                return
            }

            let blurred = source.gaussianBlurred(radius: radius)
            await MainActor.run { [weak self] in
                guard let blurred else { return }
                Self.blurCache.setObject(blurred, forKey: source)
                self?.apply(blurredImage: blurred, source: source)
            }
        }
    }

    // MARK: - Private

    private func apply(blurredImage: UIImage, source: UIImage) {
        // Size the image to fill the screen; syncImageToWindowCoordinates adjusts the origin
        fullScreenSize = UIScreen.main.bounds.size
        backgroundImageView.image = blurredImage
        backgroundImageView.frame = CGRect(origin: .zero, size: fullScreenSize)
        syncImageToWindowCoordinates()
    }

    /// Shifts the inner image so the visible portion aligns with the wallpaper behind the row.
    /// As the row moves down (originY increases), the image moves up by the same amount.
    private func syncImageToWindowCoordinates() {
        guard backgroundImageView.image != nil, let window else { return }
        let origin = convert(CGPoint.zero, to: window)
        backgroundImageView.frame.origin = CGPoint(x: -origin.x, y: -origin.y)
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
                    Task { @MainActor [weak self] in self?.syncImageToWindowCoordinates() }
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
            self?.loadCurrentWallpaper()
        }
    }
}
