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

    /// Current seed count (server-based for logged in users, local for guests)
    /// Placeholder only: `init` always overwrites this synchronously via `ImpactManager.loadSeeds`
    /// before the object is observable, so `ImpactManager` is read from one place.
    @Published public private(set) var seedCount: Int = 0

    /// Current user avatar URL
    @Published public private(set) var avatarURL: URL?

    /// Current username for display
    @Published public private(set) var username: String?

    /// Balance increment for animations (temporary state)
    @Published public private(set) var balanceIncrement: Int?

    /// Current level number (from API for logged-in users, 1 for logged-out)
    @Published public private(set) var currentLevelNumber: Int = 1

    /// Current progress towards next level (from API for logged-in users, default 0.25 for initial state)
    @Published public private(set) var currentProgress: Double = 0.25

    /// Error state for register visit failures (read-only externally, set only by this class)
    @Published public private(set) var hasRegisterVisitError: Bool = false

    // MARK: - Private Properties

    private var authStateObserver: NSObjectProtocol?
    private var userProfileObserver: NSObjectProtocol?
    private let accountsProvider: AccountsProviderProtocol
    private let impactManager: ImpactManager
    /// Normalizing the avatar to match Web's Product behaviour.
    /// Our Auth Provider (Auth0) sends us a Gravatar URL when no profile image is retrieved from a user
    /// (e.g. Apple Sign In). As of now, we replace it with our tree-image in `EcosiaAvatar` by not setting any URL
    private var normalizedAvatarURL: URL? {
        guard userProfile?.pictureURL?.baseDomain != gravatarURL?.baseDomain else { return nil }
        return userProfile?.pictureURL
    }

    // MARK: - Singleton

    /// Factory for creating accounts provider - can be configured before first access
    nonisolated(unsafe) public static var accountsProviderFactory: () -> AccountsProviderProtocol = { AccountsProvider() }

    /// Shared instance for app-wide auth state
    nonisolated(unsafe) public static let shared: EcosiaAuthUIStateProvider = {
        MainActor.assumeIsolated {
            EcosiaAuthUIStateProvider(accountsProvider: accountsProviderFactory())
        }
    }()

    public init(accountsProvider: AccountsProviderProtocol, impactManager: ImpactManager = ImpactManager()) {
        self.accountsProvider = accountsProvider
        self.impactManager = impactManager

        // Initialize state synchronously to prevent flickering
        syncAuthState()

        // Seed real state synchronously so the UI never flashes a placeholder. `handleNewSeeds()`,
        // triggered separately, fetches and persists the real value shortly after.
        let snapshot = impactManager.loadSeeds(isLoggedIn: isLoggedIn, userId: userProfile?.sub)
        seedCount = snapshot.seedCount
        currentLevelNumber = snapshot.currentLevelNumber
        currentProgress = snapshot.currentProgress

        setupAuthStateMonitoring()
    }

    deinit {
        MainActor.assumeIsolated {
            if let observer = authStateObserver {
                NotificationCenter.default.removeObserver(observer)
            }
            if let observer = userProfileObserver {
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
    }

    private func handleAuthStateChange(_ notification: Notification) async {
        // Handle specific auth actions (business logic can be nonisolated)
        if let actionType = notification.userInfo?["actionType"] as? EcosiaAuthActionType {
            switch actionType {
            case .userLoggedIn:
                EcosiaLogger.accounts.info("User logged in - registering visit")
                syncAuthState()
                // `accountOrigin` is only set for a real interactive login/signup, not for the
                // silent credential resume this same notification also fires on at cold launch -
                // only a real new login should discard a guest's local snapshot.
                let authState = notification.userInfo?["authState"] as? AuthWindowState
                if authState?.accountOrigin != nil {
                    discardGuestImpactSnapshot()
                }
                await handleNewSeeds()
            case .userLoggedOut:
                EcosiaLogger.accounts.info("User logged out - resetting to local seed collection")
                syncAuthState()
                await resetToLocalSeedCollection()
                await handleNewSeeds()
            case .authStateLoaded:
                syncAuthState()
            }
        }
    }

    /// Clears the shared cache on a fresh login, so a guest's own local snapshot is never read
    /// back as the new session's real balance, and reflects the resulting zeroed state right away.
    @MainActor
    private func discardGuestImpactSnapshot() {
        impactManager.reset()
        let snapshot = impactManager.loadSeeds(isLoggedIn: isLoggedIn, userId: userProfile?.sub)
        seedCount = snapshot.seedCount
        currentLevelNumber = snapshot.currentLevelNumber
        currentProgress = snapshot.currentProgress
    }

    /// Refreshes `isLoggedIn`/`userProfile` (and the properties derived from it) from
    /// `EcosiaAuthenticationService.shared`.
    @MainActor
    private func syncAuthState() {
        isLoggedIn = EcosiaAuthenticationService.shared.isLoggedIn
        userProfile = EcosiaAuthenticationService.shared.userProfile
        username = userProfile?.name
        avatarURL = normalizedAvatarURL
    }

    @MainActor
    private func handleUserProfileUpdate() {
        let hadUserId = isLoggedIn && userProfile?.sub != nil
        syncAuthState()
        let hasUserId = isLoggedIn && userProfile?.sub != nil

        // The profile (and so the user id) can arrive after `.userLoggedIn` already tried and
        // skipped a registerVisit for lack of one - retry now that it's known.
        if hasUserId && !hadUserId {
            Task { await handleNewSeeds() }
        }
    }

    // MARK: - Seed Count Management

    /// Fetches new seeds regardless of login state and applies whatever came back.
    /// `ImpactManager.updateSeeds` owns both mechanisms - a logged-in registerVisit call and a
    /// logged-out local daily collection - and persists the result itself; this only reacts.
    private func handleNewSeeds() async {
        let result = await impactManager.updateSeeds(
            isLoggedIn: isLoggedIn,
            userId: userProfile?.sub,
            accessToken: EcosiaAuthenticationService.shared.accessToken,
            accountsProvider: accountsProvider
        )

        switch result {
        case .updated(let snapshot, let didLevelUp, let seedsIncrement):
            apply(snapshot: snapshot, didLevelUp: didLevelUp, seedsIncrement: seedsIncrement)
            hasRegisterVisitError = false

        case .registerVisitSkipped:
            break

        case .registerVisitFailed:
            hasRegisterVisitError = true
            if #available(iOS 16.0, *) {
                EcosiaErrorToastPresenter.shared.presentRegisterVisitError()
            }
        }
    }

    /// Applies a new snapshot to published state and animates it as needed. Shared by
    /// `handleNewSeeds()` (a real result, logged-in or logged-out) and `debugUpdateBalance(_:)`
    /// (a synthetic logged-in one), so all three go through the same level-up/animation decisions.
    @MainActor
    private func apply(snapshot: ImpactSnapshot, didLevelUp: Bool, seedsIncrement: Int?) {
        currentLevelNumber = snapshot.currentLevelNumber
        currentProgress = snapshot.currentProgress

        if didLevelUp {
            EcosiaLogger.accounts.info("Level up detected: triggering animation for level \(snapshot.currentLevelNumber)")
            triggerLevelUpAnimation()
        }

        if let increment = seedsIncrement {
            EcosiaLogger.accounts.info("Balance updated with animation: \(seedCount) → \(snapshot.seedCount) (+\(increment)), level=\(snapshot.currentLevelNumber), progress=\(snapshot.currentProgress)")
            animateBalanceChange(from: seedCount, to: snapshot.seedCount, increment: increment)
        } else {
            EcosiaLogger.accounts.info("Balance updated without animation: \(seedCount) → \(snapshot.seedCount), level=\(snapshot.currentLevelNumber), progress=\(snapshot.currentProgress)")
            seedCount = snapshot.seedCount
        }
    }

    @MainActor
    private func animateBalanceChange(from oldValue: Int, to newValue: Int, increment: Int) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.balanceIncrement = increment

            withAnimation(.easeIn(duration: 0.3)) {
                self.seedCount = newValue
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                withAnimation(.linear(duration: 0.57)) {
                    self.balanceIncrement = nil
                }
            }
        }
    }

    @MainActor
    private func triggerLevelUpAnimation() {
        EcosiaAccountNotificationCenter.postLevelUp(
            newLevel: currentLevelNumber,
            newProgress: currentProgress
        )
    }

    /// Resets to local seed collection system after logout.
    ///
    /// Clears the entire cache and lastAppOpenDate, then reloads (which fills the now-empty
    /// cache with a fresh 0 seeds/level 1 default) to seed published state.
    @MainActor
    private func resetToLocalSeedCollection() {
        EcosiaLogger.accounts.info("Resetting to local seed collection system")

        impactManager.reset()
        let snapshot = impactManager.loadSeeds(isLoggedIn: false, userId: nil)
        seedCount = snapshot.seedCount
        currentLevelNumber = snapshot.currentLevelNumber
        currentProgress = snapshot.currentProgress
    }

    // MARK: - Public Methods

    /// Refreshes seed state based on authentication status.
    ///
    /// Should be called when the NTP appears or app returns from background.
    /// - For logged-in users: Registers a visit to fetch latest balance from server
    /// - For logged-out users: Checks and collects daily seed
    @MainActor
    public func refreshSeedState() {
        Task {
            await handleNewSeeds()
        }
    }

    // MARK: - Debug Methods

    /// Debug method to simulate balance updates for testing animations
    /// This allows QA to test seed addition and level-up animations without server calls
    /// Available in all builds, accessible through hidden debug menu
    @MainActor
    public func debugUpdateBalance(_ response: AccountVisitResponse) {
        let snapshot = impactManager.debugUpdateBalance(response, isLoggedIn: isLoggedIn, userId: userProfile?.sub)
        apply(snapshot: snapshot, didLevelUp: response.didLevelUp, seedsIncrement: response.seedsIncrement)
        EcosiaLogger.accounts.info("Debug: Balance updated via debug method")
    }

    /// Debug method to directly trigger level-up animation without mock data
    /// This allows QA to test the level-up sparkle animation independently
    /// Available in all builds, accessible through hidden debug menu
    @MainActor
    public func debugTriggerLevelUpAnimation() {
        triggerLevelUpAnimation()
        EcosiaLogger.accounts.info("Debug: Level-up animation triggered directly")
    }

    /// Debug method to directly add seeds with animation for logged-in users
    /// This allows QA to test seed increment animations without mock responses
    /// Available in all builds, accessible through hidden debug menu
    @MainActor
    public func debugAddSeeds(_ count: Int) {
        let currentSeeds = seedCount
        let newSeeds = currentSeeds + count
        animateBalanceChange(from: currentSeeds, to: newSeeds, increment: count)
        EcosiaLogger.accounts.info("Debug: Added \(count) seeds for logged-in user (\(currentSeeds) → \(newSeeds))")
    }

    /// Debug method to force-add a real, persisted seed for logged-out users, bypassing the
    /// once-per-day gate, so QA can rapid-test the local seed cap/animation
    /// Available in all builds, accessible through hidden debug menu
    @MainActor
    public func debugAddLoggedOutSeed() {
        let (snapshot, increment) = impactManager.debugAddLoggedOutSeeds(1)
        apply(snapshot: snapshot, didLevelUp: false, seedsIncrement: increment > 0 ? increment : nil)
        EcosiaLogger.accounts.info("Debug: Added 1 seed for logged-out user")
    }
}
