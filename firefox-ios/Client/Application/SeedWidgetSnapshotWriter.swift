// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import UIKit
import WidgetKit
import Shared
import Ecosia

/// Observes seed-state notifications from the app and mirrors a lightweight snapshot
/// into the shared app-group UserDefaults so the WidgetKit extension can read it.
///
/// The medium and large widget families also need the level state and the account avatar.
/// Level names are resolved here — the extension never derives them — and the avatar is
/// downscaled into the shared container, since the extension cannot reach the app's image cache.
///
/// Call `SeedWidgetSnapshotWriter.shared.setup()` once during app launch
/// (e.g. from `AppLaunchUtil.setUpPostLaunchDependencies()`).
@MainActor
final class SeedWidgetSnapshotWriter {

    static let shared = SeedWidgetSnapshotWriter()

    private let sharedDefaults = UserDefaults(suiteName: AppInfo.sharedContainerIdentifier)
    private var observers: [NSObjectProtocol] = []

    /// File name of the avatar inside the shared app-group container.
    private static let avatarFileName = "seed-widget-avatar.png"
    /// Widgets have a tight memory budget and draw the avatar at 22–26 pt, so it is stored small.
    private static let avatarPixelSize = CGSize(width: 128, height: 128)

    /// The remote URL the stored avatar was fetched from, so it is downloaded only once.
    private var storedAvatarSourceURL: URL?
    /// The URL currently being fetched, so a burst of seed updates cannot start parallel downloads.
    private var pendingAvatarSourceURL: URL?

    private init() {}

    // MARK: - Setup

    func setup() {
        let names: [Notification.Name] = [
            UserDefaultsSeedProgressManager.progressUpdatedNotification,
            UserDefaultsSeedProgressManager.levelUpNotification,
            .EcosiaAuthStateChanged,
            // Fired by EcosiaAuthUIStateProvider after seedCount is committed for logged-in users.
            .EcosiaAccountProgressUpdated,
            .EcosiaAccountLevelUp
        ]

        for name in names {
            let observer = NotificationCenter.default.addObserver(
                forName: name,
                object: nil,
                queue: nil
            ) { [weak self] _ in
                Task { @MainActor in
                    self?.writeSnapshot()
                }
            }
            observers.append(observer)
        }

        // Write once immediately so the widget has a valid value on first install.
        Task { @MainActor in
            writeSnapshot()
        }
    }

    // MARK: - Snapshot

    @MainActor
    private func writeSnapshot() {
        let provider = EcosiaAuthUIStateProvider.shared
        let isSignedIn = provider.isLoggedIn

        // For logged-out users, read directly from UserDefaultsSeedProgressManager (the source of truth).
        // provider.seedCount is updated with a 1-second animation delay after progressUpdatedNotification
        // fires, so reading it here would capture the stale value and show a count one behind the NTP.
        let seedCount: Int
        let levelProgress: Double
        if isSignedIn {
            seedCount = provider.seedCount
            levelProgress = provider.currentProgress
        } else {
            seedCount = UserDefaultsSeedProgressManager.loadTotalSeedsCollected()
            levelProgress = Double(UserDefaultsSeedProgressManager.calculateInnerProgress())
        }

        // Written for logged-out users too: the large widget's teaser ladder names the first
        // levels they would unlock.
        let levelNames = GrowthPointsLevelSystem.allLevelNames

        let avatarFileName = refreshAvatar(for: isSignedIn ? provider.avatarURL : nil)

        let snapshot = SeedWidgetSnapshot(
            seedCount: seedCount,
            levelProgress: levelProgress,
            isSignedIn: isSignedIn,
            currentLevel: isSignedIn ? provider.currentLevelNumber : 1,
            levelNames: levelNames,
            growthPointsRemaining: isSignedIn ? provider.growthPointsRemaining : 0,
            avatarFileName: avatarFileName
        )

        if let defaults = sharedDefaults {
            snapshot.save(to: defaults)
        }

        WidgetCenter.shared.reloadTimelines(ofKind: SeedCounterWidgetKind)
    }

    // MARK: - Avatar

    /// Returns the avatar file name to put in the snapshot, and starts a download when the
    /// account avatar has changed. The download rewrites the snapshot when it completes, so the
    /// widget picks the image up on the next reload rather than blocking this one.
    private func refreshAvatar(for sourceURL: URL?) -> String? {
        guard let sourceURL else {
            removeStoredAvatar()
            return nil
        }

        let isStored = storedAvatarSourceURL == sourceURL && storedAvatarFileURL.map {
            FileManager.default.fileExists(atPath: $0.path)
        } ?? false

        if !isStored {
            guard pendingAvatarSourceURL != sourceURL else { return nil }
            pendingAvatarSourceURL = sourceURL
            Task { @MainActor in
                await downloadAvatar(from: sourceURL)
            }
            return nil
        }

        return Self.avatarFileName
    }

    private func downloadAvatar(from sourceURL: URL) async {
        defer { pendingAvatarSourceURL = nil }
        guard let destination = storedAvatarFileURL else { return }

        do {
            let (data, _) = try await URLSession.shared.data(from: sourceURL)
            guard let image = UIImage(data: data),
                  let resized = downscaled(image).pngData()
            else {
                EcosiaLogger.accounts.error("Seed widget avatar could not be decoded")
                return
            }
            try resized.write(to: destination, options: .atomic)
            storedAvatarSourceURL = sourceURL
            // The image is on disk now — rewrite the snapshot so it references the file.
            writeSnapshot()
        } catch {
            EcosiaLogger.accounts.error("Seed widget avatar download failed: \(error.localizedDescription)")
        }
    }

    private func downscaled(_ image: UIImage) -> UIImage {
        let size = Self.avatarPixelSize
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        return UIGraphicsImageRenderer(size: size, format: format).image { _ in
            image.draw(in: CGRect(origin: .zero, size: size))
        }
    }

    private func removeStoredAvatar() {
        storedAvatarSourceURL = nil
        pendingAvatarSourceURL = nil
        guard let url = storedAvatarFileURL,
              FileManager.default.fileExists(atPath: url.path)
        else { return }
        try? FileManager.default.removeItem(at: url)
    }

    private var storedAvatarFileURL: URL? {
        SeedWidgetSnapshot
            .sharedContainerURL(appGroupIdentifier: AppInfo.sharedContainerIdentifier)?
            .appendingPathComponent(Self.avatarFileName)
    }
}
