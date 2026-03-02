// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import SafariServices
import Common
import Ecosia

// MARK: - Product Tour Spotlight Integration
extension BrowserViewController {

    // MARK: - Setup

    /// Sets up the product tour spotlight coordinator
    /// Call this in viewDidLoad or similar lifecycle method
    func setupProductTourSpotlightIfNeeded() {
        guard OnboardingProductTourExperiment.isEnabled,
              ProductTourManager.shared.isInProductTour else {
            return
        }

        // Only create coordinator if it doesn't exist
        guard spotlightCoordinator == nil else {
            return
        }

        makeSpotlightCoordinator()
    }

    /// Updates the spotlight coordinator's theme when theme changes
    /// Call this when theme changes (e.g., dark mode toggle)
    func updateSpotlightThemeIfNeeded() {
        guard OnboardingProductTourExperiment.isEnabled,
              ProductTourManager.shared.isInProductTour else {
            return
        }

        if let coordinator = spotlightCoordinator {
            // Update theme on existing coordinator
            let theme = themeManager.getCurrentTheme(for: windowUUID)
            coordinator.updateTheme(theme)
        } else {
            // Create coordinator if it doesn't exist yet
            makeSpotlightCoordinator()
        }
    }

    // MARK: - Private Helpers

    @discardableResult
    private func makeSpotlightCoordinator() -> ProductTourSpotlightCoordinator {
        let theme = themeManager.getCurrentTheme(for: windowUUID)
        let coordinator = ProductTourSpotlightCoordinator(
            viewController: self,
            bottomContentView: bottomContentStackView,
            theme: theme
        )
        coordinator.openURL = { [weak self] url in
            let safariVC = SFSafariViewController(url: url)
            safariVC.modalPresentationStyle = .pageSheet
            self?.present(safariVC, animated: true)
        }
        spotlightCoordinator = coordinator
        return coordinator
    }
}
