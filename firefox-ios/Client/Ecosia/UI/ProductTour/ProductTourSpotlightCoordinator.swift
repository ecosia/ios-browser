// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import UIKit
import Ecosia

/// Coordinates the display of spotlight toasts during the product tour
final class ProductTourSpotlightCoordinator: ProductTourObserver {

    // MARK: - Types

    /// Describes how the secondary button should behave (and be tracked) in a spotlight.
    private enum SecondaryAction {
        /// Navigate back to the previous step (multi-step spotlights).
        case back
        /// Skip the entire spotlight sequence.
        case skip
        /// Open a URL (e.g. "Read More").
        case openURL(URL)
    }

    /// Groups everything the coordinator needs to present and track a spotlight sequence.
    private struct SpotlightConfiguration {
        /// Ordered steps in this spotlight sequence.
        let steps: [SpotlightToastViewModel]
        /// Analytics label used for every event in this sequence.
        let analyticsLabel: Analytics.Label.Onboarding
        /// Returns the secondary action for a given step index.
        /// For multi-step spotlights the action typically alternates between skip/back.
        let secondaryAction: (_ stepIndex: Int) -> SecondaryAction
        /// Called once the spotlight sequence finishes (completed, skipped, or dismissed).
        let onComplete: () -> Void
    }

    // MARK: - Properties

    private weak var viewController: UIViewController?
    private weak var bottomContentView: UIView?
    private var currentSpotlight: SpotlightToast?
    private var currentStepIndex: Int = 0
    private var currentConfiguration: SpotlightConfiguration?
    private var theme: Theme
    // Safety: set once at init, accessed in nonisolated deinit only for removeObserver.
    nonisolated(unsafe) private let tourManager: ProductTourManager

    /// Closure called when the coordinator needs to open a URL in a new tab
    var openURL: ((URL) -> Void)?

    /// Whether a spotlight is currently being displayed
    var isShowingSpotlight: Bool {
        return currentSpotlight != nil
    }

    // MARK: - Spotlight Configurations

    private lazy var searchConfiguration: SpotlightConfiguration = {
        SpotlightConfiguration(
            steps: [
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
            ],
            analyticsLabel: .serpTour,
            secondaryAction: { stepIndex in
                stepIndex > 0 ? .back : .skip
            },
            onComplete: { [weak self] in
                self?.tourManager.completeSearchSpotlight()
            }
        )
    }()

    private lazy var externalWebsiteConfiguration: SpotlightConfiguration = {
        SpotlightConfiguration(
            steps: [
                SpotlightToastViewModel(
                    image: nil,
                    titleText: .localized(.protectionSpotlightTitle),
                    descriptionText: .localized(.protectionSpotlightDescription),
                    currentStep: 1,
                    totalSteps: 1,
                    primaryButtonText: .localized(.gotIt),
                    secondaryButtonText: .localized(.readMore),
                    secondaryButtonIcon: UIImage(named: "openLink")
                )
            ],
            analyticsLabel: .privacyTour,
            secondaryAction: { _ in
                .openURL(EcosiaEnvironment.current.urlProvider.trackingProtectionHelpPage)
            },
            onComplete: { [weak self] in
                self?.tourManager.completeExternalWebsiteSpotlight()
            }
        )
    }()

    // MARK: - Initialization

    init(viewController: UIViewController, bottomContentView: UIView, theme: Theme, tourManager: ProductTourManager = .shared) {
        self.viewController = viewController
        self.bottomContentView = bottomContentView
        self.theme = theme
        self.tourManager = tourManager

        // Register as observer
        tourManager.addObserver(self)
    }

    deinit {
        tourManager.removeObserver(self)
    }

    // MARK: - ProductTourObserver

    func productTour(didReceiveEvent event: ProductTourEvent) {
        switch event {
        case .searchCompleted:
            currentStepIndex = 0
            showSpotlight(with: searchConfiguration)
        case .externalWebsiteVisited:
            showSpotlight(with: externalWebsiteConfiguration)
        case .tourCompleted, .tourStarted:
            dismissCurrentSpotlight()
        case .searchTrackCompleted, .signInFlowStarted, .signInFlowEnded:
            break
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
        if tourManager.shouldShowSearchSpotlight {
            currentStepIndex = 0
            showSpotlight(with: searchConfiguration)
        } else if tourManager.shouldShowExternalWebsiteSpotlight {
            showSpotlight(with: externalWebsiteConfiguration)
        }
    }

    // MARK: - Private Methods – Presentation

    private func showSpotlight(with configuration: SpotlightConfiguration) {
        guard let viewController = viewController,
              let bottomContentView = bottomContentView else { return }

        // Dismiss any existing spotlight before showing a new one
        dismissCurrentSpotlight()

        currentStepIndex = 0
        currentConfiguration = configuration
        presentStep(in: viewController, bottomAnchorView: bottomContentView)
    }

    /// Creates and shows the `SpotlightToast` for the current step.
    private func presentStep(in viewController: UIViewController, bottomAnchorView: UIView) {
        guard let configuration = currentConfiguration,
              currentStepIndex < configuration.steps.count else { return }

        let step = configuration.steps[currentStepIndex]

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

        // Dismiss by tapping outside completes the spotlight
        spotlight.completionHandler = { [weak self] _ in
            self?.completeCurrentSpotlight()
        }

        currentSpotlight = spotlight
        spotlight.show(in: viewController, bottomAnchorView: bottomAnchorView)
        Analytics.shared.spotlightTourDisplay(label: configuration.analyticsLabel, step: step.currentStep)
    }

    // MARK: - Private Methods – Actions

    func handlePrimaryAction() {
        guard let configuration = currentConfiguration else { return }

        let currentStep = configuration.steps[currentStepIndex]
        currentStepIndex += 1

        if currentStepIndex < configuration.steps.count {
            // Transition to next spotlight with forward animation
            let nextStep = configuration.steps[currentStepIndex]
            currentSpotlight?.transition(to: nextStep, direction: .forward)
            Analytics.shared.spotlightTourClick(label: configuration.analyticsLabel, action: .next, step: currentStep.currentStep)
            Analytics.shared.spotlightTourDisplay(label: configuration.analyticsLabel, step: nextStep.currentStep)
        } else {
            // All steps completed
            Analytics.shared.spotlightTourClick(label: configuration.analyticsLabel, action: .complete, step: currentStep.currentStep)
            dismissCurrentSpotlight()
            completeCurrentSpotlight()
        }
    }

    func handleSecondaryAction() {
        guard let configuration = currentConfiguration else { return }

        let currentStep = configuration.steps[currentStepIndex]

        switch configuration.secondaryAction(currentStepIndex) {
        case .back:
            currentStepIndex -= 1
            let previousStep = configuration.steps[currentStepIndex]
            currentSpotlight?.transition(to: previousStep, direction: .backward)
            Analytics.shared.spotlightTourClick(label: configuration.analyticsLabel, action: .back, step: currentStep.currentStep)
            Analytics.shared.spotlightTourDisplay(label: configuration.analyticsLabel, step: previousStep.currentStep)

        case .skip:
            Analytics.shared.spotlightTourClick(label: configuration.analyticsLabel, action: .skip, step: currentStep.currentStep)
            dismissCurrentSpotlight()
            completeCurrentSpotlight()

        case .openURL(let url):
            Analytics.shared.spotlightTourClick(label: configuration.analyticsLabel, action: .readMore, step: currentStep.currentStep)
            dismissCurrentSpotlight()
            completeCurrentSpotlight()
            openURL?(url)
        }
    }

    // MARK: - Private Methods – Lifecycle

    private func dismissCurrentSpotlight() {
        currentSpotlight?.dismiss(false)
        currentSpotlight = nil
    }

    private func completeCurrentSpotlight() {
        currentSpotlight = nil
        currentConfiguration?.onComplete()
        currentConfiguration = nil
    }
}
