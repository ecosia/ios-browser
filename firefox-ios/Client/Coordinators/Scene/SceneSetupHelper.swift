// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Ecosia
import UIKit

class BrowserWindow: UIWindow {
    let uuid: WindowUUID

    init(frame: CGRect, uuid: WindowUUID) {
        self.uuid = uuid
        super.init(frame: frame)
    }

    init(windowScene: UIWindowScene, uuid: WindowUUID) {
        self.uuid = uuid
        super.init(windowScene: windowScene)
    }

    required init?(coder: NSCoder) {
        assertionFailure("init(coder:) currently unsupported for BrowserWindow")
        self.uuid = .unavailable
        super.init(coder: coder)
    }
}

struct SceneSetupHelper {
    @MainActor
    func configureWindowFor(_ scene: UIScene,
                            windowUUID: WindowUUID,
                            screenshotServiceDelegate: UIScreenshotServiceDelegate) -> UIWindow {
        guard let windowScene = (scene as? UIWindowScene) else {
            return BrowserWindow(frame: UIScreen.main.bounds, uuid: windowUUID)
        }

        windowScene.screenshotService?.delegate = screenshotServiceDelegate

        let window = BrowserWindow(windowScene: windowScene, uuid: windowUUID)

        // Setting the initial theme correctly as we don't have a window attached yet to let ThemeManager set it
        let themeManager: ThemeManager = AppContainer.shared.resolve()
        themeManager.setWindow(window, for: windowUUID)
        /* Ecosia: Extract currentTheme to a constant so it can be reused for the window
           background colour set below without calling getCurrentTheme twice.
        window.overrideUserInterfaceStyle = themeManager.getCurrentTheme(for: windowUUID).type.getInterfaceStyle()
        */
        let currentTheme = themeManager.getCurrentTheme(for: windowUUID)
        window.overrideUserInterfaceStyle = currentTheme.type.getInterfaceStyle()

        // Ecosia: Set the window background to the NTP/homepage background colour so the window
        // is already the correct colour before the BVC's backgroundView is painted by applyTheme.
        // Without this, UIWindow's default nil/black background shows through briefly on cold
        // start (dark → light flash in light mode).
        window.backgroundColor = (currentTheme.colors as? EcosiaThemeColourPalette)?.ecosia.backgroundPrimaryDecorative

        return window
    }

    @MainActor
    func createNavigationController() -> UINavigationController {
        let navigationController = RootNavigationController()
        navigationController.isNavigationBarHidden = true
        navigationController.edgesForExtendedLayout = UIRectEdge(rawValue: 0)

        return navigationController
    }
}

class RootNavigationController: UINavigationController {
    // Forward status bar appearance decisions to the top view controller. By default, UINavigationController ignores
    // child view controllers’ preferStatusBarHidden values. Overriding this ensures that the top view controller controls
    // whether the status bar is hidden.
    override var childForStatusBarHidden: UIViewController? {
        return topViewController
    }
}
