// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import ComponentLibrary
import Foundation
import Shared

class ShowWallpaperOnboarding: HiddenSetting {
    private weak var settingsDelegate: DebugSettingsDelegate?

    init(settings: SettingsTableViewController,
         settingsDelegate: DebugSettingsDelegate) {
        self.settingsDelegate = settingsDelegate
        super.init(settings: settings)
    }

    override var title: NSAttributedString? {
        guard let theme else { return nil }
        return NSAttributedString(string: "Show wallpaper onboarding",
                                  attributes: [NSAttributedString.Key.foregroundColor: theme.colors.textPrimary])
    }

    override func onClick(_ navigationController: UINavigationController?) {
        let windowUUID = settings.windowUUID

        let viewModel = WallpaperSelectorViewModel(wallpaperManager: WallpaperManager())
        let viewController = WallpaperSelectorViewController(
            viewModel: viewModel,
            windowUUID: windowUUID
        )

        let bottomSheetViewModel = BottomSheetViewModel(
            closeButtonA11yLabel: .CloseButtonTitle,
            closeButtonA11yIdentifier: AccessibilityIdentifiers.FirefoxHomepage.OtherButtons.closeButton
        )

        let bottomSheetVC = BottomSheetViewController(
            viewModel: bottomSheetViewModel,
            childViewController: viewController,
            windowUUID: windowUUID
        )

        navigationController?.present(bottomSheetVC, animated: true) {
            // Mark onboarding as seen after presenting
            WallpaperManager().onboardingSeen()
        }
    }
}
