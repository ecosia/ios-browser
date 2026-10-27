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

    /// Updated on auth events rather than read live, so a refresh can't run ahead of the login/logout handlers.
    private var isLoggedIn = false
    /// Whether `isLoggedIn` is confirmed, or still the default from before the launch credentials check.
    private var hasResolvedAuthState = false
    /// Set when `refreshSeedState()` runs before auth resolves; replayed on `authStateLoaded`.
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

    /// Must run after the auth observers are registered, so a resolution can't land unheard in between.
    func loadInitialSnapshot() {
        isLoggedIn = auth.isLoggedIn
        hasResolvedAuthState = auth.hasResolvedAuthState
        if let snapshot = Self.resolveInitialImpactSnapshot(isLoggedIn: isLoggedIn) {
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

    func handleAuthStateChange(actionType: EcosiaAuthActionType?) {
        // Every auth notification means the service's isLoggedIn is now confirmed.
        isLoggedIn = auth.isLoggedIn
        hasResolvedAuthState = true

        switch actionType {
        case .userLoggedIn:
            handleUserLoggedIn()
        case .userLoggedOut:
            handleUserLoggedOut()
        case .authStateLoaded:
            handleAuthStateLoaded()
        case nil:
            break
        }
    }

    func refreshLoggedInState() {
        isLoggedIn = auth.isLoggedIn
    }

    private func handleUserLoggedIn() {
        pendingSeedStateRefresh = false
        guard !hasHandledCurrentResolution else { return }
        hasHandledCurrentResolution = true
        EcosiaLogger.accounts.info("User logged in - registering visit")
        registerVisitIfNeeded()
    }

    private func handleUserLoggedOut() {
        hasHandledCurrentResolution = false
        pendingSeedStateRefresh = false
        EcosiaLogger.accounts.info("User logged out - resetting to local seed collection")
        resetToLocalSeedCollection()
        handleLocalSeedCollection()
    }

    private func handleAuthStateLoaded() {
        if !isLoggedIn, let snapshot = Self.resolveInitialImpactSnapshot(isLoggedIn: false) {
            // EcosiaAuthenticationService already clears the shared logged-in cache
            // whenever this resolves to logged-out following a logged-in session (e.g.
            // an expired token) - re-resolve here to move off whatever this object showed
            // at init (possibly that now-stale cache) onto the current local snapshot.
            // A no-op for an ordinary continuing guest, who was already showing this.
            apply(snapshot)
        }

        guard pendingSeedStateRefresh, !hasHandledCurrentResolution else { return }
        pendingSeedStateRefresh = false
        hasHandledCurrentResolution = true
        refreshSeedState()
    }

    func handleSeedProgressUpdate() {
        guard !isLoggedIn else { return }

        let newSeedCount = Self.seedProgressManagerType.loadTotalSeedsCollected()

        if newSeedCount > seedCount {
            let increment = newSeedCount - seedCount
            EcosiaLogger.accounts.info("Seed progress updated for logged-out user: \(seedCount) → \(newSeedCount) (+\(increment))")
            animateBalanceChange(from: seedCount, to: newSeedCount, increment: increment)
        } else {
            seedCount = newSeedCount
        }
    }

    // MARK: - Seed Count Management

    /// Registers a visit when logged in, collects the daily local seed when logged out.
    public func refreshSeedState() {
        // Catch up: the resolution notification only reaches registered browser windows, so auth
        // may have resolved without this object hearing it.
        if !hasResolvedAuthState {
            isLoggedIn = auth.isLoggedIn
            hasResolvedAuthState = auth.hasResolvedAuthState
        }

        // Defer: a separate check from the catch-up above, because auth can still be resolving
        // after it. Branching on an unresolved isLoggedIn could treat a logged-in user as a guest.
        guard hasResolvedAuthState else {
            EcosiaLogger.accounts.debug("Deferring seed state refresh until auth state resolves")
            pendingSeedStateRefresh = true
            return
        }

        if isLoggedIn {
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

                let userID = auth.userID

                EcosiaLogger.accounts.info("Registering user visit for balance update")
                let response = try await accountsProvider.registerVisit(accessToken: accessToken)

                guard let currentUserID = auth.userID else {
                    EcosiaLogger.accounts.notice("Discarding register visit response - no signed-in account")
                    return
                }

                // A response for an earlier account would land under the current one. Compared by account,
                // not token, because a renew-on-401 inside the request replaces the token.
                guard currentUserID == userID else {
                    EcosiaLogger.accounts.notice("Discarding register visit response - account changed while in flight")
                    return
                }

                await updateBalance(response)

                await MainActor.run {
                    hasRegisterVisitError = false
                }
            } catch {
                EcosiaLogger.accounts.debug("Could not register visit: \(error.localizedDescription)")

                await MainActor.run {
                    hasRegisterVisitError = true
                }
            }
        }
    }

    @MainActor
    private func updateBalance(_ response: AccountVisitResponse) {
        let newSeedCount = response.seeds.balanceAmount
        let newLevelNumber = response.growthPoints.level.number
        let newProgress = response.progressToNextLevel

        currentLevelNumber = newLevelNumber
        currentProgress = newProgress

        persistLoggedInImpactSnapshot(seedCount: newSeedCount, currentLevelNumber: newLevelNumber, currentProgress: newProgress)

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
