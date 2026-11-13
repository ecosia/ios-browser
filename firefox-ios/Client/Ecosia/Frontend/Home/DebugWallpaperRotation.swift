// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

/// Hidden Debug setting that rotates the NTP between the bundled wallpapers, the "wood" wallpaper
/// and a plain background every 20 seconds, to check how NTP elements look on each of them.
@MainActor
enum DebugWallpaperRotation {
    /// The only wallpaper in the CDN metadata with dark text, so it is downloaded when rotation starts.
    private static let wood = Wallpaper(
        id: "wood",
        textColor: .black,
        cardColor: UIColor(red: 0x1A / 255, green: 0x4D / 255, blue: 0x2E / 255, alpha: 1),
        logoTextColor: .black
    )

    static let rotation = WallpaperRotation(
        wallpapers: [.ecosiaDefault, .ecosiaForest, wood, .baseWallpaper],
        interval: 20
    )

    private struct Images {
        let portrait: UIImage
        let landscape: UIImage?
    }

    private static let enabledKey = "ecosiaDebugWallpaperRotationEnabled"
    private static let wallpaperURLKey = "MozWallpaperURLScheme"
    private static var woodImages: Images?

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
        guard wallpaper.id == wood.id else {
            return EcosiaHomepageAdapter.configuration(forBundled: wallpaper)
        }
        // Until the download finishes, or if it fails, wood's turn shows the plain background.
        guard let woodImages else { return WallpaperConfiguration(hasImage: false) }
        return WallpaperConfiguration(
            id: wood.id,
            landscapeImage: woodImages.landscape ?? woodImages.portrait,
            portraitImage: woodImages.portrait,
            textColor: wood.textColor,
            cardColor: wood.cardColor,
            logoTextColor: wood.logoTextColor,
            hasImage: true
        )
    }

    private static func start() {
        rotation.start()
        guard woodImages == nil else { return }
        Task {
            woodImages = await downloadImages(for: wood)
            NotificationCenter.default.post(name: WallpaperRotation.didRotate, object: rotation)
        }
    }

    private static func downloadImages(for wallpaper: Wallpaper) async -> Images? {
        guard let baseURL = Bundle.main.object(forInfoDictionaryKey: wallpaperURLKey) as? String,
              !baseURL.isEmpty else { return nil }
        let device = UIDevice.current.userInterfaceIdiom == .pad ? "iPad" : "iPhone"
        let fileURL = "\(baseURL)/\(wallpaper.id)/\(wallpaper.id)_\(device)"
        guard let portrait = await image(at: "\(fileURL)_portrait.jpg") else { return nil }
        let landscape = await image(at: "\(fileURL)_landscape.jpg")
        return Images(portrait: portrait, landscape: landscape)
    }

    nonisolated private static func image(at urlString: String) async -> UIImage? {
        guard let url = URL(string: urlString),
              let (data, _) = try? await URLSession.shared.data(from: url) else { return nil }
        return UIImage(data: data)
    }
}
