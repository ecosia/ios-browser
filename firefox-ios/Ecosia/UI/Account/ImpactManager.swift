// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@preconcurrency import Foundation
import SwiftUI
import Combine
import Common

/// Owns seed/level/progress state regardless of login state, so callers never need to know
/// whether a number came from the server (logged-in) or local collection (logged-out) - they
/// just observe `seedCount`/`currentLevelNumber`/`currentProgress` and call `refreshSeedState()`.
///
/// Reads `isLoggedIn`/the current user id straight from `authService` every time rather than
/// caching a local copy kept in sync via notifications - `EcosiaAuthenticationService` is already
/// the single source of truth and safe to read synchronously at any point, so a cached copy would
/// just be a second thing that could drift from it. Listens to `.EcosiaAuthStateChanged` only to
/// trigger the login/logout side effects (register a visit, reset local collection), not to track
/// state itself - no dependency on `EcosiaAuthUIStateProvider` at all, the two are siblings.
@MainActor
public final class ImpactManager: ObservableObject {

    // MARK: - Published Properties

    /// Current seed count (server-based for logged in users, local for guests)
    @Published public private(set) var seedCount: Int = 0

    /// Current level number (from API for logged-in users, 1 for logged-out)
    @Published public private(set) var currentLevelNumber: Int = 1

    /// Current progress towards next level (from API for logged-in users, default 0.25 for initial state)
    @Published public private(set) var currentProgress: Double = 0.25

    /// Error state for register visit failures (read-only externally, set only by this class)
    @Published public private(set) var hasRegisterVisitError: Bool = false

    /// Balance increment for animations (temporary state)
    @Published public private(set) var balanceIncrement: Int?

    // MARK: - Private Properties

    private var isLoggedIn: Bool { authService.isLoggedIn }
    private var userId: String? { authService.userProfile?.sub }

    private var authStateObserver: NSObjectProtocol?
    private var seedProgressObserver: NSObjectProtocol?
    private let accountsProvider: AccountsProviderProtocol
    private let authService: EcosiaAuthenticationService

    /// Not `private`: swapped for a mock from tests via `@testable import`.
    nonisolated(unsafe) static var loggedOutImpactCacheType: SeedProgressManagerProtocol.Type = UserDefaultsSeedProgressManager.self
    /// Not `private`: swapped for a mock from tests via `@testable import`.
    nonisolated(unsafe) static var loggedInImpactCacheType: LoggedInImpactCacheProtocol.Type = UserDefaultsLoggedInImpactCache.self

    // MARK: - Singleton

    /// Factory for creating accounts provider - can be configured before first access
    nonisolated(unsafe) public static var accountsProviderFactory: () -> AccountsProviderProtocol = { AccountsProvider() }

    /// Shared instance for app-wide impact state
    nonisolated(unsafe) public static let shared: ImpactManager = {
        MainActor.assumeIsolated {
            ImpactManager(accountsProvider: accountsProviderFactory())
        }
    }()

    public init(accountsProvider: AccountsProviderProtocol, authService: EcosiaAuthenticationService = .shared) {
        self.accountsProvider = accountsProvider
        self.authService = authService

        // Seed real state synchronously: logged-out reads the local snapshot, logged-in reads
        // the last known server snapshot from cache (falls through to the placeholder above only
        // on a first-ever login with nothing cached yet - registerVisitIfNeeded(), triggered
        // separately, fills that in shortly after).
        if let snapshot = Self.resolveInitialImpactSnapshot(isLoggedIn: isLoggedIn, userId: userId) {
            seedCount = snapshot.seedCount
            currentLevelNumber = snapshot.currentLevelNumber
            currentProgress = snapshot.currentProgress
        }

        setupObservers()
    }

    deinit {
        MainActor.assumeIsolated {
            [authStateObserver, seedProgressObserver].forEach {
                if let observer = $0 {
                    NotificationCenter.default.removeObserver(observer)
                }
            }
        }
    }

    /// Resolves the snapshot to seed `init`'s state with. One polymorphic call through
    /// `ImpactSnapshotReadable` - which store answers it depends only on login state, the call
    /// shape is identical either way. Pulled out as a pure static function (rather than inlined
    /// in `init`) so it can be unit tested directly against a mock `loggedInImpactCacheType`,
    /// independent of the live `EcosiaAuthenticationService.shared` state `init` otherwise reads from.
    static func resolveInitialImpactSnapshot(isLoggedIn: Bool, userId: String?) -> ImpactSnapshot? {
        let cacheType: ImpactSnapshotReadable.Type = isLoggedIn ? loggedInImpactCacheType : loggedOutImpactCacheType
        return cacheType.currentSnapshot(forUserId: userId)
    }

    // MARK: - Public Interface

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

    private func setupObservers() {
        // Listen for auth state changes - only to trigger the login/logout side effects below,
        // isLoggedIn/userId are read live from authService rather than cached from this.
        authStateObserver = NotificationCenter.default.addObserver(
            forName: .EcosiaAuthStateChanged,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            Task { [notification] in
                await self?.handleAuthStateChange(notification)
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

    private func handleAuthStateChange(_ notification: Notification) async {
        guard let actionType = notification.userInfo?["actionType"] as? EcosiaAuthActionType else { return }
        switch actionType {
        case .userLoggedIn:
            EcosiaLogger.accounts.info("User logged in - registering visit")
            registerVisitIfNeeded()
        case .userLoggedOut:
            EcosiaLogger.accounts.info("User logged out - resetting to local seed collection")
            await resetToLocalSeedCollection()
            await handleLocalSeedCollection()
        case .authStateLoaded:
            break // isLoggedIn/userId are read live, nothing to refresh here
        }
    }

    @MainActor
    private func handleSeedProgressUpdate() {
        // Only handle for logged-out users
        guard !isLoggedIn else { return }

        let newSeedCount = Self.loggedOutImpactCacheType.loadTotalSeedsCollected()

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
                guard let accessToken = authService.accessToken, !accessToken.isEmpty else {
                    EcosiaLogger.accounts.notice("Cannot register visit - no access token available")
                    return
                }

                EcosiaLogger.accounts.info("Registering user visit for balance update")
                let response = try await accountsProvider.registerVisit(accessToken: accessToken)
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

    /// Writes through to `loggedInImpactCacheType` so a cold launch (or the profile screen) can
    /// seed from these values next time, instead of flashing the logged-out cap.
    private func persistLoggedInImpactSnapshot(seedCount: Int, currentLevelNumber: Int, currentProgress: Double) {
        guard isLoggedIn, let userId else { return }
        Self.loggedInImpactCacheType.save(
            ImpactSnapshot(seedCount: seedCount, currentLevelNumber: currentLevelNumber, currentProgress: currentProgress),
            userId: userId
        )
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
    /// Resets seeds to 0, level to 1, and clears lastAppOpenDate to allow immediate seed collection.
    @MainActor
    private func resetToLocalSeedCollection() {
        EcosiaLogger.accounts.info("Resetting to local seed collection system")

        // Same vocabulary on both stores: the local manager re-arms collection from zero, the
        // logged-in cache drops the stale server snapshot - so a later login by a different
        // account doesn't briefly show this account's numbers either way.
        Self.loggedOutImpactCacheType.clearOnLogout()
        Self.loggedInImpactCacheType.clearOnLogout()

        seedCount = Self.loggedOutImpactCacheType.loadTotalSeedsCollected()
        currentLevelNumber = 1
        currentProgress = 0.25
    }

    /// Handles daily seed collection for logged-out users.
    ///
    /// Collects one seed per day and animates the increment if a new seed was collected.
    @MainActor
    private func handleLocalSeedCollection() {
        EcosiaLogger.accounts.info("Handling local seed collection for logged-out user")
        Self.loggedOutImpactCacheType.collectDailySeed()
        let newSeedCount = Self.loggedOutImpactCacheType.loadTotalSeedsCollected()

        if newSeedCount > seedCount {
            let increment = newSeedCount - seedCount
            animateBalanceChange(from: seedCount, to: newSeedCount, increment: increment)
        } else {
            seedCount = newSeedCount
        }
    }

    // MARK: - Public Methods

    /// Refreshes seed state based on authentication status. Called every time regardless of
    /// login state - callers don't branch on `isLoggedIn` themselves, this does it internally.
    ///
    /// Should be called when the NTP appears or app returns from background.
    /// - For logged-in users: Registers a visit to fetch latest balance from server
    /// - For logged-out users: Checks and collects daily seed
    @MainActor
    public func refreshSeedState() {
        if isLoggedIn {
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
