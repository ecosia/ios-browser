// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Ecosia

/// Silently re-runs the native-to-web session transfer when the web session is lost while the user is still logged in natively.
@MainActor
final class WebSessionRecoveryCoordinator {

    static let shared = WebSessionRecoveryCoordinator()

    let gate: WebSessionRetransferGate

    private let authService: EcosiaAuthenticationService
    private let browserViewControllers = NSHashTable<BrowserViewController>.weakObjects()
    private var pendingRetry: Task<Void, Never>?

    init(gate: WebSessionRetransferGate = WebSessionRetransferGate(),
         authService: EcosiaAuthenticationService = .shared) {
        self.gate = gate
        self.authService = authService
    }

    func register(_ browserViewController: BrowserViewController) {
        browserViewControllers.add(browserViewController)
    }

    func retransferWebSession(reason: String) {
        // A direct `logout()` (e.g. from the account impact view) doesn't block the gate
        guard authService.isLoggedIn, !authService.isLoggingOut else { return }

        switch gate.requestStart() {
        case .start:
            pendingRetry?.cancel()
            pendingRetry = nil
            Task { await runRetransfer(reason: reason) }
        case .alreadyRunning, .blocked:
            EcosiaLogger.auth.info("Web session re-transfer (\(reason)) skipped: another auth flow is running")
        case .retryAfter(let delay):
            scheduleRetry(after: delay, reason: reason)
        case .limitReached:
            EcosiaLogger.auth.sentry("Web session re-transfer (\(reason)) skipped: attempt limit reached")
        }
    }

    private func runRetransfer(reason: String) async {
        guard let browserViewController = activeBrowserViewController else {
            EcosiaLogger.auth.notice("Web session re-transfer (\(reason)) skipped: no browser window available")
            gate.finish(succeeded: false)
            return
        }

        EcosiaLogger.auth.info("Starting silent web session re-transfer (\(reason))")
        let flow = EcosiaAuthFlow(type: .webSessionRetransfer,
                                  authService: authService,
                                  browserViewController: browserViewController)
        let result = await flow.startWebSessionRetransfer()
        gate.finish(succeeded: result == .retransferred)

        if result == .deferred {
            retransferWebSession(reason: reason)
        }
    }

    private func scheduleRetry(after delay: TimeInterval, reason: String) {
        guard pendingRetry == nil else { return }
        EcosiaLogger.auth.info("Web session re-transfer (\(reason)) retrying in \(Int(delay))s")
        pendingRetry = Task { [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            guard !Task.isCancelled else { return }
            self?.pendingRetry = nil
            self?.retransferWebSession(reason: reason)
        }
    }

    /// The invisible tab has to live in a window the user can't see change, so prefer the foreground one.
    private var activeBrowserViewController: BrowserViewController? {
        let candidates = browserViewControllers.allObjects.filter { $0.view.window != nil }
        return candidates.first { $0.view.window?.windowScene?.activationState == .foregroundActive }
            ?? candidates.first
    }
}
