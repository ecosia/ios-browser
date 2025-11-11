// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

final class WelcomeNavigation: UINavigationController {
    private let fadeTransitionDelegate = FadeTransitionDelegate()

    override init(rootViewController: UIViewController) {
        super.init(rootViewController: rootViewController)
        transitioningDelegate = fadeTransitionDelegate
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        transitioningDelegate = fadeTransitionDelegate
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        topViewController is WelcomeViewController ? .portrait : .all
    }
}
