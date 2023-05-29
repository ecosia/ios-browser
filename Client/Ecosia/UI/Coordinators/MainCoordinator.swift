// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Core

final class MainCoordinator: Coordinator {

    var childCoordinators = [Coordinator]()
    var navigationController: UINavigationController
    var browserViewController: BrowserViewController!
    weak var welcomeDelegate: WelcomeDelegate?
    
    private var profile: Profile
    private var tabManager: TabManager

    init(navigationController: UINavigationController,
         profile: Profile,
         tabManager: TabManager,
         welcomeDelegate: WelcomeDelegate?) {
        self.navigationController = navigationController
        self.profile = profile
        self.tabManager = tabManager
        self.welcomeDelegate = welcomeDelegate
    }

    func start() {
        
        browserViewController = BrowserViewController(profile: profile, tabManager: tabManager)
        browserViewController.edgesForExtendedLayout = []
        
        let rootVC: UIViewController

        if User.shared.firstTime {
            rootVC = Welcome(delegate: welcomeDelegate)
        } else {
            rootVC = browserViewController
        }

        navigationController.pushViewController(rootVC, animated: false)
    }
}
