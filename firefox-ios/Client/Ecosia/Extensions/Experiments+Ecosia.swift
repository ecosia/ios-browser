// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import class MozillaAppServices.RemoteSettingsService
import struct MozillaAppServices.RemoteSettingsConfig
import protocol MozillaAppServices.NimbusInterface

extension Experiments {
    /// A file:// server makes Nimbus read recipes from a local folder instead of creating a client on Mozilla's Remote Settings.
    static func localRemoteSettingsService(nimbusDBPath: String) -> RemoteSettingsService {
        let directory = URL(fileURLWithPath: nimbusDBPath)
            .deletingLastPathComponent()
            .appendingPathComponent("nimbus-recipes", isDirectory: true)
        let config = RemoteSettingsConfig(server: .custom(url: directory.absoluteString))
        return RemoteSettingsService(storageDir: directory.path, config: config)
    }

    /// Applying an empty recipe list ends every enrolment an earlier version made; the fetch flag persists in the Nimbus database.
    static func disableRemoteExperiments(for nimbus: NimbusInterface) {
        if nimbus.isFetchEnabled() {
            nimbus.setFetchEnabled(false)
            // The flag is written on the fetch queue; a concurrent write from the database queue fails and is swallowed.
            nimbus.waitForFetchQueue()
        }
        guard !nimbus.getActiveExperiments().isEmpty || !nimbus.getAvailableExperiments().isEmpty else { return }
        nimbus.setExperimentsLocally(#"{"data": []}"#)
        nimbus.applyPendingExperiments().waitUntilFinished()
    }
}
