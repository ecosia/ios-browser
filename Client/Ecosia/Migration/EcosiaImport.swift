/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Core
import MozillaAppServices
import Storage
import Shared

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
        enum Code: Int {
            case favourites = 911,
                 history = 912,
                 tabs = 913
        }

        let reasons: [MaybeErrorType]

        var description: String {
            // max 3 errors to be reported to save bandwidth and storage
            return reasons.prefix(3).map{$0.description}.joined(separator: " / ")
        }
    }

    let profile: Profile
    let tabManager: TabManager
    private var waitForTabs = false
    private var tabMigrationStart = Date()
    private let migrationGroup = DispatchGroup()

    private let migration = Migration()
    private var finished: ((Migration) -> ())?
    private var progress: ((Double) -> ())?


    init(profile: Profile, tabManager: TabManager) {
        self.profile = profile
        self.tabManager = tabManager
    }

    private var tabsProgress = 0.0 { didSet { progress?(totalProgress) } }
    private var favsProgress = 0.0 { didSet { progress?(totalProgress) } }
    private var historyProgress = 0.0 { didSet { progress?(totalProgress) } }

    private var totalProgress: Double {
        return (tabsProgress + favsProgress + historyProgress) / 3.0
    }

    func migrate(progress: ((Double) -> ())? = nil, finished: @escaping (Migration) -> ()) {
        self.finished = finished
        self.progress = progress

        // Tab migration is triggered by Browser setup in parallel, so it can be it has finished before we get here
        let ecosiaTabs = Core.Tabs().items
        if tabManager.normalTabs.count == ecosiaTabs.count || ecosiaTabs.isEmpty {
            migration.tabs = .succeeded
            Analytics.shared.migrated(.tabs, in: Date().timeIntervalSince(tabMigrationStart))
            self.tabsProgress = 1.0
        } else {
            migrationGroup.enter()
            waitForTabs = true
            tabManager.addDelegate(self)
        }

        // Migrate in order for performance reasons -> first history, then favorites
        migrationGroup.enter()
        EcosiaHistory.migrate(Core.History().items, to: profile, progress: { historyProgress in
            self.historyProgress = historyProgress
        }) { result in
            switch result {
            case .success:
                self.migration.history = .succeeded
            case .failure(let error):
                self.migration.history = .failed(error)
                Analytics.shared.migrationError(code: .history, message: error.description)
            }
            self.historyProgress = 1.0

            EcosiaFavourites.migrate(Core.Favourites().items, to: self.profile, progress: { favsProgress in
                self.favsProgress = favsProgress
            }) { result in
                switch result {
                case .success:
                    self.migration.favorites = .succeeded
                case .failure(let error):
                    self.migration.favorites = .failed(error)
                    Analytics.shared.migrationError(code: .favourites, message: error.description)
                }
                self.favsProgress = 1.0

                if self.waitForTabs {
                    // give tab migration 5 more seconds after rest has finished
                    DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(5)) {
                        self.migration.tabs = .failed(.init(reasons: ["Tab migration timed out"]))
                        self.migrationGroup.leave()
                    }
                }
                self.migrationGroup.leave()
            }
        }

        migrationGroup.notify(queue: .main) {
            self.progress?(1.0)
            self.finished?(self.migration)
            self.finished = nil
            self.progress = nil
        }

    }
}

extension EcosiaImport: TabManagerDelegate {
    func tabManagerDidRestoreTabs(_ tabManager: TabManager) {
        guard waitForTabs else { return }
        waitForTabs = false

        let ecosiaTabs = Core.Tabs().items
        if tabManager.normalTabs.count == ecosiaTabs.count {
            migration.tabs = .succeeded
        } else {
            let message = "\(tabManager.normalTabs.count) of \(ecosiaTabs.count) tabs migrated"
            migration.tabs = .failed(.init(reasons: [message]))
            Analytics.shared.migrationError(code: .tabs, message: message)
        }

        self.tabsProgress = 1.0
        Analytics.shared.migrated(.tabs, in: Date().timeIntervalSince(tabMigrationStart))
        migrationGroup.leave()
    }

    func tabManager(_ tabManager: TabManager, didSelectedTabChange selected: Tab?, previous: Tab?, isRestoring: Bool) {}
    func tabManager(_ tabManager: TabManager, didAddTab tab: Tab, isRestoring: Bool) {}
    func tabManager(_ tabManager: TabManager, didRemoveTab tab: Tab, isRestoring: Bool) {}
    func tabManagerDidAddTabs(_ tabManager: TabManager) {}
    func tabManagerDidRemoveAllTabs(_ tabManager: TabManager, toast: ButtonToast?) {}
}
