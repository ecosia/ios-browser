// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@preconcurrency import Foundation
import SwiftUI
import Common

/// Owns the user's seed count, level and progress: server-based when logged in, local when logged out.
@MainActor
public final class ImpactManager: ObservableObject {

    // MARK: - Published Properties

    /// Placeholder only: `loadInitialSnapshot()` overwrites this before the object is observable.
    @Published public private(set) var seedCount: Int = 0

    /// Balance increment for animations (temporary state)
    @Published public private(set) var balanceIncrement: Int?

    @Published public private(set) var currentLevelNumber: Int = 1

    @Published public private(set) var currentProgress: Double = 0.25

    @Published public private(set) var hasRegisterVisitError: Bool = false

    // MARK: - Private Properties

    /// Set when `refreshSeedState()` is called before auth state has resolved, so the call isn't
    /// answered with a guess; replayed once `handleAuthStateLoaded()` confirms the real value.
    private var pendingSeedStateRefresh = false
    /// Guards against firing more than one initial `registerVisitIfNeeded()`/`handleLocalSeedCollection()`
    /// for a single resolution: cold launch can dispatch both `userLoggedIn` and `authStateLoaded`
    /// for the same "already logged in" event, in unspecified order, so whichever arrives first
    /// claims it and the other is a no-op. Reset on logout so a later login fires its own.
    private var hasHandledCurrentResolution = false
    private let accountsProvider: AccountsProviderProtocol
    private let auth: AuthSessionProviderProtocol
    nonisolated(unsafe) private static var seedProgressManagerType: SeedProgressManagerProtocol.Type = UserDefaultsSeedProgressManager.self
    /// Not `private`: swapped for a mock from tests via `@testable import`.
    nonisolated(unsafe) static var loggedInImpactCacheType: LoggedInImpactCacheProtocol.Type = LoggedInImpactCache.self

    // MARK: - Init

    public init(accountsProvider: AccountsProviderProtocol, auth: AuthSessionProviderProtocol = EcosiaAuthSessionProvider()) {
        self.accountsProvider = accountsProvider
        self.auth = auth
    }

    /// Seeds real state synchronously so the UI never flashes a placeholder;
    /// `registerVisitIfNeeded()`, triggered separately, fills in the server values shortly after.
    func loadInitialSnapshot() {
        if let snapshot = Self.resolveInitialImpactSnapshot(isLoggedIn: auth.isLoggedIn) {
            apply(snapshot)
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

    // MARK: - Auth Events

    func handleUserLoggedIn() {
        pendingSeedStateRefresh = false
        guard !hasHandledCurrentResolution else { return }
        hasHandledCurrentResolution = true
        EcosiaLogger.accounts.info("User logged in - registering visit")
        registerVisitIfNeeded()
    }

    func handleUserLoggedOut() {
        hasHandledCurrentResolution = false
        pendingSeedStateRefresh = false
        EcosiaLogger.accounts.info("User logged out - resetting to local seed collection")
        resetToLocalSeedCollection()
        handleLocalSeedCollection()
    }

    func handleAuthStateLoaded() {
        if !auth.isLoggedIn, let snapshot = Self.resolveInitialImpactSnapshot(isLoggedIn: false) {
            // EcosiaAuthenticationService already clears the shared logged-in cache
            // whenever this resolves to logged-out following a logged-in session (e.g.
            // an expired token) - re-resolve here to move off whatever this object showed
            // at init (possibly that now-stale cache) onto the current local snapshot.
            // A no-op for an ordinary continuing guest, who was already showing this.
            apply(snapshot)
        }

        // Cold launch can dispatch both userLoggedIn and authStateLoaded for the same
        // "already logged in" event, in unspecified order - hasHandledCurrentResolution
        // makes sure only whichever arrives first triggers the refresh.
        guard pendingSeedStateRefresh, !hasHandledCurrentResolution else { return }
        pendingSeedStateRefresh = false
        hasHandledCurrentResolution = true
        refreshSeedState()
    }

    func handleSeedProgressUpdate() {
        // Only handle for logged-out users
        guard !auth.isLoggedIn else { return }

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

    /// Refreshes seed state based on authentication status.
    ///
    /// Should be called when the NTP appears or app returns from background.
    /// - For logged-in users: Registers a visit to fetch latest balance from server
    /// - For logged-out users: Checks and collects daily seed
    public func refreshSeedState() {
        // isLoggedIn can still be the initial default here (auth resolution runs
        // asynchronously from launch), so branching on it now could wrongly treat
        // a logged-in user as a guest. Wait for a confirmed value instead of guessing;
        // handleAuthStateLoaded replays this call.
        guard auth.hasResolvedAuthState else {
            EcosiaLogger.accounts.debug("Deferring seed state refresh until auth state resolves")
            pendingSeedStateRefresh = true
            return
        }

        if auth.isLoggedIn {
            EcosiaLogger.accounts.debug("Refreshing seed state for logged-in user (server fetch)")
            registerVisitIfNeeded()
        } else {
            EcosiaLogger.accounts.debug("Refreshing seed state for logged-out user (daily seed check)")
            handleLocalSeedCollection()
        }
    }

    /// Registers a user visit to fetch the latest balance from the backend.
    ///
    /// Only proceeds if a valid access token is available (user is logged in).
    /// Updates the balance and level information on success.
    /// Sets `hasRegisterVisitError` to `true` on failure.
    private func registerVisitIfNeeded() {
        Task {
            do {
                guard let accessToken = auth.accessToken, !accessToken.isEmpty else {
                    EcosiaLogger.accounts.notice("Cannot register visit - no access token available")
                    return
                }

                EcosiaLogger.accounts.info("Registering user visit for balance update")
                let response = try await accountsProvider.registerVisit(accessToken: accessToken)

                // The token can change (logout, or a different account logging in) while this
                // request is in flight; applying a response addressed to that earlier session
                // would store its balance under whichever account is current when it lands.
                guard auth.accessToken == accessToken else {
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

    private func apply(_ snapshot: ImpactSnapshot) {
        seedCount = snapshot.seedCount
        currentLevelNumber = snapshot.currentLevelNumber
        currentProgress = snapshot.currentProgress
    }

    /// Writes through to `loggedInImpactCacheType` so a cold launch (or a resume before the next
    /// server refresh completes) can seed from these values next time, instead of flashing the
    /// logged-out cap.
    private func persistLoggedInImpactSnapshot(seedCount: Int, currentLevelNumber: Int, currentProgress: Double) {
        guard auth.isLoggedIn else { return }
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
