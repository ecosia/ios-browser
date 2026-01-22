// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation

/// Represents the different states of the product tour onboarding flow
public enum ProductTourState: String, CaseIterable {
    case firstSearch
    case searchCompleted
    case tourCompleted

    /// The default state when no tour is active
    static var `default`: ProductTourState { .tourCompleted }
}

/// Protocol for observing product tour state changes
public protocol ProductTourObserver: AnyObject {
    func productTourStateDidChange(_ state: ProductTourState)
}

/// Manager responsible for controlling the product tour state across the app
public final class ProductTourManager {
    public static let shared = ProductTourManager()

    private let userDefaults: UserDefaults
    private let logger: Logger
    private let kProductTourStateKey = "ProductTourState"

    // Observers for state changes
    private var observers: [WeakReference] = []

    /// Current product tour state
    public private(set) var currentState: ProductTourState {
        didSet {
            guard oldValue != currentState else { return }
            saveState()
            notifyObservers()
            logger.log("Product tour state changed from \(oldValue.rawValue) to \(currentState.rawValue)",
                       level: .info,
                       category: .lifecycle)
        }
    }

    init(userDefaults: UserDefaults = .standard,
         logger: Logger = DefaultLogger.shared) {
        self.userDefaults = userDefaults
        self.logger = logger
        self.currentState = Self.loadState(from: userDefaults)
    }

    // MARK: - Public API

    /// Register an observer to receive state change notifications
    public func addObserver(_ observer: ProductTourObserver) {
        // Clean up any deallocated observers
        observers.removeAll { $0.value == nil }

        // Avoid duplicate observers
        if !observers.contains(where: { $0.value === observer }) {
            observers.append(WeakReference(observer))
        }
    }

    /// Remove an observer from receiving notifications
    public func removeObserver(_ observer: ProductTourObserver) {
        observers.removeAll { $0.value === observer }
    }

    /// Check if the product tour should show specialized homepage content
    public var shouldShowProductTourHomepage: Bool {
        return currentState == .firstSearch
    }

    /// Progress to the next state in the tour
    public func advanceToNextState() {
        switch currentState {
        case .firstSearch:
            currentState = .searchCompleted
        case .searchCompleted:
            currentState = .tourCompleted
        case .tourCompleted:
            // Already at the end
            break
        }
    }

    /// Mark the first search as completed
    public func completeFirstSearchIfNeeded() {
        guard currentState == .firstSearch else { return }
        currentState = .searchCompleted
    }

    /// Complete the entire product tour
    public func completeTour() {
        currentState = .tourCompleted
    }

    /// Reset the tour state (useful for testing or re-onboarding)
    public func resetTour() {
        currentState = .firstSearch
    }

    /// Check if the user is currently in a product tour state
    public var isInProductTour: Bool {
        return currentState != .tourCompleted
    }

    // MARK: - Private Methods

    private static func loadState(from userDefaults: UserDefaults) -> ProductTourState {
        guard OnboardingProductTourExperiment.isEnabled else { return .tourCompleted }
        let savedStateString = userDefaults.string(forKey: "ProductTourState")
        return ProductTourState(rawValue: savedStateString ?? "") ?? .default
    }

    private func saveState() {
        if OnboardingProductTourExperiment.isEnabled {
            userDefaults.set(currentState.rawValue, forKey: kProductTourStateKey)
        }
    }

    private func notifyObservers() {
        // Clean up deallocated observers before notifying
        observers.removeAll { $0.value == nil }

        observers.forEach { weakObserver in
            if let observer = weakObserver.value as? ProductTourObserver {
                observer.productTourStateDidChange(currentState)
            }
        }
    }
}

/// Weak reference wrapper to avoid retain cycles with observers
private final class WeakReference {
    weak var value: AnyObject?

    init(_ value: AnyObject) {
        self.value = value
    }
}
