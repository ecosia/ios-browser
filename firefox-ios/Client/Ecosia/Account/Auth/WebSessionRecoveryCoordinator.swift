// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import WebKit
import Ecosia

/// Silently re-runs the native-to-web session transfer when the web session is lost while the user is still logged in natively.
///
/// The web deletes `EASC` once it can no longer refresh the session, so a missing cookie is the only signal needed.
@MainActor
final class WebSessionRecoveryCoordinator {

    /// What prompted a re-transfer, for logs
    enum Trigger: String, CustomStringConvertible {
        case launch
        case foreground
        case cookieRemoved = "cookie removed"
        case signInIntercepted = "sign-in intercepted"
        case debug

        var description: String { rawValue }
    }

    static let shared = WebSessionRecoveryCoordinator()

    let gate: WebSessionRetransferGate

    private let authService: EcosiaAuthenticationService
    private let browserViewControllers = NSHashTable<BrowserViewController>.weakObjects()
    private var pendingRetry: Task<Void, Never>?
    private var inFlightRetransfer: Task<EcosiaAuthFlow.WebSessionRetransferResult, Never>?
    private var observers: [NSObjectProtocol] = []

    init(gate: WebSessionRetransferGate = WebSessionRetransferGate(),
         authService: EcosiaAuthenticationService = .shared) {
        self.gate = gate
        self.authService = authService
        observeWebSessionTriggers()
    }

    func register(_ browserViewController: BrowserViewController) {
        browserViewControllers.add(browserViewController)
        // Auth state can resolve before any window registers, in which case its launch notification reaches nobody
        Task { await retransferIfWebSessionMissing(trigger: .launch) }
    }

    /// Re-transfers when the user is logged in natively but the web session cookie is gone.
    func retransferIfWebSessionMissing(trigger: Trigger) async {
        guard authService.hasResolvedAuthState, authService.isLoggedIn, !authService.isLoggingOut else { return }

        let cookieStore: CookieStoreProtocol = WKWebsiteDataStore.default().httpCookieStore
        guard Cookie.authSessionCookie(in: await cookieStore.allCookies()) == nil else { return }

        EcosiaLogger.auth.info("Web session missing while logged in natively (\(trigger))")
        retransferWebSession(trigger: trigger)
    }

    func retransferWebSession(trigger: Trigger) {
        _ = startRetransfer(trigger: trigger)
    }

    /// Starts a re-transfer, or joins the one already running, and waits for its result.
    /// - Returns: `nil` when no re-transfer could run now (blocked by another auth flow, backing off or capped)
    func startOrJoinRetransfer(trigger: Trigger) async -> EcosiaAuthFlow.WebSessionRetransferResult? {
        if let inFlightRetransfer {
            return await inFlightRetransfer.value
        }
        return await startRetransfer(trigger: trigger)?.value
    }

    private func startRetransfer(trigger: Trigger) -> Task<EcosiaAuthFlow.WebSessionRetransferResult, Never>? {
        // A direct `logout()` (e.g. from the account impact view) doesn't block the gate
        guard authService.isLoggedIn, !authService.isLoggingOut else { return nil }

        switch gate.requestStart() {
        case .start:
            pendingRetry?.cancel()
            pendingRetry = nil
            let retransfer = Task { await runRetransfer(trigger: trigger) }
            inFlightRetransfer = retransfer
            return retransfer
        case .alreadyRunning:
            return inFlightRetransfer
        case .blocked:
            EcosiaLogger.auth.info("Web session re-transfer (\(trigger)) skipped: another auth flow is running")
        case .retryAfter(let delay):
            scheduleRetry(after: delay, trigger: trigger)
        case .limitReached:
            EcosiaLogger.auth.sentry("Web session re-transfer (\(trigger)) skipped: attempt limit reached")
        }
        return nil
    }

    private func runRetransfer(trigger: Trigger) async -> EcosiaAuthFlow.WebSessionRetransferResult {
        let result = await performRetransfer(trigger: trigger)
        gate.finish(succeeded: result == .retransferred)
        inFlightRetransfer = nil

        if result == .deferred {
            await retransferIfWebSessionMissing(trigger: trigger)
        }
        return result
    }

    private func performRetransfer(trigger: Trigger) async -> EcosiaAuthFlow.WebSessionRetransferResult {
        guard let browserViewController = activeBrowserViewController else {
            EcosiaLogger.auth.notice("Web session re-transfer (\(trigger)) skipped: no browser window available")
            return .deferred
        }

        EcosiaLogger.auth.info("Starting silent web session re-transfer (\(trigger))")
        let flow = EcosiaAuthFlow(type: .webSessionRetransfer,
                                  authService: authService,
                                  browserViewController: browserViewController)
        return await flow.startWebSessionRetransfer()
    }

    private func scheduleRetry(after delay: TimeInterval, trigger: Trigger) {
        guard pendingRetry == nil else { return }
        EcosiaLogger.auth.info("Web session re-transfer (\(trigger)) retrying in \(Int(delay))s")
        pendingRetry = Task { [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            guard !Task.isCancelled else { return }
            self?.pendingRetry = nil
            // The web session may be back by now, so only retry if it's still missing
            await self?.retransferIfWebSessionMissing(trigger: trigger)
        }
    }

    /// Removals cover the app running; launch and foreground cover anything that happened while it wasn't.
    private func observeWebSessionTriggers() {
        observe(.EcosiaAuthSessionCookieRemoved, trigger: .cookieRemoved)
        observe(UIApplication.didBecomeActiveNotification, trigger: .foreground)
        observe(.EcosiaAuthStateChanged, trigger: .launch) {
            ($0.userInfo?["actionType"] as? EcosiaAuthActionType) == .authStateLoaded
        }
    }

    private func observe(_ name: Notification.Name,
                         trigger: Trigger,
                         when isRelevant: @escaping @Sendable (Notification) -> Bool = { _ in true }) {
        let observer = NotificationCenter.default.addObserver(forName: name, object: nil, queue: .main) { [weak self] notification in
            guard isRelevant(notification) else { return }
            Task { @MainActor in
                await self?.retransferIfWebSessionMissing(trigger: trigger)
            }
        }
        observers.append(observer)
    }

    /// The invisible tab has to live in a window the user can't see change, so prefer the foreground one.
    private var activeBrowserViewController: BrowserViewController? {
        let candidates = browserViewControllers.allObjects.filter { $0.view.window != nil }
        return candidates.first { $0.view.window?.windowScene?.activationState == .foregroundActive }
            ?? candidates.first
    }
}
