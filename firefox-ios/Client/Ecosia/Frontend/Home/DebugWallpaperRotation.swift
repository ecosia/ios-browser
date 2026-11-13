// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common

/// Hidden Debug setting that rotates the NTP between the bundled default wallpaper (the CDN's
/// "ecosia-forest"), the "leaf" and "wood" wallpapers from the CDN and a plain background every
/// 20 seconds, to check how NTP elements look on each of them.
@MainActor
enum DebugWallpaperRotation {
    /// Colours match the CDN metadata (`metadata/v1/wallpapers.json`).
    private static let leaf = cdnWallpaper(id: "leaf", textColor: .white, logoTextColor: UIColor(rgb: 0xE8F5E9))
    /// The only wallpaper in the CDN metadata with dark text.
    private static let wood = cdnWallpaper(id: "wood", textColor: .black, logoTextColor: .black)
    private static let cdnWallpapers = [leaf, wood]

    static let rotation = WallpaperRotation(
        wallpapers: [.ecosiaDefault, leaf, wood, .baseWallpaper],
        interval: 20
    )

    private struct Images {
        let portrait: UIImage
        let landscape: UIImage?
    }

    private static let enabledKey = "ecosiaDebugWallpaperRotationEnabled"
    private static let wallpaperURLKey = "MozWallpaperURLScheme"
    private static var downloadedImages: [String: Images] = [:]
    private static var isDownloading = false

    static var isEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: enabledKey) }
        set {
            UserDefaults.standard.set(newValue, forKey: enabledKey)
            if newValue {
                start()
            } else {
                rotation.stop()
            }
        }
    }

    static func startIfEnabled() {
        guard isEnabled else { return }
        start()
    }

    /// The background whose turn it is, or `nil` when rotation is off.
    static func currentConfiguration() -> WallpaperConfiguration? {
        guard isEnabled, let wallpaper = rotation.currentWallpaper else { return nil }

        let isCDNWallpaper = cdnWallpapers.contains { $0.id == wallpaper.id }
        guard isCDNWallpaper else {
            return EcosiaHomepageAdapter.configuration(forBundled: wallpaper)
        }

        // Until the download finishes, or if it fails, a CDN wallpaper's turn shows the plain background.
        guard let images = downloadedImages[wallpaper.id] else {
            return WallpaperConfiguration(hasImage: false)
        }
        return WallpaperConfiguration(
            id: wallpaper.id,
            landscapeImage: images.landscape ?? images.portrait,
            portraitImage: images.portrait,
            textColor: wallpaper.textColor,
            cardColor: wallpaper.cardColor,
            logoTextColor: wallpaper.logoTextColor,
            hasImage: true
        )
    }

    private static func cdnWallpaper(id: String, textColor: UIColor, logoTextColor: UIColor) -> Wallpaper {
        Wallpaper(id: id, textColor: textColor, cardColor: UIColor(rgb: 0x1A4D2E), logoTextColor: logoTextColor)
    }

    private static func start() {
        rotation.start()
        guard !isDownloading else { return }
        isDownloading = true
        Task {
            for wallpaper in cdnWallpapers where downloadedImages[wallpaper.id] == nil {
                downloadedImages[wallpaper.id] = await downloadImages(for: wallpaper)
                // Refresh the NTP in case it is this wallpaper's turn.
                NotificationCenter.default.post(name: WallpaperRotation.didRotate, object: rotation)
            }
            isDownloading = false
        }
    }

    private static func downloadImages(for wallpaper: Wallpaper) async -> Images? {
        guard let baseURL = Bundle.main.object(forInfoDictionaryKey: wallpaperURLKey) as? String,
              !baseURL.isEmpty else { return nil }
        let device = UIDevice.current.userInterfaceIdiom == .pad ? "iPad" : "iPhone"
        let fileURL = "\(baseURL)/\(wallpaper.id)/\(wallpaper.id)_\(device)"
        // A random query string skips any cached copy, so the rotation always shows the latest CDN assets.
        let cacheBuster = "?cacheBuster=\(UUID().uuidString)"
        guard let portrait = await image(at: "\(fileURL)_portrait.jpg\(cacheBuster)") else { return nil }
        let landscape = await image(at: "\(fileURL)_landscape.jpg\(cacheBuster)")
        return Images(portrait: portrait, landscape: landscape)
    }

    nonisolated private static func image(at urlString: String) async -> UIImage? {
        guard let url = URL(string: urlString),
              let (data, _) = try? await URLSession.shared.data(from: url) else { return nil }
        return UIImage(data: data)
    }
}
