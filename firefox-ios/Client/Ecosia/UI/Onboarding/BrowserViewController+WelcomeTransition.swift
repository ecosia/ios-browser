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
        // Hide toolbars initially to prevent flash
        header.alpha = 0
        bottomContainer.alpha = 0

        // Hide content and set background color to match NTP
        contentStackView.alpha = 0
        let theme = themeManager.getCurrentTheme(for: windowUUID)
        // TODO: Investigate colors behind toolbars before transition
        view.backgroundColor = theme.colors.ecosia.backgroundPrimaryDecorative
    }

    /// Animates the top and bottom toolbars sliding in from the edges
    /// This is called after the welcome screen fades out
    func animateToolbarsIn() {
        let margin: CGFloat = 20 // Additional margin to ensure views are fully hidden
        let topOffset = -(header.frame.height + view.safeAreaInsets.top + margin)
        let bottomOffset = bottomContainer.frame.height + view.safeAreaInsets.bottom + margin

        // Set initial off-screen positions and make visible
        header.alpha = 1.0
        bottomContainer.alpha = 1.0
        header.transform = CGAffineTransform(translationX: 0, y: topOffset)
        bottomContainer.transform = CGAffineTransform(translationX: 0, y: bottomOffset)

        // Animate to final positions
        UIView.animate(
            withDuration: 0.35,
            delay: 0,
            options: .curveEaseInOut,
            animations: { [weak self] in
                self?.header.transform = .identity
                self?.bottomContainer.transform = .identity
                self?.contentStackView.alpha = 1
            },
        )
    }

    private static func hash(for key: String) -> Int {
        return key.hashValue
    }
}
