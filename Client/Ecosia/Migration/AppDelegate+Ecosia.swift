/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import Core

extension AppDelegate {
    func migrateEcosiaContents() {
        guard EcosiaImport.isNeeded, let profile = profile else { return }

        let ecosiaImport = EcosiaImport(profile: profile, tabManager: self.tabManager)
        ecosiaImport.migrate(progress: { progress in
            print("progress: \(progress) ")
        }){ [weak self] migration in
            if case .succeeded = migration.favorites,
               case .succeeded = migration.tabs,
               case .succeeded = migration.history {
                self?.cleanUp()
                Analytics.shared.migration(true)
            } else {
                Analytics.shared.migration(false)
            }
            
            Core.User.shared.migrated = true
        }
    }
    
    private func cleanUp() {
        History().deleteAll()
        Favourites().items = []
        Tabs().clear()
    }
}
