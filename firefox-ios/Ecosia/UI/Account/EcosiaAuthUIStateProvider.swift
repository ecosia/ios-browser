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
    /// Placeholder only: `init` always overwrites this synchronously via `resolveInitialImpactSnapshot`
    /// before the object is observable.
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
    private var seedProgressObserver: NSObjectProtocol?
    /// Mirrors `EcosiaAuthenticationService.hasResolvedAuthState`: whether `isLoggedIn` is a
    /// confirmed value yet, or still the initial default from before the stored-credentials
    /// check on launch completes.
    private var hasResolvedAuthState = false
    /// Set when `refreshSeedState()` is called before auth state has resolved, so the call isn't
    /// answered with a guess; replayed once `handleAuthStateChange` confirms the real value.
    private var pendingSeedStateRefresh = false
    private let accountsProvider: AccountsProviderProtocol
    private let authState: EcosiaAuthStateReading
    /// Set while an explicit login/sign-up is running. `userLoggedIn` lands as soon as native
    /// Auth0 auth completes, so without this a refresh during the web session transfer would
    /// take the logged-in branch and register the visit before that transfer established it.
    private var isAuthenticationInFlight = false
    /// Normalizing the avatar to match Web's Product behaviour.
    /// Our Auth Provider (Auth0) sends us a Gravatar URL when no profile image is retrieved from a user
    /// (e.g. Apple Sign In). As of now, we replace it with our tree-image in `EcosiaAvatar` by not setting any URL
    private var normalizedAvatarURL: URL? {
        guard userProfile?.pictureURL?.baseDomain != gravatarURL?.baseDomain else { return nil }
        return userProfile?.pictureURL
    }
    nonisolated(unsafe) private static var seedProgressManagerType: SeedProgressManagerProtocol.Type = UserDefaultsSeedProgressManager.self
    /// Not `private`: swapped for a mock from tests via `@testable import`.
    nonisolated(unsafe) static var loggedInImpactCacheType: LoggedInImpactCacheProtocol.Type = LoggedInImpactCache.self

    // MARK: - Singleton

    /// Factory for creating accounts provider - can be configured before first access
    nonisolated(unsafe) public static var accountsProviderFactory: () -> AccountsProviderProtocol = { AccountsProvider() }

    /// Shared instance for app-wide auth state
    nonisolated(unsafe) public static let shared: EcosiaAuthUIStateProvider = {
        MainActor.assumeIsolated {
            EcosiaAuthUIStateProvider(accountsProvider: accountsProviderFactory())
        }
    }()

    public init(accountsProvider: AccountsProviderProtocol,
                authState: EcosiaAuthStateReading = EcosiaAuthenticationService.shared) {
        self.accountsProvider = accountsProvider
        self.authState = authState

        // Observers must be registered before the synchronous reads below: EcosiaAuthenticationService
        // resolves on its own Task, so it could otherwise finish and post its notification in the gap
        // between reading its state here and registering to hear about later updates - permanently
        // missing that one notification and leaving hasResolvedAuthState stuck false.
        setupAuthStateMonitoring()

        // Initialize state synchronously to prevent flickering
        self.isLoggedIn = authState.isLoggedIn
        self.hasResolvedAuthState = authState.hasResolvedAuthState
        self.userProfile = authState.userProfile
        self.avatarURL = normalizedAvatarURL
        self.username = userProfile?.name

        // Seed real state synchronously so the UI never flashes a placeholder
        // `registerVisitIfNeeded()`, triggered separately, fills that in shortly after.
        if let snapshot = Self.resolveInitialImpactSnapshot(isLoggedIn: isLoggedIn) {
            seedCount = snapshot.seedCount
            currentLevelNumber = snapshot.currentLevelNumber
            currentProgress = snapshot.currentProgress
        }
    }

    /// Reads the logged-in cache unconditionally first, since `isLoggedIn` can still be resolving
    /// (async keychain check) when this runs - only once that read misses do we fall back
    /// to branching on `isLoggedIn` for the logged-out local snapshot.
    static func resolveInitialImpactSnapshot(isLoggedIn: Bool) -> ImpactSnapshot? {
        if let cached = loggedInImpactCacheType.load() {
            return cached
        }
        guard isLoggedIn else {
            return ImpactSnapshot(
                seedCount: seedProgressManagerType.loadTotalSeedsCollected(),
                currentLevelNumber: seedProgressManagerType.loadCurrentLevel(),
                currentProgress: Double(seedProgressManagerType.calculateInnerProgress())
            )
        }
        return nil
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
        isLoggedIn = authState.isLoggedIn
        hasResolvedAuthState = true

        // Handle specific auth actions (business logic can be nonisolated)
        if let actionType = notification.userInfo?["actionType"] as? EcosiaAuthActionType {
            switch actionType {
            case .userLoggedIn:
                // Credential restoration on launch dispatches this too, so it can't stand in for
                // an actual sign-in - `handleSuccessfulAuthentication()` covers that.
                break
            case .userLoggedOut:
                pendingSeedStateRefresh = false
                EcosiaLogger.accounts.info("User logged out - resetting to local seed collection")
                await resetToLocalSeedCollection()
                await handleLocalSeedCollection()
            case .authStateLoaded:
                if !isLoggedIn, let snapshot = Self.resolveInitialImpactSnapshot(isLoggedIn: false) {
                    // EcosiaAuthenticationService already clears the shared logged-in cache
                    // whenever this resolves to logged-out following a logged-in session (e.g.
                    // an expired token) - re-resolve here to move off whatever this object showed
                    // at init (possibly that now-stale cache) onto the current local snapshot.
                    // A no-op for an ordinary continuing guest, who was already showing this.
                    seedCount = snapshot.seedCount
                    currentLevelNumber = snapshot.currentLevelNumber
                    currentProgress = snapshot.currentProgress
                }

                // `dispatchAuthState` posts this once per registered browser window, so consuming
                // the pending refresh is also what keeps multi-window launches to a single visit.
                guard pendingSeedStateRefresh else { break }
                pendingSeedStateRefresh = false
                refreshSeedState()
            }
        }
    }

    @MainActor
    private func handleUserProfileUpdate() {
        Task { @MainActor in
            isLoggedIn = authState.isLoggedIn
        }
        userProfile = authState.userProfile
        username = userProfile?.name
        avatarURL = normalizedAvatarURL
    }

    @MainActor
    private func handleSeedProgressUpdate() {
        // Only handle for logged-out users
        guard !isLoggedIn else { return }

        let newSeedCount = Self.seedProgressManagerType.loadTotalSeedsCollected()

        // If seed count increased, show animation
        if newSeedCount > seedCount {
            let increment = newSeedCount - seedCount
            EcosiaLogger.accounts.info("Seed progress updated for logged-out user: \(seedCount) → \(newSeedCount) (+\(increment))")
            animateBalanceChange(from: seedCount, to: newSeedCount, increment: increment)
        } else {
            seedCount = newSeedCount
        }
    }

    // MARK: - Seed Count Management

    /// Registers a user visit to fetch the latest balance from the backend.
    ///
    /// Only proceeds if a valid access token is available (user is logged in).
    /// Updates the balance and level information on success.
    /// Sets `hasRegisterVisitError` to `true` on failure.
    private func registerVisitIfNeeded() {
        Task {
            do {
                guard let accessToken = authState.accessToken, !accessToken.isEmpty else {
                    EcosiaLogger.accounts.notice("Cannot register visit - no access token available")
                    return
                }

                EcosiaLogger.accounts.info("Registering user visit for balance update")
                let response = try await accountsProvider.registerVisit(accessToken: accessToken)

                // The token can change (logout, or a different account logging in) while this
                // request is in flight; applying a response addressed to that earlier session
                // would store its balance under whichever account is current when it lands.
                guard authState.accessToken == accessToken else {
                    EcosiaLogger.accounts.notice("Discarding register visit response - session changed while in flight")
                    return
                }

                await updateBalance(response)

                // Clear error on success
                await MainActor.run {
                    hasRegisterVisitError = false
                }
            } catch {
                EcosiaLogger.accounts.debug("Could not register visit: \(error.localizedDescription)")

                // Set error state
                await MainActor.run {
                    hasRegisterVisitError = true
                    if #available(iOS 16.0, *) {
                        EcosiaErrorToastPresenter.shared.presentRegisterVisitError()
                    }
                }
            }
        }
    }

    @MainActor
    private func updateBalance(_ response: AccountVisitResponse) {
        let newSeedCount = response.seeds.balanceAmount
        let newLevelNumber = response.growthPoints.level.number
        let newProgress = response.progressToNextLevel

        // Update level and progress from API
        currentLevelNumber = newLevelNumber
        currentProgress = newProgress

        persistLoggedInImpactSnapshot(seedCount: newSeedCount, currentLevelNumber: newLevelNumber, currentProgress: newProgress)

        // Trigger level-up animation if user leveled up
        if response.didLevelUp {
            EcosiaLogger.accounts.info("Level up detected: triggering animation for level \(newLevelNumber)")
            triggerLevelUpAnimation()
        }

        if let increment = response.seedsIncrement {
            EcosiaLogger.accounts.info("Balance updated with animation: \(seedCount) → \(newSeedCount) (+\(increment)), level=\(newLevelNumber), progress=\(newProgress)")
            animateBalanceChange(from: seedCount, to: newSeedCount, increment: increment)
        } else {
            EcosiaLogger.accounts.info("Balance updated without animation: \(seedCount) → \(newSeedCount), level=\(newLevelNumber), progress=\(newProgress)")
            seedCount = newSeedCount
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

    /// Writes through to `loggedInImpactCacheType` so a cold launch (or a resume before the next
    /// server refresh completes) can seed from these values next time, instead of flashing the
    /// logged-out cap.
    private func persistLoggedInImpactSnapshot(seedCount: Int, currentLevelNumber: Int, currentProgress: Double) {
        guard isLoggedIn else { return }
        Self.loggedInImpactCacheType.save(
            ImpactSnapshot(seedCount: seedCount, currentLevelNumber: currentLevelNumber, currentProgress: currentProgress)
        )
    }

    /// Resets to local seed collection system after logout.
    ///
    /// Resets seeds to 0, level to 1, and clears lastAppOpenDate to allow immediate seed collection.
    @MainActor
    private func resetToLocalSeedCollection() {
        EcosiaLogger.accounts.info("Resetting to local seed collection system")

        // The local manager re-arms collection from zero, the logged-in cache drops
        // the stale server snapshot - so a later login by a different account doesn't
        // briefly show this account's numbers either way.
        Self.seedProgressManagerType.resetLocalSeedProgress()
        Self.loggedInImpactCacheType.clear()

        seedCount = Self.seedProgressManagerType.loadTotalSeedsCollected()
        currentLevelNumber = 1
        currentProgress = 0.25
    }

    /// Handles daily seed collection for logged-out users.
    ///
    /// Collects one seed per day and animates the increment if a new seed was collected.
    @MainActor
    private func handleLocalSeedCollection() {
        EcosiaLogger.accounts.info("Handling local seed collection for logged-out user")
        Self.seedProgressManagerType.collectDailySeed()
        let newSeedCount = Self.seedProgressManagerType.loadTotalSeedsCollected()

        if newSeedCount > seedCount {
            let increment = newSeedCount - seedCount
            animateBalanceChange(from: seedCount, to: newSeedCount, increment: increment)
        } else {
            seedCount = newSeedCount
        }
    }

    // MARK: - Public Methods

    /// Brackets an explicit login/sign-up so refresh-driven visits wait for it to finish.
    ///
    /// The caller clears this on every exit - success, failure and cancellation - so a flow that
    /// ends without reaching `handleSuccessfulAuthentication()` can't strand refreshes.
    @MainActor
    public func setAuthenticationInFlight(_ inFlight: Bool) {
        isAuthenticationInFlight = inFlight
    }

    /// Registers the visit for a login or sign-up that has just completed end to end.
    ///
    /// Driven explicitly by the auth flow rather than by `.EcosiaAuthStateChanged`, whose
    /// `userLoggedIn` action is also dispatched by credential restoration on launch.
    @MainActor
    public func handleSuccessfulAuthentication() {
        // This call answers whatever refresh was still waiting on auth state to resolve.
        pendingSeedStateRefresh = false
        EcosiaLogger.accounts.info("Authentication completed - registering visit")
        registerVisitIfNeeded()
    }

    /// Refreshes seed state based on authentication status.
    ///
    /// Should be called when the NTP appears or app returns from background.
    /// - For logged-in users: Registers a visit to fetch latest balance from server
    /// - For logged-out users: Checks and collects daily seed
    @MainActor
    public func refreshSeedState() {
        if !hasResolvedAuthState {
            // Re-sync directly from the service rather than trusting this mirror alone: its
            // resolution notification only reaches registered browser windows, so it can resolve
            // without ever notifying this provider (e.g. none were registered yet) - leaving
            // hasResolvedAuthState stuck false forever and every future call deferring for nothing.
            isLoggedIn = authState.isLoggedIn
            hasResolvedAuthState = authState.hasResolvedAuthState
        }

        // isLoggedIn can still be the initial default here (auth resolution runs
        // asynchronously from launch), so branching on it now could wrongly treat
        // a logged-in user as a guest. Wait for a confirmed value instead of guessing;
        // handleAuthStateChange replays this call.
        guard hasResolvedAuthState else {
            EcosiaLogger.accounts.debug("Deferring seed state refresh until auth state resolves")
            pendingSeedStateRefresh = true
            return
        }

        if isLoggedIn {
            guard !isAuthenticationInFlight else {
                EcosiaLogger.accounts.debug("Deferring seed state refresh until authentication completes")
                return
            }
            EcosiaLogger.accounts.debug("Refreshing seed state for logged-in user (server fetch)")
            registerVisitIfNeeded()
        } else {
            EcosiaLogger.accounts.debug("Refreshing seed state for logged-out user (daily seed check)")
            handleLocalSeedCollection()
        }
    }

    // MARK: - Debug Methods

    /// Debug method to simulate balance updates for testing animations
    /// This allows QA to test seed addition and level-up animations without server calls
    /// Available in all builds, accessible through hidden debug menu
    @MainActor
    public func debugUpdateBalance(_ response: AccountVisitResponse) {
        updateBalance(response)
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
}
