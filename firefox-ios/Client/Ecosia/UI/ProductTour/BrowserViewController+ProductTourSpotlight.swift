// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common
import Ecosia

// MARK: - Product Tour Spotlight Integration
extension BrowserViewController {

    // MARK: - Setup

    /// Sets up the product tour spotlight coordinator
    /// Call this in viewDidLoad or similar lifecycle method
    func setupProductTourSpotlight() {
        guard OnboardingProductTourExperiment.isEnabled else {
            return
        }

        // Only create coordinator if it doesn't exist
        guard spotlightCoordinator == nil else {
            return
        }

        let theme = themeManager.getCurrentTheme(for: windowUUID)
        spotlightCoordinator = ProductTourSpotlightCoordinator(
            viewController: self,
            bottomContentView: bottomContentStackView,
            theme: theme
        )
    }

    /// Updates the spotlight coordinator's theme when theme changes
    /// Call this when theme changes (e.g., dark mode toggle)
    func updateSpotlightTheme() {
        guard OnboardingProductTourExperiment.isEnabled else {
            return
        }

        // Don't recreate coordinator if a spotlight is currently showing
        guard spotlightCoordinator?.isShowingSpotlight != true else {
            return
        }

        // Recreate coordinator with new theme
        let theme = themeManager.getCurrentTheme(for: windowUUID)
        spotlightCoordinator = ProductTourSpotlightCoordinator(
            viewController: self,
            bottomContentView: bottomContentStackView,
            theme: theme
        )
    }
}
