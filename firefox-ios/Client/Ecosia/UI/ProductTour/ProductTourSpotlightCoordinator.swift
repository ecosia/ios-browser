// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import UIKit
import Ecosia

/// Coordinates the display of spotlight toasts during the product tour
final class ProductTourSpotlightCoordinator: ProductTourObserver {

    // MARK: - Properties

    private weak var viewController: UIViewController?
    private var currentSpotlight: SpotlightToast?
    private var currentStepIndex: Int = 0
    private let theme: Theme

    // The spotlight steps to show when searchCompleted state is reached
    private lazy var spotlightSteps: [SpotlightToastViewModel] = {
        return [
            SpotlightToastViewModel(
                image: UIImage(named: "spotlightCleanEnergy"),
                titleText: .localized(.spotlightStep1Title),
                descriptionText: .localized(.spotlightStep1Description),
                currentStep: 1,
                totalSteps: 2,
                primaryButtonText: .localized(.next),
                secondaryButtonText: .localized(.skip)
            ),
            SpotlightToastViewModel(
                // TODO: Export image without text and handle localisation?
                image: UIImage(named: "spotlightPlanetProfits"),
                titleText: .localized(.spotlightStep2Title),
                descriptionText: .localized(.spotlightStep2Description),
                currentStep: 2,
                totalSteps: 2,
                primaryButtonText: .localized(.gotIt),
                secondaryButtonText: .localized(.goBack)
            )
        ]
    }()

    // MARK: - Initialization

    init(viewController: UIViewController, theme: Theme) {
        self.viewController = viewController
        self.theme = theme

        // Register as observer
        ProductTourManager.shared.addObserver(self)
    }

    deinit {
        ProductTourManager.shared.removeObserver(self)
    }

    // MARK: - ProductTourObserver

    func productTourStateDidChange(_ state: ProductTourState) {
        switch state {
        case .searchCompleted:
            // Show the first spotlight when search is completed
            currentStepIndex = 0
            showCurrentSpotlight()
        case .tourCompleted:
            dismissCurrentSpotlight()
        case .firstSearch:
            dismissCurrentSpotlight()
        }
    }

    // MARK: - Public Methods

    /// Manually trigger spotlight display (useful for testing or manual triggers)
    func showSpotlightIfNeeded() {
        let currentState = ProductTourManager.shared.currentState

        if currentState == .searchCompleted {
            currentStepIndex = 0
            showCurrentSpotlight()
        }
    }

    // MARK: - Private Methods

    private func showCurrentSpotlight() {
        guard currentStepIndex < spotlightSteps.count else {
            return
        }

        guard let viewController = viewController else {
            return
        }

        let step = spotlightSteps[currentStepIndex]

        let spotlight = SpotlightToast(
            viewModel: step,
            theme: theme,
            primaryAction: { [weak self] in
                self?.handlePrimaryAction()
            },
            secondaryAction: { [weak self] in
                self?.handleSecondaryAction()
            }
        )

        currentSpotlight = spotlight
        spotlight.show(in: viewController)
    }

    private func dismissCurrentSpotlight() {
        currentSpotlight?.dismiss(false)
        currentSpotlight = nil
    }

    private func handlePrimaryAction() {
        currentStepIndex += 1

        if currentStepIndex < spotlightSteps.count {
            // Show next spotlight
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                self?.showCurrentSpotlight()
            }
        } else {
            // All steps completed
            completeTour()
        }
    }

    private func handleSecondaryAction() {
        if currentStepIndex > 0 {
            // Go back to previous step
            currentStepIndex -= 1
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                self?.showCurrentSpotlight()
            }
        } else {
            // Skip the tour
            completeTour()
        }
    }

    private func completeTour() {
        currentSpotlight = nil
        ProductTourManager.shared.completeTour()
    }
}
