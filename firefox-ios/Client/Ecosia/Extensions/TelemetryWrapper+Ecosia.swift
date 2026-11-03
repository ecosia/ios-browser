// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared

extension TelemetryWrapper {
    /// Off for every install. An install that uploaded before sends Glean's one-off `deletion-request` on its next launch.
    static let isGleanUploadEnabled = false

    static let discardedQueuedGleanPingsKey = "ecosiaDiscardedQueuedGleanPings"

    /// Where Glean keeps pings waiting for upload. Its `deletion-request` lives next to it, in `deletion_request`.
    static var gleanPendingPingsDirectory: URL? {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first?
            .appendingPathComponent("glean_data/pending_pings", isDirectory: true)
    }

    /// With upload off, Glean drops the queued pings of its own (`baseline`, `metrics`, `events`) but still sends
    /// the app-defined ones (`nimbus`, `usage-reporting`) an earlier version queued. Deleting the queue before Glean
    /// starts means an upgraded install sends only its deletion requests. It runs once, so later launches keep
    /// `usage-deletion-request` for retries.
    static func discardQueuedGleanPingsOnce(prefs: Prefs,
                                            directory: URL? = gleanPendingPingsDirectory,
                                            fileManager: FileManager = .default) {
        guard prefs.boolForKey(discardedQueuedGleanPingsKey) != true else { return }
        if let directory, fileManager.fileExists(atPath: directory.path) {
            // Try again on the next launch
            guard (try? fileManager.removeItem(at: directory)) != nil else { return }
        }
        prefs.setBool(true, forKey: discardedQueuedGleanPingsKey)
    }
}
