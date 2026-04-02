// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Ecosia

extension BrowserCoordinator {

    /// Ecosia: Injects Referrals and EcosiaAuth into the browser view controller so that
    /// showHomepage can run setupEcosiaAdapter and the Ecosia NTP data source is used.
    /// Call once after the coordinator's browserViewController is created.
    func configureEcosiaServicesIfNeeded() {
        guard browserViewController.referrals == nil else { return }
        browserViewController.referrals = Referrals()
        _ = EcosiaAuth(browserViewController: browserViewController)
    }

    // Ecosia: Opens the Ecosia Help Center FAQ in a new tab.
    func showHelp() {
        let helpURL = EcosiaEnvironment.current.urlProvider.faq
        browserViewController.openURLInNewTab(helpURL)
        Analytics.shared.navigation(.open, label: .help)
    }

    // Ecosia: Presents the Ecosia Feedback view controller with Report Issue pre-selected.
    func showFeedback(windowUUID: WindowUUID) {
        let feedbackVC = FeedbackViewController(windowUUID: windowUUID, initialFeedbackType: .reportIssue)
        feedbackVC.onFeedbackSubmitted = { [weak self] in
            guard let view = self?.browserViewController.view else { return }
            guard let themeManager: ThemeManager = AppContainer.shared.resolve() else { return }
            let theme = themeManager.getCurrentTheme(for: windowUUID)
            SimpleToast().ecosiaShowAlertWithText(
                String.localized(.thankYouForYourFeedback),
                bottomContainer: view,
                theme: theme,
                bottomInset: view.layoutMargins.bottom
            )
        }
        browserViewController.present(feedbackVC, animated: true)
        Analytics.shared.navigation(.open, label: .sendFeedback)
    }
}
