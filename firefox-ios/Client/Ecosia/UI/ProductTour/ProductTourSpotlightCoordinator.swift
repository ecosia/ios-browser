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
    private weak var bottomContentView: UIView?
    private var currentSpotlight: SpotlightToast?
    private var currentStepIndex: Int = 0
    private var theme: Theme
    // TODO: Make dynamic when privacy tour is introduced (MOB-3905)
    private let analyticsLabel: Analytics.Label.Onboarding = .serpTour

    /// Whether a spotlight is currently being displayed
    var isShowingSpotlight: Bool {
        return currentSpotlight != nil
    }

    // The spotlight steps to show when search is completed
    private lazy var spotlightSteps: [SpotlightToastViewModel] = {
        return [
            SpotlightToastViewModel(
                image: UIImage(named: "spotlightCleanEnergy"),
                titleText: .localized(.serpSpotlightStep1Title),
                descriptionText: .localized(.serpSpotlightStep1Description),
                currentStep: 1,
                totalSteps: 2,
                primaryButtonText: .localized(.next),
                secondaryButtonText: .localized(.skip)
            ),
            SpotlightToastViewModel(
                image: UIImage(named: "spotlightPlanetProfits"),
                titleText: .localized(.serpSpotlightStep2Title),
                descriptionText: .localized(.serpSpotlightStep2Description),
                currentStep: 2,
                totalSteps: 2,
                primaryButtonText: .localized(.gotIt),
                secondaryButtonText: .localized(.goBack)
            )
        ]
    }()

    // The spotlight to show when the user visits an external website
    private lazy var externalWebsiteSpotlight: SpotlightToastViewModel = {
        SpotlightToastViewModel(
            image: nil,
            titleText: .localized(.protectionSpotlightTitle),
            descriptionText: .localized(.protectionSpotlightDescription),
            currentStep: 1,
            totalSteps: 1,
            primaryButtonText: .localized(.gotIt),
            secondaryButtonText: .localized(.readMore) // TODO: Add right side icon
        )
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

    func productTour(didReceiveEvent event: ProductTourEvent) {
        switch event {
        case .searchCompleted:
            currentStepIndex = 0
            showSearchSpotlight()
        case .externalWebsiteVisited:
            showExternalWebsiteSpotlight()
        case .tourCompleted:
            dismissCurrentSpotlight()
        case .tourStarted:
            dismissCurrentSpotlight()
        }
    }

    // MARK: - Public Methods

    /// Updates the theme for the coordinator and any currently displayed spotlight
    func updateTheme(_ newTheme: Theme) {
        theme = newTheme
        currentSpotlight?.applyTheme(theme: newTheme)
    }

    /// Manually trigger spotlight display (useful for testing or manual triggers)
    func showSpotlightIfNeeded() {
        if ProductTourManager.shared.shouldShowSearchSpotlight {
            currentStepIndex = 0
            showSearchSpotlight()
        } else if ProductTourManager.shared.shouldShowExternalWebsiteSpotlight {
            showExternalWebsiteSpotlight()
        }
    }

    // MARK: - Private Methods

    private func showSearchSpotlight() {
        guard currentStepIndex < spotlightSteps.count else { return }

        guard let viewController = viewController,
              let bottomContentView = bottomContentView else { return }

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
            self?.completeSearchMilestone()
        }

        currentSpotlight = spotlight
        spotlight.show(in: viewController, bottomAnchorView: bottomContentView)
        Analytics.shared.spotlightTourDisplay(label: analyticsLabel, step: step.currentStep)
    }

    private func showExternalWebsiteSpotlight() {
        guard let viewController = viewController,
              let bottomContentView = bottomContentView else { return }

        // Dismiss any existing spotlight before showing the external website one
        dismissCurrentSpotlight()

        let step = externalWebsiteSpotlight

        let spotlight = SpotlightToast(
            viewModel: step,
            theme: theme,
            // TODO: Avoid duplication, e.g. re-use action methods
            primaryAction: { [weak self] in
                self?.dismissCurrentSpotlight()
                self?.completeExternalWebsiteMilestone()
            },
            secondaryAction: {
                // TODO: Open helpscout links
                print("Read more tapped - open helpscout article")
            }
        )

        spotlight.completionHandler = { [weak self] _ in
            self?.completeExternalWebsiteMilestone()
        }

        currentSpotlight = spotlight
        spotlight.show(in: viewController, bottomAnchorView: bottomContentView)
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
            completeSearchMilestone()
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
            completeSearchMilestone()
            Analytics.shared.spotlightTourClick(label: analyticsLabel, action: .skip, step: currentStep.currentStep)
        }
    }

    private func completeSearchMilestone() {
        currentSpotlight = nil
        ProductTourManager.shared.completeSearchSpotlight()
    }

    private func completeExternalWebsiteMilestone() {
        currentSpotlight = nil
        ProductTourManager.shared.completeExternalWebsiteSpotlight()
    }
}
