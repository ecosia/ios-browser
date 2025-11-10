// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Shared

// MARK: - Welcome Transition Animation
extension BrowserViewController {
    private static let welcomeTransitionBackgroundKey = "welcomeTransitionBackground"

    /// Prepares the toolbars to be animated in after welcome dismissal
    /// This should be called early in the view lifecycle
    func prepareToolbarsForWelcomeTransition() {
        // Move toolbars completely off-screen
        let screenHeight = UIScreen.main.bounds.height
        header.transform = CGAffineTransform(translationX: 0, y: -screenHeight)
        bottomContainer.transform = CGAffineTransform(translationX: 0, y: screenHeight)
        header.alpha = 1.0
        bottomContainer.alpha = 1.0

        // Hide content and set background color to match NTP
        contentStackView.alpha = 0
        let theme = themeManager.getCurrentTheme(for: windowUUID)
        view.backgroundColor = theme.colors.ecosia.backgroundPrimaryDecorative
    }

    /// Animates the top and bottom toolbars sliding in from the edges
    /// This is called after the welcome screen fades out
    func animateToolbarsIn() {
        // Animate to final positions
        UIView.animate(
            withDuration: 0.2,
            delay: 0,
            options: .curveEaseInOut,
            animations: { [weak self] in
                self?.header.transform = .identity
                self?.bottomContainer.transform = .identity
            },
            completion: { [weak self] _ in
                // Restore visibility after animation
                UIView.animate(withDuration: 0.2) {
                    self?.contentStackView.alpha = 1
                }
            }
        )
    }

    private static func hash(for key: String) -> Int {
        return key.hashValue
    }
}
