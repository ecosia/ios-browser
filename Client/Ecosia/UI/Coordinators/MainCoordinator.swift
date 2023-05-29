// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Core

final class MainCoordinator: Coordinator {

    var childCoordinators = [Coordinator]()
    var navigationController: UINavigationController
    
    private var profile: Profile
    private var tabManager: TabManager
    var browserViewController: BrowserViewController!

    init(navigationController: UINavigationController,
         profile: Profile,
         tabManager: TabManager) {
        self.navigationController = navigationController
        self.profile = profile
        self.tabManager = tabManager
    }

    func start() {
        
        browserViewController = BrowserViewController(profile: profile, tabManager: tabManager)
        browserViewController.edgesForExtendedLayout = []
        
        let rootVC: UIViewController

        if User.shared.firstTime {
            rootVC = Welcome(delegate: self)
        } else {
            rootVC = browserViewController
        }

        navigationController.pushViewController(rootVC, animated: false)
    }
}

extension MainCoordinator: WelcomeDelegate {
    func welcomeDidFinish(_ welcome: Welcome) {
        navigationController.setViewControllers([browserViewController], animated: true)
    }
}
