/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import Core

extension AppDelegate {
    func migrateEcosiaContents() {
        guard EcosiaImport.isNeeded, let profile = profile else { return }

        let ecosiaImport = EcosiaImport(profile: profile, tabManager: self.tabManager)
        ecosiaImport.migrate { migration in
            if case .succeeded = migration.favorites,
               case .succeeded = migration.tabs,
               case .succeeded = migration.history {
                Analytics.shared.migration(true)
            } else {
                Analytics.shared.migration(false)
            }

            // Clean up
            Core.User.shared.migrated = true
        }
    }
}
