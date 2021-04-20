/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import Core

extension AppDelegate {
    func migrateEcosiaContents() {
        guard EcosiaImport.isNeeded, let profile = profile else {
            User.shared.migrated = true
            return
        }
        window?.rootViewController?.present(LoadingScreen(profile: profile, tabManager: tabManager), animated: false)
    }
}
