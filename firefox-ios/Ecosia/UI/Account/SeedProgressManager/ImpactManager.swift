// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// Owns seed/level/progress ("impact") state for both logged-in and logged-out users, and is the
/// only thing that touches the shared `ImpactCacheProtocol` cache directly - the logged-out
/// lifecycle is delegated to `LoggedOutSeedProgressManager`, which shares the same cache
/// instance. A dependency of `EcosiaAuthUIStateProvider`, so tests can inject their own
/// cache/`LoggedOutSeedProgressManager`.
///
/// Every method takes the raw `isLoggedIn`/`userId` state and decides internally what that means -
/// `EcosiaAuthUIStateProvider` never branches on login state itself, it just hands its state
/// through and applies whatever comes back.
///
/// Three actions cover everything `EcosiaAuthUIStateProvider` needs:
///
/// - `loadSeeds`: read the current snapshot, regardless of login state - a pure read, returning a
///   zeroed default without writing anything if nothing's stored yet.
/// - `updateSeeds`: fetch new seeds - `LoggedOutSeedProgressManager` decides whether/how many to
///   add locally, or a `registerVisit` call returns the server's balance - and persist the result.
///   This is the one trigger for "new seeds", regardless of login state.
/// - `reset`: clear the entire cache. Only happens on logout or local data deletion.
public final class ImpactManager: @unchecked Sendable {

    private let cache: ImpactCacheProtocol
    private let loggedOutManager: LoggedOutSeedProgressManager

    public init(cache: ImpactCacheProtocol = ImpactCache(), loggedOutManager: LoggedOutSeedProgressManager? = nil) {
        self.cache = cache
        self.loggedOutManager = loggedOutManager ?? LoggedOutSeedProgressManager(cache: cache)
    }

    /// Result of `updateSeeds`: the resulting snapshot plus the signals `EcosiaAuthUIStateProvider`
    /// needs to animate correctly, or why nothing was fetched.
    enum SeedsUpdate {
        case updated(snapshot: ImpactSnapshot, didLevelUp: Bool, seedsIncrement: Int?)
        case registerVisitSkipped
        case registerVisitFailed
    }

    // MARK: - Loading

    /// Reads the current snapshot, or a zeroed default if nothing's stored yet - a pure read, it
    /// never writes to the cache. Logged out always reads the local guest lifecycle. Logged in
    /// with no userId yet (the transient window right after auth state flips, before the
    /// profile arrives) also returns the zeroed default, never the guest's own local snapshot.
    public func loadSeeds(isLoggedIn: Bool, userId: String?) -> ImpactSnapshot {
        guard isLoggedIn else {
            return loggedOutManager.load()
        }
        guard userId != nil else {
            return .zero
        }
        return cache.load() ?? .zero
    }

    // MARK: - Updating

    /// Single trigger for fetching new seeds, regardless of login state, and persisting the
    /// result: a logged-out user gets today's local seed if due (capped at
    /// `LoggedOutSeedProgressManager.maxSeedsForLoggedOutUsers`); a logged-in one registers a
    /// visit against the backend.
    func updateSeeds(
        isLoggedIn: Bool,
        userId: String?,
        accessToken: String?,
        accountsProvider: AccountsProviderProtocol
    ) async -> SeedsUpdate {
        guard isLoggedIn else {
            EcosiaLogger.accounts.debug("Refreshing seed state for logged-out user (daily seed check)")
            let (snapshot, increment) = loggedOutManager.collectDailySeedIfDue()
            return .updated(snapshot: snapshot, didLevelUp: false, seedsIncrement: increment)
        }

        EcosiaLogger.accounts.debug("Refreshing seed state for logged-in user (server fetch)")
        guard userId != nil else {
            EcosiaLogger.accounts.notice("Cannot register visit - user id not yet available")
            return .registerVisitSkipped
        }
        guard let accessToken, !accessToken.isEmpty else {
            EcosiaLogger.accounts.notice("Cannot register visit - no access token available")
            return .registerVisitSkipped
        }

        do {
            EcosiaLogger.accounts.info("Registering user visit for balance update")
            let response = try await accountsProvider.registerVisit(accessToken: accessToken)
            let snapshot = snapshot(from: response)
            cache.save(snapshot)
            return .updated(snapshot: snapshot, didLevelUp: response.didLevelUp, seedsIncrement: response.seedsIncrement)
        } catch {
            EcosiaLogger.accounts.debug("Could not register visit: \(error.localizedDescription)")
            return .registerVisitFailed
        }
    }

    /// Turns a `registerVisit` response into a snapshot.
    private func snapshot(from response: AccountVisitResponse) -> ImpactSnapshot {
        ImpactSnapshot(
            seedCount: response.seeds.balanceAmount,
            currentLevelNumber: response.growthPoints.level.number,
            currentProgress: response.progressToNextLevel
        )
    }

    /// Debug-only: applies a synthetic `registerVisit` response without a real network call, so QA
    /// can test balance/level-up animations. Persists like a real one - only while actually logged
    /// in with a known user id, so it never overwrites the guest's own local seed count.
    @discardableResult
    public func debugUpdateBalance(_ response: AccountVisitResponse, isLoggedIn: Bool, userId: String?) -> ImpactSnapshot {
        let snapshot = snapshot(from: response)
        if isLoggedIn, userId != nil {
            cache.save(snapshot)
        }
        return snapshot
    }

    /// Debug-only: force-adds `count` seeds to the logged-out cache directly, bypassing the
    /// once-per-day gate, so QA can rapid-test the seed/level UI without waiting a day between
    /// taps. Returns the resulting snapshot and how much the seed count increased by, so the
    /// caller (`EcosiaAuthUIStateProvider.debugAddLoggedOutSeed()`) can animate it the same way
    /// `updateSeeds` does.
    @discardableResult
    public func debugAddLoggedOutSeeds(_ count: Int) -> (snapshot: ImpactSnapshot, increment: Int) {
        loggedOutManager.addDebugSeeds(count)
    }

    // MARK: - Resetting

    /// Clears the entire shared cache. Only called on logout or local data deletion.
    public func reset() {
        loggedOutManager.reset()
    }
}
