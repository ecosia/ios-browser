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
                titleText: .Onboarding.Spotlight.Step1.title,
                descriptionText: .Onboarding.Spotlight.Step1.description,
                currentStep: 1,
                totalSteps: 2,
                primaryButtonText: .Onboarding.Spotlight.Step1.primaryButton,
                secondaryButtonText: .Onboarding.Spotlight.Step1.secondaryButton
            ),
            SpotlightToastViewModel(
                // TODO: Export image without text and handle localisation?
                image: UIImage(named: "spotlightPlanetProfits"),
                titleText: .Onboarding.Spotlight.Step2.title,
                descriptionText: .Onboarding.Spotlight.Step2.description,
                currentStep: 2,
                totalSteps: 2,
                primaryButtonText: .Onboarding.Spotlight.Step2.primaryButton,
                secondaryButtonText: .Onboarding.Spotlight.Step2.secondaryButton
            )
        ]
    }()
    
    // MARK: - Initialization
    
    init(viewController: UIViewController, theme: Theme) {
        self.viewController = viewController
        self.theme = theme
        
        print("🔦 [SpotlightCoordinator] Initialized with view controller: \(type(of: viewController))")
        
        // Register as observer
        ProductTourManager.shared.addObserver(self)
        print("🔦 [SpotlightCoordinator] Registered as observer with ProductTourManager")
    }
    
    deinit {
        print("🔦 [SpotlightCoordinator] Deinitializing, removing observer")
        ProductTourManager.shared.removeObserver(self)
    }
    
    // MARK: - ProductTourObserver
    
    func productTourStateDidChange(_ state: ProductTourState) {
        print("🔦 [SpotlightCoordinator] Product tour state changed to: \(state)")
        
        switch state {
        case .searchCompleted:
            // Show the first spotlight when search is completed
            print("🔦 [SpotlightCoordinator] Search completed - showing first spotlight")
            currentStepIndex = 0
            showCurrentSpotlight()
        case .tourCompleted:
            print("🔦 [SpotlightCoordinator] Tour completed - dismissing spotlight")
            dismissCurrentSpotlight()
        case .firstSearch:
            print("🔦 [SpotlightCoordinator] First search state - dismissing any active spotlight")
            dismissCurrentSpotlight()
        }
    }

    // MARK: - Public Methods
    
    /// Manually trigger spotlight display (useful for testing or manual triggers)
    func showSpotlightIfNeeded() {
        let currentState = ProductTourManager.shared.currentState
        print("🔦 [SpotlightCoordinator] showSpotlightIfNeeded called, current state: \(currentState)")
        
        if currentState == .searchCompleted {
            currentStepIndex = 0
            showCurrentSpotlight()
        } else {
            print("🔦 [SpotlightCoordinator] Not showing spotlight, state is not searchCompleted")
        }
    }
    
    // MARK: - Private Methods
    
    private func showCurrentSpotlight() {
        print("🔦 [SpotlightCoordinator] showCurrentSpotlight called, step: \(currentStepIndex), total steps: \(spotlightSteps.count)")
        
        guard currentStepIndex < spotlightSteps.count else {
            print("🔦 [SpotlightCoordinator] ❌ Step index out of bounds")
            return
        }
        
        guard let viewController = viewController else {
            print("🔦 [SpotlightCoordinator] ❌ View controller is nil")
            return
        }
        
        print("🔦 [SpotlightCoordinator] ✅ Creating spotlight for step \(currentStepIndex + 1)")
        
        let step = spotlightSteps[currentStepIndex]
        
        let spotlight = SpotlightToast(
            viewModel: step,
            theme: theme,
            primaryAction: { [weak self] in
                print("🔦 [SpotlightCoordinator] Primary action triggered")
                self?.handlePrimaryAction()
            },
            secondaryAction: { [weak self] in
                print("🔦 [SpotlightCoordinator] Secondary action triggered")
                self?.handleSecondaryAction()
            }
        )
        
        currentSpotlight = spotlight
        spotlight.show(in: viewController)
    }
    
    private func dismissCurrentSpotlight() {
        print("🔦 [SpotlightCoordinator] dismissCurrentSpotlight called, has spotlight: \(currentSpotlight != nil)")
        currentSpotlight?.dismiss(false)
        currentSpotlight = nil
    }
    
    private func handlePrimaryAction() {
        print("🔦 [SpotlightCoordinator] handlePrimaryAction - current step: \(currentStepIndex), total: \(spotlightSteps.count)")
        
        currentStepIndex += 1
        print("🔦 [SpotlightCoordinator] Incremented to step: \(currentStepIndex)")
        
        if currentStepIndex < spotlightSteps.count {
            // Show next spotlight
            print("🔦 [SpotlightCoordinator] Showing next spotlight after delay")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                print("🔦 [SpotlightCoordinator] Delay completed, showing next spotlight")
                self?.showCurrentSpotlight()
            }
        } else {
            // All steps completed
            print("🔦 [SpotlightCoordinator] All steps completed, completing tour")
            completeTour()
        }
    }
    
    private func handleSecondaryAction() {
        print("🔦 [SpotlightCoordinator] handleSecondaryAction - current step: \(currentStepIndex)")
        
        if currentStepIndex > 0 {
            // Go back to previous step
            currentStepIndex -= 1
            print("🔦 [SpotlightCoordinator] Going back to step: \(currentStepIndex)")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                print("🔦 [SpotlightCoordinator] Delay completed, showing previous spotlight")
                self?.showCurrentSpotlight()
            }
        } else {
            // Skip the tour
            print("🔦 [SpotlightCoordinator] Skipping tour from first step")
            completeTour()
        }
    }
    
    private func completeTour() {
        print("🔦 [SpotlightCoordinator] completeTour called")
        currentSpotlight = nil
        ProductTourManager.shared.completeTour()
        print("🔦 [SpotlightCoordinator] Tour marked as completed")
    }
}

// MARK: - String Extensions for Localization

extension String {
    struct Onboarding {
        struct Spotlight {
            struct Step1 {
                static let title = NSLocalizedString(
                    "Onboarding.Spotlight.Step1.Title",
                    value: "You browse with 100% clean energy",
                    comment: "Title for the first spotlight step in product tour"
                )
                static let description = NSLocalizedString(
                    "Onboarding.Spotlight.Step1.Description",
                    value: "You're helping push dirty energy off the grid! We produce more solar and wind energy than your searches take.",
                    comment: "Description for the first spotlight step in product tour"
                )
                static let primaryButton = NSLocalizedString(
                    "Onboarding.Spotlight.Step1.PrimaryButton",
                    value: "Next",
                    comment: "Primary button text for the first spotlight step"
                )
                static let secondaryButton = NSLocalizedString(
                    "Onboarding.Spotlight.Step1.SecondaryButton",
                    value: "Skip",
                    comment: "Secondary button text for the first spotlight step"
                )
            }
            
            struct Step2 {
                static let title = NSLocalizedString(
                    "Onboarding.Spotlight.Step2.Title",
                    value: "We use profits for the planet",
                    comment: "Title for the second spotlight step in product tour"
                )
                static let description = NSLocalizedString(
                    "Onboarding.Spotlight.Step2.Description",
                    value: "Unlike any other search engines, we use 100% of the profits that we make from ads for climate action!",
                    comment: "Description for the second spotlight step in product tour"
                )
                static let primaryButton = NSLocalizedString(
                    "Onboarding.Spotlight.Step2.PrimaryButton",
                    value: "Got it",
                    comment: "Primary button text for the second spotlight step"
                )
                static let secondaryButton = NSLocalizedString(
                    "Onboarding.Spotlight.Step2.SecondaryButton",
                    value: "Go back",
                    comment: "Secondary button text for the second spotlight step"
                )
            }
        }
    }
}
