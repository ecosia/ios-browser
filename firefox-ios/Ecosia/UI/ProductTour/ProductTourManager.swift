// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation

/// Events broadcast to observers when the product tour progresses
public enum ProductTourEvent {
    /// The tour has started; the homepage should show first-search content
    case tourStarted
    /// The user completed their first search; show the search spotlight
    case searchCompleted
    /// The user visited an external website; show the external website spotlight
    case externalWebsiteVisited
    /// All milestones are done; the tour is finished
    case tourCompleted
}

/// Tracks which product tour milestones have been completed
public struct ProductTourMilestones: OptionSet, Equatable {
    public let rawValue: Int
    public init(rawValue: Int) { self.rawValue = rawValue }

    /// The user has performed their first search (pre-spotlight)
    public static let firstSearchDone = ProductTourMilestones(rawValue: 1 << 0)
    /// The search spotlight flow has been completed/skipped/dismissed
    public static let searchSpotlightDone = ProductTourMilestones(rawValue: 1 << 1)
    /// The user has visited an external website (pre-spotlight)
    public static let externalWebsiteVisitDone = ProductTourMilestones(rawValue: 1 << 2)
    /// The external website spotlight has been completed/dismissed
    public static let externalWebsiteSpotlightDone = ProductTourMilestones(rawValue: 1 << 3)

    /// All milestones required to finish the tour
    public static let all: ProductTourMilestones = [
        .firstSearchDone,
        .searchSpotlightDone,
        .externalWebsiteVisitDone,
        .externalWebsiteSpotlightDone
    ]
}

/// Protocol for observing product tour events
public protocol ProductTourObserver: AnyObject {
    func productTour(didReceiveEvent event: ProductTourEvent)
}

/// Manager responsible for controlling the product tour across the app.
///
/// The tour has two independent tracks that can happen in any order:
///   1. **Search track**: first search → search spotlight
///   2. **External website track**: first external website visit → external website spotlight
///
/// The tour completes automatically once both tracks are finished.
///
/// The manager automatically listens to authentication state changes. When a user logs in,
/// the ``AccountOrigin`` determines which tour variant to start (new account vs. existing account).
public final class ProductTourManager {
    public static let shared = ProductTourManager()
    private static let milestonesKey = "ProductTourMilestones"

    private let userDefaults: UserDefaults
    private let authManager: EcosiaBrowserWindowAuthManager

    // Observers for event notifications
    private var observers: [WeakReference] = []

    /// Tracks which independent milestones have been completed
    public private(set) var completedMilestones: ProductTourMilestones {
        didSet {
            guard oldValue != completedMilestones else { return }
            saveMilestones()
        }
    }

    public init(userDefaults: UserDefaults = .standard,
                authManager: EcosiaBrowserWindowAuthManager = .shared) {
        self.userDefaults = userDefaults
        self.authManager = authManager
        self.completedMilestones = Self.loadMilestones(from: userDefaults)
        authManager.subscribe(observer: self, selector: #selector(handleAuthStateChanged(_:)))
    }

    deinit {
        authManager.unsubscribe(observer: self)
    }

    // MARK: - Auth State Observation

    @objc private func handleAuthStateChanged(_ notification: Notification) {
        guard let actionType = notification.userInfo?["actionType"] as? EcosiaAuthActionType,
              let authState = notification.userInfo?["authState"] as? AuthWindowState else {
            return
        }

        if case .userLoggedIn = actionType, isInProductTour {
            applyAccountOriginToTour(authState.accountOrigin)
        }
    }

    /// Adjusts milestones based on account origin.
    ///
    /// - New account / no login: full tour (first-search → search spotlight → external website → external website spotlight)
    /// - Existing account: skip the search track entirely, only the external website track remains
    private func applyAccountOriginToTour(_ accountOrigin: AccountOrigin?) {
        guard accountOrigin == .existingAccount else { return }

        // Existing users skip the first-search homepage and search spotlight
        completedMilestones.insert(.firstSearchDone)
        completedMilestones.insert(.searchSpotlightDone)
        notifyObservers(event: .searchCompleted)
    }

    // MARK: - Public API

    /// Register an observer to receive event notifications
    public func addObserver(_ observer: ProductTourObserver) {
        observers.removeAll { $0.value == nil }
        if !observers.contains(where: { $0.value === observer }) {
            observers.append(WeakReference(observer))
        }
    }

    /// Remove an observer from receiving notifications
    public func removeObserver(_ observer: ProductTourObserver) {
        observers.removeAll { $0.value === observer }
    }

    /// Whether the user is currently in the product tour
    public var isInProductTour: Bool {
        guard OnboardingProductTourExperiment.isEnabled else { return false }
        return !completedMilestones.contains(.all)
    }

    /// Whether the homepage should show product tour first-search content.
    /// True when the tour is active and the user hasn't searched yet.
    public var shouldShowProductTourHomepage: Bool {
        return isInProductTour && !completedMilestones.contains(.firstSearchDone)
    }

    /// Whether the search spotlight should be shown.
    /// True when the first search is done but the spotlight hasn't been shown yet.
    public var shouldShowSearchSpotlight: Bool {
        return completedMilestones.contains(.firstSearchDone)
            && !completedMilestones.contains(.searchSpotlightDone)
    }

    /// Whether the external website spotlight should be shown.
    /// True when an external website was visited but the spotlight hasn't been shown yet.
    public var shouldShowExternalWebsiteSpotlight: Bool {
        return completedMilestones.contains(.externalWebsiteVisitDone)
            && !completedMilestones.contains(.externalWebsiteSpotlightDone)
    }

    // MARK: - Milestone Completion

    /// Call when the user performs their first search on Ecosia.
    public func completeFirstSearchIfNeeded() {
        guard isInProductTour,
              !completedMilestones.contains(.firstSearchDone) else { return }
        completedMilestones.insert(.firstSearchDone)
        notifyObservers(event: .searchCompleted)
    }

    /// Call when the user navigates to an external (non-Ecosia) website.
    public func completeExternalWebsiteVisitIfNeeded() {
        guard isInProductTour,
              !completedMilestones.contains(.externalWebsiteVisitDone) else { return }
        completedMilestones.insert(.externalWebsiteVisitDone)
        notifyObservers(event: .externalWebsiteVisited)
    }

    /// Call when the search spotlight is completed, skipped, or dismissed.
    public func completeSearchSpotlight() {
        guard !completedMilestones.contains(.searchSpotlightDone) else { return }
        completedMilestones.insert(.searchSpotlightDone)
        completeTourIfAllMilestonesCompleted()
    }

    /// Call when the external website spotlight is completed or dismissed.
    public func completeExternalWebsiteSpotlight() {
        guard !completedMilestones.contains(.externalWebsiteSpotlightDone) else { return }
        completedMilestones.insert(.externalWebsiteSpotlightDone)
        completeTourIfAllMilestonesCompleted()
    }

    /// Force-complete the entire product tour.
    public func completeTour() {
        guard isInProductTour else { return }
        completedMilestones = .all
        notifyObservers(event: .tourCompleted)
    }

    /// Reset the tour state (useful for testing or re-onboarding).
    public func resetTour() {
        completedMilestones = []
        notifyObservers(event: .tourStarted)
    }

    // MARK: - Private Methods

    private func completeTourIfAllMilestonesCompleted() {
        if completedMilestones.contains(.all) {
            notifyObservers(event: .tourCompleted)
        }
    }

    private static func loadMilestones(from userDefaults: UserDefaults) -> ProductTourMilestones {
        guard OnboardingProductTourExperiment.isEnabled else { return .all }
        let rawValue = userDefaults.integer(forKey: milestonesKey)
        return ProductTourMilestones(rawValue: rawValue)
    }

    private func saveMilestones() {
        if OnboardingProductTourExperiment.isEnabled {
            userDefaults.set(completedMilestones.rawValue, forKey: Self.milestonesKey)
        }
    }

    private func notifyObservers(event: ProductTourEvent) {
        observers.removeAll { $0.value == nil }
        observers.forEach { weakObserver in
            if let observer = weakObserver.value as? ProductTourObserver {
                observer.productTour(didReceiveEvent: event)
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
