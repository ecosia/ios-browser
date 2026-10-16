// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@preconcurrency import Foundation
import SwiftUI
import Combine
import Common

/// Centralized, reactive authentication state provider for consistent UI state across all components
/// This eliminates the need for individual components to manage their own auth state observers
@MainActor
public class EcosiaAuthUIStateProvider: ObservableObject {

    /// Auth0 gives us back a Gravatar URL when no profile picture URL is provided from a resource (e.g. Sign In with Apple)
    /// We want to strip it, therefore we track the URL
    private let gravatarURL = URL(string: "https://s.gravatar.com/avatar/")

    // MARK: - Published Properties

    /// Current authentication status
    @Published public private(set) var isLoggedIn: Bool = false

    /// Current user profile information
    @Published public private(set) var userProfile: UserProfile?

    /// Current user avatar URL
    @Published public private(set) var avatarURL: URL?

    /// Current username for display
    @Published public private(set) var username: String?

    public var seedCount: Int { impactManager.seedCount }

    public var balanceIncrement: Int? { impactManager.balanceIncrement }

    public var currentLevelNumber: Int { impactManager.currentLevelNumber }

    public var currentProgress: Double { impactManager.currentProgress }

    public var hasRegisterVisitError: Bool { impactManager.hasRegisterVisitError }

    // MARK: - Private Properties

    private var authStateObserver: NSObjectProtocol?
    private var userProfileObserver: NSObjectProtocol?
    private var seedProgressObserver: NSObjectProtocol?
    private var impactObserver: AnyCancellable?
    /// Mirrors `EcosiaAuthenticationService.hasResolvedAuthState`: whether `isLoggedIn` is a
    /// confirmed value yet, or still the initial default from before the stored-credentials
    /// check on launch completes.
    private var hasResolvedAuthState = false
    /// Normalizing the avatar to match Web's Product behaviour.
    /// Our Auth Provider (Auth0) sends us a Gravatar URL when no profile image is retrieved from a user
    /// (e.g. Apple Sign In). As of now, we replace it with our tree-image in `EcosiaAvatar` by not setting any URL
    private var normalizedAvatarURL: URL? {
        guard userProfile?.pictureURL?.baseDomain != gravatarURL?.baseDomain else { return nil }
        return userProfile?.pictureURL
    }
    private let impactManager: ImpactManager

    // MARK: - Singleton

    /// Factory for creating accounts provider - can be configured before first access
    nonisolated(unsafe) public static var accountsProviderFactory: () -> AccountsProviderProtocol = { AccountsProvider() }

    /// Shared instance for app-wide auth state
    nonisolated(unsafe) public static let shared: EcosiaAuthUIStateProvider = {
        MainActor.assumeIsolated {
            EcosiaAuthUIStateProvider(accountsProvider: accountsProviderFactory())
        }
    }()

    public init(accountsProvider: AccountsProviderProtocol, impactManager: ImpactManager? = nil) {
        self.impactManager = impactManager ?? ImpactManager(accountsProvider: accountsProvider)
        impactObserver = self.impactManager.objectWillChange.sink { [weak self] _ in
            self?.objectWillChange.send()
        }

        // Observers must be registered before the synchronous reads below: EcosiaAuthenticationService
        // resolves on its own Task, so it could otherwise finish and post its notification in the gap
        // between reading its state here and registering to hear about later updates - permanently
        // missing that one notification and leaving hasResolvedAuthState stuck false.
        setupAuthStateMonitoring()

        // Initialize state synchronously to prevent flickering
        self.isLoggedIn = EcosiaAuthenticationService.shared.isLoggedIn
        self.hasResolvedAuthState = EcosiaAuthenticationService.shared.hasResolvedAuthState
        self.userProfile = EcosiaAuthenticationService.shared.userProfile
        self.avatarURL = normalizedAvatarURL
        self.username = userProfile?.name

        self.impactManager.loadInitialSnapshot()
    }

    deinit {
        MainActor.assumeIsolated {
            if let observer = authStateObserver {
                NotificationCenter.default.removeObserver(observer)
            }
            if let observer = userProfileObserver {
                NotificationCenter.default.removeObserver(observer)
            }
            if let observer = seedProgressObserver {
                NotificationCenter.default.removeObserver(observer)
            }
        }
    }

    // MARK: - Public Interface

    /// Computed property for user display text
    public var userDisplayText: String {
        username ?? String.localized(.guestUser)
    }

    /// Computed property for level display text
    /// Returns level number and name for logged-in users, empty string for logged-out users
    public var levelDisplayText: String {
        let levelNumber = currentLevelNumber
        let levelName = GrowthPointsLevelSystem.levelName(for: levelNumber)
        return "\(String.localized(.level)) \(levelNumber) - \(levelName)"
    }

    /// Computed property for level progress (0.0 to 1.0)
    /// Returns progress from API for logged-in users, 0.25 default for initial/logged-out state
    public var levelProgress: Double {
        guard isLoggedIn else {
            return 0.25 // Default progress for logged-out users
        }
        return currentProgress
    }

    // MARK: - Private Methods

    private func setupAuthStateMonitoring() {
        // Listen for auth state changes
        authStateObserver = NotificationCenter.default.addObserver(
            forName: .EcosiaAuthStateChanged,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            Task { [notification] in
                await self?.handleAuthStateChange(notification)
            }
        }

        // Listen for user profile updates
        userProfileObserver = NotificationCenter.default.addObserver(
            forName: .EcosiaUserProfileUpdated,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task {
                await self?.handleUserProfileUpdate()
            }
        }

        // Listen for seed progress updates (for logged-out users)
        seedProgressObserver = NotificationCenter.default.addObserver(
            forName: UserDefaultsSeedProgressManager.progressUpdatedNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task {
                await self?.handleSeedProgressUpdate()
            }
        }
    }

    /// Not `private`: tests call this directly on their own instance instead of posting a real
    /// `NotificationCenter` notification, which `.shared` would also receive and react to.
    func handleAuthStateChange(_ notification: Notification) async {
        // Every dispatch of this notification means EcosiaAuthenticationService has a confirmed
        // isLoggedIn value now, whether this is the launch-time resolution or a later login/logout.
        isLoggedIn = EcosiaAuthenticationService.shared.isLoggedIn
        hasResolvedAuthState = true

        if let actionType = notification.userInfo?["actionType"] as? EcosiaAuthActionType {
            switch actionType {
            case .userLoggedIn:
                impactManager.handleUserLoggedIn()
            case .userLoggedOut:
                impactManager.handleUserLoggedOut()
            case .authStateLoaded:
                impactManager.handleAuthStateLoaded()
            }
        }
    }

    @MainActor
    private func handleUserProfileUpdate() {
        Task { @MainActor in
            isLoggedIn = EcosiaAuthenticationService.shared.isLoggedIn
        }
        userProfile = EcosiaAuthenticationService.shared.userProfile
        username = userProfile?.name
        avatarURL = normalizedAvatarURL
    }

    @MainActor
    private func handleSeedProgressUpdate() {
        impactManager.handleSeedProgressUpdate()
    }

    // MARK: - Public Methods

    /// Refreshes seed state based on authentication status.
    ///
    /// Should be called when the NTP appears or app returns from background.
    @MainActor
    public func refreshSeedState() {
        if !hasResolvedAuthState {
            // Re-sync directly from the service rather than trusting this mirror alone: its
            // resolution notification only reaches registered browser windows, so it can resolve
            // without ever notifying this provider (e.g. none were registered yet) - leaving
            // hasResolvedAuthState stuck false forever and every future call deferring for nothing.
            isLoggedIn = EcosiaAuthenticationService.shared.isLoggedIn
            hasResolvedAuthState = EcosiaAuthenticationService.shared.hasResolvedAuthState
        }
        impactManager.refreshSeedState()
    }

    // MARK: - Debug Methods

    @MainActor
    public func debugUpdateBalance(_ response: AccountVisitResponse) {
        impactManager.debugUpdateBalance(response)
    }

    @MainActor
    public func debugTriggerLevelUpAnimation() {
        impactManager.debugTriggerLevelUpAnimation()
    }

    @MainActor
    public func debugAddSeeds(_ count: Int) {
        impactManager.debugAddSeeds(count)
    }
}
