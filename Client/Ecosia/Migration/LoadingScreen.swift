/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */
import UIKit
import Core

final class LoadingScreen: UIViewController {
    private weak var profile: Profile!
    private weak var tabManager: TabManager!
    
    required init?(coder: NSCoder) { nil }
    init(profile: Profile, tabManager: TabManager) {
        self.profile = profile
        self.tabManager = tabManager
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .fullScreen
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        
        let ecosiaImport = EcosiaImport(profile: profile, tabManager: tabManager)
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
