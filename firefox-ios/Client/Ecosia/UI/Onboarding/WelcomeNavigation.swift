// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common

final class WelcomeNavigation: UINavigationController {
    private var fadeTransitionDelegate: FadeTransitionDelegate {
        let transition = FadeTransitionDelegate()
        let themeManager: ThemeManager = AppContainer.shared.resolve()
        let theme = themeManager.getCurrentTheme(for: windowUUID)
        // Matches NTP background
        transition.dismissalBackgroundColor = theme.colors.ecosia.backgroundPrimaryDecorative
        return transition
    }

    let windowUUID: WindowUUID
    init(rootViewController: UIViewController, windowUUID: WindowUUID) {
        self.windowUUID = windowUUID
        super.init(rootViewController: rootViewController)
        transitioningDelegate = fadeTransitionDelegate
    }
    required init?(coder: NSCoder) { nil }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        topViewController is WelcomeViewController ? .portrait : .all
    }
}
