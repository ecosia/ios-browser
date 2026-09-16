// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import WidgetKit
import Shared
import Ecosia

/// Observes seed-state notifications from the app and mirrors a lightweight snapshot
/// into the shared app-group UserDefaults so the WidgetKit extension can read it.
///
/// Call `SeedWidgetSnapshotWriter.shared.setup()` once during app launch
/// (e.g. from `AppLaunchUtil.setUpPostLaunchDependencies()`).
@MainActor
final class SeedWidgetSnapshotWriter {

    static let shared = SeedWidgetSnapshotWriter()

    private let sharedDefaults = UserDefaults(suiteName: AppInfo.sharedContainerIdentifier)
    private var observers: [NSObjectProtocol] = []

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

        let snapshot = SeedWidgetSnapshot(
            seedCount: seedCount,
            levelProgress: levelProgress,
            isSignedIn: isSignedIn
        )

        if let defaults = sharedDefaults {
            snapshot.save(to: defaults)
        }

        WidgetCenter.shared.reloadTimelines(ofKind: SeedCounterWidgetKind)
    }
}
