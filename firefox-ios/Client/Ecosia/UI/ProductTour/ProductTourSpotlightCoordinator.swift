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
    private var bottomContentView: UIView
    private var currentSpotlight: SpotlightToast?
    private var currentStepIndex: Int = 0
    private let theme: Theme
    // TODO: Make dynamic when privacy tour is introduced (MOB-3905)
    private let analyticsLabel: Analytics.Label.Onboarding = .serpTour

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

    init(viewController: UIViewController, bottomContentView: UIView, theme: Theme) {
        self.viewController = viewController
        self.bottomContentView = bottomContentView
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

        // Set completion handler for when toast is dismissed by tapping outside
        spotlight.completionHandler = { [weak self] _ in
            self?.completeTour()
        }

        currentSpotlight = spotlight
        spotlight.show(in: viewController, bottomAnchorView: bottomContentView)
        Analytics.shared.spotlightTourDisplay(label: analyticsLabel, step: step.currentStep)
    }

    private func dismissCurrentSpotlight() {
        currentSpotlight?.dismiss(false)
        currentSpotlight = nil
    }

    private func handlePrimaryAction() {
        let currentStep = spotlightSteps[currentStepIndex]

        currentStepIndex += 1

        if currentStepIndex < spotlightSteps.count {
            // Transition to next spotlight with forward animation
            let nextStep = spotlightSteps[currentStepIndex]
            currentSpotlight?.transition(to: nextStep, direction: .forward)
            Analytics.shared.spotlightTourClick(label: analyticsLabel, action: .next, step: currentStep.currentStep)
            Analytics.shared.spotlightTourDisplay(label: analyticsLabel, step: nextStep.currentStep)
        } else {
            // All steps completed
            dismissCurrentSpotlight()
            completeTour()
            Analytics.shared.spotlightTourClick(label: analyticsLabel, action: .complete, step: currentStep.currentStep)
        }
    }

    private func handleSecondaryAction() {
        let currentStep = spotlightSteps[currentStepIndex]

        if currentStepIndex > 0 {
            // Transition back to previous step with backward animation
            currentStepIndex -= 1
            let previousStep = spotlightSteps[currentStepIndex]
            currentSpotlight?.transition(to: previousStep, direction: .backward)
            Analytics.shared.spotlightTourClick(label: analyticsLabel, action: .back, step: currentStep.currentStep)
            Analytics.shared.spotlightTourDisplay(label: analyticsLabel, step: previousStep.currentStep)
        } else {
            // Skip the tour
            dismissCurrentSpotlight()
            completeTour()
            Analytics.shared.spotlightTourClick(label: analyticsLabel, action: .skip, step: currentStep.currentStep)
        }
    }

    private func completeTour() {
        currentSpotlight = nil
        ProductTourManager.shared.completeTour()
    }
}
