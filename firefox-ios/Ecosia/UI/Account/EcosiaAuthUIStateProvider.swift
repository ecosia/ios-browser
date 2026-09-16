// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@preconcurrency import Foundation
import SwiftUI
import Combine
import Common

/// Centralized, reactive authentication state provider for consistent UI state across all components
/// This eliminates the need for individual components to manage their own auth state observers
///
/// This is a thin `@Published` mirror of the shared impact cache: it doesn't fetch or persist
/// anything itself. `LoggedInImpactUpdater` and `LoggedOutSeedProgressManager` each own writing
/// their own side of `ImpactCacheProtocol` and post `.EcosiaImpactCacheUpdated` when they do; this
/// class just observes that notification and applies the result to published state/animations.
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
    private var impactCacheObserver: NSObjectProtocol?
    private var impactUpdateFailedObserver: NSObjectProtocol?

    private let accountsProvider: AccountsProviderProtocol
    private let authenticationService: EcosiaAuthenticationService
    private let loggedOutManager: LoggedOutSeedProgressManager
    private let loggedInUpdater: LoggedInImpactUpdater

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

    public init(
        accountsProvider: AccountsProviderProtocol,
        cache: ImpactCacheProtocol = ImpactCache(),
        authenticationService: EcosiaAuthenticationService = .shared
    ) {
        self.accountsProvider = accountsProvider
        self.authenticationService = authenticationService
        self.loggedOutManager = LoggedOutSeedProgressManager(cache: cache, authenticationService: authenticationService)
        self.loggedInUpdater = LoggedInImpactUpdater(cache: cache, accountsProvider: accountsProvider, authenticationService: authenticationService)

        // Initialize state synchronously to prevent flickering
        self.isLoggedIn = authenticationService.isLoggedIn
        self.userProfile = authenticationService.userProfile
        self.avatarURL = normalizedAvatarURL
        self.username = userProfile?.name

        // Seed real state synchronously so the UI never flashes a placeholder. `loggedInUpdater`
        // reacts to auth state on its own and will fetch/persist the real logged-in value shortly
        // after; for logged-out this already IS the real value.
        let snapshot = currentSnapshot()
        seedCount = snapshot.seedCount
        currentLevelNumber = snapshot.currentLevelNumber
        currentProgress = snapshot.currentProgress

        setupObservers()
    }

    deinit {
        MainActor.assumeIsolated {
            if let authStateObserver {
                NotificationCenter.default.removeObserver(authStateObserver)
            }
            if let userProfileObserver {
                NotificationCenter.default.removeObserver(userProfileObserver)
            }
            if let impactCacheObserver {
                NotificationCenter.default.removeObserver(impactCacheObserver)
            }
            if let impactUpdateFailedObserver {
                NotificationCenter.default.removeObserver(impactUpdateFailedObserver)
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

    private func currentSnapshot() -> ImpactSnapshot {
        if isLoggedIn, let userID = userProfile?.sub, let cached = loggedInUpdater.cachedSnapshot(for: userID) {
            return cached
        }

        // `isLoggedIn` always starts false on a cold launch, regardless of whether this device
        // actually has a session - it only flips once EcosiaAuthenticationService's async
        // credential retrieval resolves, moments after this initializer runs. If a session is
        // plausibly still stored (a refresh token exists locally - no network call) and the shared
        // cache still holds a logged-in snapshot from last time, show that as a same-frame best
        // guess instead of the guest's local count. The reactive flow (LoggedInImpactUpdater's
        // auto-fetch once login is confirmed, or the stale-guess correction in
        // handleAuthStateChange's `.authStateLoaded` case if it turns out we're not actually logged
        // in) corrects this within moments either way - this only avoids flashing the wrong
        // identity's balance on every single cold launch for a returning logged-in user.
        if authenticationService.hasStoredSession, let cachedLoggedIn = loggedInUpdater.anyLoggedInSnapshot() {
            return cachedLoggedIn
        }

        return loggedOutManager.load()
    }

    private func setupObservers() {
        // Auth state (login/logout/loaded) - just keeps published auth fields in sync. Fetching
        // and persisting the logged-in balance is `loggedInUpdater`'s own job; it observes the
        // same notification independently.
        authStateObserver = NotificationCenter.default.addObserver(
            forName: .EcosiaAuthStateChanged,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            Task { [notification] in
                await self?.handleAuthStateChange(notification)
            }
        }

        userProfileObserver = NotificationCenter.default.addObserver(
            forName: .EcosiaUserProfileUpdated,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task {
                await self?.syncAuthState()
            }
        }

        // The single reactive entry point for both logged-in and logged-out balance updates.
        impactCacheObserver = NotificationCenter.default.addObserver(
            forName: .EcosiaImpactCacheUpdated,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let snapshot = notification.userInfo?[ImpactCache.snapshotUserInfoKey] as? ImpactSnapshot else { return }
            let seedsIncrement = notification.userInfo?[ImpactCache.seedsIncrementUserInfoKey] as? Int
            let didLevelUp = notification.userInfo?[ImpactCache.didLevelUpUserInfoKey] as? Bool ?? false
            self?.apply(snapshot: snapshot, seedsIncrement: seedsIncrement, didLevelUp: didLevelUp)
        }

        impactUpdateFailedObserver = NotificationCenter.default.addObserver(
            forName: .EcosiaImpactUpdateFailed,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.hasRegisterVisitError = true
            if #available(iOS 16.0, *) {
                EcosiaErrorToastPresenter.shared.presentRegisterVisitError()
            }
        }
    }

    private func handleAuthStateChange(_ notification: Notification) async {
        guard let actionType = notification.userInfo?["actionType"] as? EcosiaAuthActionType else { return }
        switch actionType {
        case .userLoggedIn:
            EcosiaLogger.accounts.info("User logged in")
            syncAuthState()
        case .userLoggedOut:
            EcosiaLogger.accounts.info("User logged out - resetting to local seed collection")
            syncAuthState()
            // Cancel explicitly, before resetting the cache, rather than relying on
            // LoggedInImpactUpdater's own independent observer happening to run first - it does
            // today only because of construction order, which isn't a guarantee worth depending on.
            loggedInUpdater.cancelInFlight()
            loggedOutManager.reset()
            // reset() just cleared the last-app-open date, so this collects immediately - matches
            // "opening the app as a guest for the first time today" rather than leaving it at 0.
            loggedOutManager.collectDailySeedIfDue()
        case .authStateLoaded:
            syncAuthState()
            if !isLoggedIn, loggedInUpdater.anyLoggedInSnapshot() != nil {
                // The cold-launch credential check just confirmed we're NOT actually logged in,
                // but the shared cache is still tagged to a logged-in user - either this
                // provider's own optimistic guess in currentSnapshot() was wrong (a stored
                // session that turned out to be revoked/expired), or the cache was left stale by
                // a previous run that never went through a real logout. Only correct it in this
                // specific case - a guest cold launch reaches this same branch on every single
                // launch too, and must not have its local progress wiped every time.
                EcosiaLogger.accounts.info("Cold-launch check confirmed logged out - clearing a stale logged-in cache entry")
                loggedInUpdater.cancelInFlight()
                loggedOutManager.reset()
                loggedOutManager.collectDailySeedIfDue()
            }
        }
    }

    /// Refreshes `isLoggedIn`/`userProfile` (and the properties derived from it) from
    /// `authenticationService`.
    @MainActor
    private func syncAuthState() {
        isLoggedIn = authenticationService.isLoggedIn
        userProfile = authenticationService.userProfile
        username = userProfile?.name
        avatarURL = normalizedAvatarURL
    }

    // MARK: - Seed Count Management

    /// A snapshot is only relevant if it belongs to whoever is currently active - defense in depth
    /// alongside `LoggedInImpactUpdater`'s own identity check, in case a write and an auth
    /// transition ever race each other. Checked against `EcosiaAuthenticationService` directly,
    /// not `self.isLoggedIn`/`userProfile` - those are a `@Published` mirror that can lag the real
    /// auth state by one run-loop turn (see `syncAuthState()`), which is fine for what they render
    /// but not for a check that decides whether to accept a write.
    private func isRelevant(_ snapshot: ImpactSnapshot) -> Bool {
        authenticationService.isLoggedIn
            ? snapshot.loggedInUserID == authenticationService.userProfile?.sub
            : snapshot.loggedInUserID == nil
    }

    /// Applies a new snapshot to published state and animates it as needed. Shared by the real
    /// `.EcosiaImpactCacheUpdated` notification (logged-in or logged-out) and `debugUpdateBalance(_:)`
    /// (a synthetic logged-in one, via the same cache write), so all paths go through the same
    /// level-up/animation decisions.
    ///
    /// `seedsIncrement`/`didLevelUp` come from the writer, not from diffing `snapshot` against the
    /// currently displayed values: on a first login the account's real balance/level can differ
    /// wildly from the guest's local ones without anything having just been earned, so a diff-based
    /// check would misfire a celebratory animation for a value that was simply never shown before.
    @MainActor
    private func apply(snapshot: ImpactSnapshot, seedsIncrement: Int?, didLevelUp: Bool) {
        guard isRelevant(snapshot) else { return }

        hasRegisterVisitError = false
        currentLevelNumber = snapshot.currentLevelNumber
        currentProgress = snapshot.currentProgress

        if didLevelUp {
            EcosiaLogger.accounts.info("Level up detected: triggering animation for level \(snapshot.currentLevelNumber)")
            triggerLevelUpAnimation()
        }

        if let increment = seedsIncrement, increment > 0 {
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

    // MARK: - Public Methods

    /// Refreshes seed state based on authentication status.
    ///
    /// Should be called when the NTP appears or app returns from background.
    /// - For logged-in users: triggers `LoggedInImpactUpdater` to register a visit
    /// - For logged-out users: checks and collects the daily seed
    ///
    /// Checked against `EcosiaAuthenticationService` directly, not `self.isLoggedIn` - this can be
    /// called at any arbitrary moment unrelated to an auth transition (NTP appearing, foreground),
    /// and the published mirror can briefly lag the real value right after a transition.
    @MainActor
    public func refreshSeedState() {
        if authenticationService.isLoggedIn {
            EcosiaLogger.accounts.debug("Refreshing seed state for logged-in user (server fetch)")
            loggedInUpdater.refresh()
        } else {
            EcosiaLogger.accounts.debug("Refreshing seed state for logged-out user (daily seed check)")
            loggedOutManager.collectDailySeedIfDue()
        }
    }

    // MARK: - Debug Methods

    /// Debug method to simulate balance updates for testing animations
    /// This allows QA to test seed addition and level-up animations without server calls
    /// Available in all builds, accessible through hidden debug menu
    @MainActor
    public func debugUpdateBalance(_ response: AccountVisitResponse) {
        guard authenticationService.isLoggedIn, let userID = authenticationService.userProfile?.sub else { return }
        // Posts .EcosiaImpactCacheUpdated, applied synchronously via apply(snapshot:)
        loggedInUpdater.debugApply(response, userID: userID)
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
