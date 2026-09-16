// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// Owns fetching and persisting the logged-in impact snapshot via `registerVisit`. Reacts to auth
/// state on its own - starts a fetch when a login (and its user id) becomes known, and cancels any
/// in-flight one on logout - so callers only need an explicit `refresh()` for triggers that aren't
/// an auth transition (e.g. NTP appearing or the app returning to foreground).
public final class LoggedInImpactUpdater: @unchecked Sendable {

    private let cache: ImpactCacheProtocol
    private let accountsProvider: AccountsProviderProtocol
    private let authenticationService: EcosiaAuthenticationService

    private var authStateObserver: NSObjectProtocol?
    private var userProfileObserver: NSObjectProtocol?
    /// The in-flight `registerVisit` fetch, if any. Cancelling this actually aborts the underlying
    /// network request (`URLSessionHTTPClient` uses `URLSession`'s async `data(for:)`, which
    /// propagates Task cancellation down to the real `URLSessionTask`), not just the caller's
    /// interest in the result.
    private var inFlightTask: Task<Void, Never>?
    /// The user id an automatic fetch has already been started for, so `.EcosiaUserProfileUpdated`
    /// firing again for the same user (e.g. an avatar refresh) doesn't restart a fresh
    /// `registerVisit` on every ancillary profile update - only `refresh()` does that.
    private var autoFetchedUserID: String?

    public init(
        cache: ImpactCacheProtocol,
        accountsProvider: AccountsProviderProtocol,
        authenticationService: EcosiaAuthenticationService = .shared
    ) {
        self.cache = cache
        self.accountsProvider = accountsProvider
        self.authenticationService = authenticationService
        observeAuthState()
    }

    deinit {
        inFlightTask?.cancel()
        if let authStateObserver {
            NotificationCenter.default.removeObserver(authStateObserver)
        }
        if let userProfileObserver {
            NotificationCenter.default.removeObserver(userProfileObserver)
        }
    }

    /// Explicit trigger for callers that don't go through an auth-state transition, e.g. NTP
    /// appearing or the app returning to foreground. Always starts a fresh fetch (unlike the
    /// automatic observers below, which only fetch once per user id). A no-op while logged out.
    public func refresh() {
        guard authenticationService.isLoggedIn, let userID = authenticationService.userProfile?.sub else {
            return
        }
        startFetch(userID: userID)
    }

    /// Reads the cached snapshot if it currently belongs to `userID`, or `nil` otherwise (nothing
    /// cached yet, or the shared slot still holds a different identity's data). A pure read.
    public func cachedSnapshot(for userID: String) -> ImpactSnapshot? {
        guard let cached = cache.load(), cached.loggedInUserID == userID else { return nil }
        return cached
    }

    /// Debug-only: applies a synthetic `registerVisit` response without a real network call, so QA
    /// can test balance/level-up animations. Persists exactly like a real response.
    @discardableResult
    public func debugApply(_ response: AccountVisitResponse, userID: String) -> ImpactSnapshot {
        let snapshot = ImpactSnapshot(
            seedCount: response.seeds.balanceAmount,
            currentLevelNumber: response.growthPoints.level.number,
            currentProgress: response.progressToNextLevel,
            loggedInUserID: userID
        )
        cache.save(snapshot, seedsIncrement: response.seedsIncrement, didLevelUp: response.didLevelUp)
        return snapshot
    }

    // MARK: - Reactivity

    private func observeAuthState() {
        authStateObserver = NotificationCenter.default.addObserver(
            forName: .EcosiaAuthStateChanged,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let actionType = notification.userInfo?["actionType"] as? EcosiaAuthActionType else { return }
            switch actionType {
            case .userLoggedIn:
                EcosiaLogger.accounts.info("User logged in - registering visit")
                self?.autoFetchIfNeeded()
            case .userLoggedOut:
                EcosiaLogger.accounts.info("User logged out - cancelling any in-flight visit")
                self?.cancelInFlightFetch()
                self?.autoFetchedUserID = nil
            case .authStateLoaded:
                break
            }
        }

        // The profile (and so the user id) can arrive after `.userLoggedIn` already tried and
        // skipped a fetch for lack of one - retry now that it's known. This notification can also
        // fire again later for reasons unrelated to login (e.g. an avatar refresh), so
        // `autoFetchIfNeeded()` only actually fetches on the unknown-to-known transition, not on
        // every firing - otherwise each one would cancel and restart the previous attempt.
        userProfileObserver = NotificationCenter.default.addObserver(
            forName: .EcosiaUserProfileUpdated,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.autoFetchIfNeeded()
        }
    }

    private func autoFetchIfNeeded() {
        guard authenticationService.isLoggedIn,
              let userID = authenticationService.userProfile?.sub,
              userID != autoFetchedUserID else {
            return
        }
        startFetch(userID: userID)
    }

    private func startFetch(userID: String) {
        autoFetchedUserID = userID
        cancelInFlightFetch()
        inFlightTask = Task { [weak self] in
            await self?.fetchAndStore(expectedUserID: userID)
        }
    }

    private func cancelInFlightFetch() {
        inFlightTask?.cancel()
        inFlightTask = nil
    }

    // MARK: - Fetch

    private func fetchAndStore(expectedUserID: String) async {
        guard let accessToken = authenticationService.accessToken, !accessToken.isEmpty else {
            EcosiaLogger.accounts.notice("Cannot register visit - no access token available")
            return
        }

        do {
            EcosiaLogger.accounts.info("Registering user visit for balance update")
            let response = try await accountsProvider.registerVisit(accessToken: accessToken)
            try Task.checkCancellation()

            // Defense in depth alongside cancellation: a logout-and-back-in (same or different
            // account) between the request starting and resolving must never write this response
            // under the new identity.
            guard authenticationService.userProfile?.sub == expectedUserID else {
                EcosiaLogger.accounts.notice("Discarding registerVisit response - active user changed while in flight")
                return
            }

            let snapshot = ImpactSnapshot(
                seedCount: response.seeds.balanceAmount,
                currentLevelNumber: response.growthPoints.level.number,
                currentProgress: response.progressToNextLevel,
                loggedInUserID: expectedUserID
            )
            cache.save(snapshot, seedsIncrement: response.seedsIncrement, didLevelUp: response.didLevelUp)
        } catch is CancellationError {
            EcosiaLogger.accounts.debug("registerVisit cancelled - session changed while in flight")
        } catch {
            EcosiaLogger.accounts.debug("Could not register visit: \(error.localizedDescription)")
            NotificationCenter.default.post(name: .EcosiaImpactUpdateFailed, object: nil)
        }
    }
}

extension Notification.Name {
    /// Posted by `LoggedInImpactUpdater` when a triggered `registerVisit` fails (a cancelled
    /// request does not count as a failure - the session changing is expected, not an error).
    public static let EcosiaImpactUpdateFailed = Notification.Name("EcosiaImpactUpdateFailed")
}
