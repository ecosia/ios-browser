// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import class MozillaAppServices.RemoteSettingsService
import struct MozillaAppServices.RemoteSettingsConfig
import protocol MozillaAppServices.NimbusStartup

extension Experiments {
    /// A file:// server makes Nimbus read recipes from a local folder instead of creating a client on Mozilla's Remote Settings.
    static func localRemoteSettingsService(nimbusDBPath: String) -> RemoteSettingsService {
        let directory = URL(fileURLWithPath: nimbusDBPath)
            .deletingLastPathComponent()
            .appendingPathComponent("nimbus-recipes", isDirectory: true)
        let config = RemoteSettingsConfig(server: .custom(url: directory.absoluteString),
                                          bucketName: nil,
                                          appContext: nil)
        return RemoteSettingsService(storageDir: directory.path, config: config)
    }

    /// The flag persists in the Nimbus database, so any later `fetchExperiments()` call is a no-op too.
    static func disableRemoteExperiments(for nimbus: NimbusStartup) {
        nimbus.setFetchEnabled(false)
    }
}
