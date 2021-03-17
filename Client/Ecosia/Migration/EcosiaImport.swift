/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Core
import MozillaAppServices
import Storage
import Shared

private let tabsError = 911
private let favouritesError = 912
private let historyError = 913

final class EcosiaImport {

    enum Status {
        case initial, succeeded, failed(Failure)
    }

    class Migration {
        var tabs: Status = .initial
        var favorites: Status = .initial
        var history: Status = .initial
    }

    struct Failure: Error {
        let reasons: [MaybeErrorType]

        var description: String {
            // max 3 errors to be reported to save bandwidth and storage
            return reasons.prefix(3).map{$0.description}.joined(separator: " / ")
        }
    }

    let profile: Profile
    let tabManager: TabManager

    init(profile: Profile, tabManager: TabManager) {
        self.profile = profile
        self.tabManager = tabManager
    }

    static var isNeeded: Bool {
        Core.User.shared.migrated != true
    }

    func migrate(finished: @escaping (Migration) -> ()) {
        let migration = Migration()

        // Migrate in order for performance reasons -> History, Favorites, Tabs
        EcosiaHistory.migrateLowLevel(Core.History().items, to: profile) { result in
            switch result {
            case .success:
                migration.history = .succeeded
            case .failure(let error):
                migration.history = .failed(error)
                Analytics.shared.migrationError(code: historyError, message: error.description)
            }

            EcosiaFavourites.migrate(Core.Favourites().items, to: self.profile) { result in
                switch result {
                case .success:
                    migration.favorites = .succeeded
                case .failure(let error):
                    migration.favorites = .failed(error)
                    Analytics.shared.migrationError(code: favouritesError, message: error.description)
                }

                let urls = Core.Tabs().items.compactMap { $0.page?.url }
                EcosiaTabs.migrate(urls, to: self.tabManager) { result in
                    switch result {
                    case .success:
                        migration.tabs = .succeeded
                    case .failure(let error):
                        migration.tabs = .failed(error)
                        Analytics.shared.migrationError(code: tabsError, message: error.description)
                    }

                    Core.User.shared.migrated = true
                    finished(migration)
                }
            }
        }
    }

}
