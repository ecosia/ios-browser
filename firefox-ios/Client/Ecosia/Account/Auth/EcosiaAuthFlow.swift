// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import WebKit
import Ecosia

/// Result of authentication flow operations
public enum EcosiaAuthFlowResult {
    case success
    case failure(error: AuthError)
}

/// Orchestrates complete authentication flows with invisible tab sessions
/// Provides core functionality for authentication operations
@MainActor
final class EcosiaAuthFlow {

    public enum FlowType {
        case login
        case signUp
        case logout
        case webSessionRetransfer
    }

    enum WebSessionRetransferResult: Equatable {
        case retransferred
        case loggedOut
        /// Nothing changed (e.g. no network), worth retrying later
        case deferred
    }

    // MARK: - Core Properties

    private let authService: EcosiaAuthenticationService
    private weak var browserViewController: BrowserViewController?
    private let type: FlowType

    // Active session (retained until completion)
    private var activeSession: InvisibleTabSession?

    // MARK: - Initialization

    /// Initializes the auth flow coordinator
    /// - Parameters:
    ///   - type: Type of authentication flow (login or logout)
    ///   - authService: Authentication service for auth operations
    ///   - browserViewController: Browser view controller for tab operations
    init(type: FlowType,
         authService: Ecosia.EcosiaAuthenticationService,
         browserViewController: BrowserViewController) {
        self.type = type
        self.authService = authService
        self.browserViewController = browserViewController

        EcosiaLogger.auth.info("AuthFlow initialized for \(type)")
    }

    // MARK: - Public Core API

    /// Starts the login authentication flow
    /// - Parameters:
    ///   - delayedCompletion: Delay before calling onNativeAuthCompleted
    ///   - onNativeAuthCompleted: Callback when Auth0 authentication completes
    ///   - onFlowCompleted: Callback when entire flow completes
    ///   - onError: Callback when authentication fails
    /// - Returns: Result of the authentication operation
    public func startLogin(
        delayedCompletion: TimeInterval = 0.0,
        onNativeAuthCompleted: (() -> Void)? = nil,
        onFlowCompleted: ((Bool) -> Void)? = nil,
        onError: ((AuthError) -> Void)? = nil
    ) async -> EcosiaAuthFlowResult {
        return await performAuthentication(
            type: .login,
            delayedCompletion: delayedCompletion,
            onNativeAuthCompleted: onNativeAuthCompleted,
            onFlowCompleted: onFlowCompleted,
            onError: onError
        )
    }

    public func startSignUp(
        delayedCompletion: TimeInterval = 0.0,
        onNativeAuthCompleted: (() -> Void)? = nil,
        onFlowCompleted: ((Bool) -> Void)? = nil,
        onError: ((AuthError) -> Void)? = nil
    ) async -> EcosiaAuthFlowResult {
        return await performAuthentication(
            type: .signUp,
            delayedCompletion: delayedCompletion,
            onNativeAuthCompleted: onNativeAuthCompleted,
            onFlowCompleted: onFlowCompleted,
            onError: onError
        )
    }

    /// Starts the logout authentication flow
    /// - Parameters:
    ///   - delayedCompletion: Delay before calling onNativeAuthCompleted
    ///   - onNativeAuthCompleted: Callback when Auth0 authentication completes
    ///   - onFlowCompleted: Callback when entire flow completes
    ///   - onError: Callback when authentication fails
    /// - Returns: Result of the authentication operation
    public func startLogout(
        delayedCompletion: TimeInterval = 0.0,
        onNativeAuthCompleted: (() -> Void)? = nil,
        onFlowCompleted: ((Bool) -> Void)? = nil,
        onError: ((AuthError) -> Void)? = nil
    ) async -> EcosiaAuthFlowResult {
        return await performAuthentication(
            type: .logout,
            delayedCompletion: delayedCompletion,
            onNativeAuthCompleted: onNativeAuthCompleted,
            onFlowCompleted: onFlowCompleted,
            onError: onError
        )
    }

    /// Re-runs the session transfer for a user who is already logged in natively, without any visible UI.
    /// A failed transfer logs out natively, like login does, so both sides stay in sync.
    func startWebSessionRetransfer() async -> WebSessionRetransferResult {
        EcosiaLogger.auth.info("Starting \(type) flow")

        guard let browserViewController else {
            return .deferred
        }

        guard isStillLoggedIn else {
            EcosiaLogger.auth.info("Web session re-transfer skipped: not logged in or logging out")
            return .loggedOut
        }

        switch await authService.getSessionTransferToken() {
        case .retrieved:
            break
        case .unavailable:
            return .deferred
        case .refreshTokenRejected:
            await logOutNativelyAfterFailedSessionTransfer()
            return .loggedOut
        }

        guard isStillLoggedIn else {
            EcosiaLogger.auth.info("Web session re-transfer abandoned: logged out during the exchange")
            return .loggedOut
        }

        let tabResult: SessionTransferTabResult
        do {
            tabResult = try await runSessionTransferTab(in: browserViewController)
        } catch {
            EcosiaLogger.auth.error("Could not start the web session re-transfer tab: \(error)")
            return .deferred
        }

        // A logout while the tab loaded would otherwise leave the web signed in on its own
        guard isStillLoggedIn else {
            EcosiaLogger.auth.info("Web session re-transfer abandoned: logged out while it ran")
            try? await authService.auth0Provider.clearSession()
            return .loggedOut
        }

        let hasWebSession = await hasAuthSessionCookie()
        if hasWebSession, tabResult.landedOnSuccess || tabResult.timedOut {
            EcosiaLogger.auth.info("Silent web session re-transfer completed")
            return .retransferred
        }

        // Sign-in and Auth0 pages never count as landed, so a timeout there is a failure, unless the tab was still loading
        if tabResult.timedOut, tabResult.landedOnSuccess || tabResult.wasStillLoading {
            EcosiaLogger.auth.notice("Silent web session re-transfer timed out")
            return .deferred
        }

        // A failure page is already reported by InvisibleTabSession
        if tabResult.landedOnSuccess {
            EcosiaLogger.auth.sentry("Silent web session re-transfer landed without a web session")
        } else {
            EcosiaLogger.auth.error("Silent web session re-transfer failed")
        }
        await logOutNativelyAfterFailedSessionTransfer()
        return .loggedOut
    }

    private var isStillLoggedIn: Bool {
        authService.isLoggedIn && !authService.isLoggingOut
    }

    // MARK: - Private Implementation

    private func performAuthentication(type: FlowType,
                                       delayedCompletion: TimeInterval = 0.0,
                                       onNativeAuthCompleted: (() -> Void)? = nil,
                                       onFlowCompleted: ((Bool) -> Void)? = nil,
                                       onError: ((AuthError) -> Void)? = nil
    ) async -> EcosiaAuthFlowResult {

        EcosiaLogger.auth.info("Starting \(type) flow")

        let retransferGate = WebSessionRecoveryCoordinator.shared.gate
        retransferGate.beginBlockingOperation()
        defer { retransferGate.endBlockingOperation() }

        do {
            switch type {
            case .login:
                // Step 1: Native Auth0 authentication
                try await performNativeAuthentication(screenHint: .login)

                // Step 2: Handle native auth completion callback
                await handleNativeAuthCompleted(
                    delayedCompletion: delayedCompletion,
                    onNativeAuthCompleted: onNativeAuthCompleted
                )

                // Step 3: Session transfer and invisible tab flow
                try await performSessionTransfer(onFlowCompleted: onFlowCompleted)

            case .signUp:
                try await performNativeAuthentication(screenHint: .signUp)

                await handleNativeAuthCompleted(
                    delayedCompletion: delayedCompletion,
                    onNativeAuthCompleted: onNativeAuthCompleted
                )

                try await performSessionTransfer(onFlowCompleted: onFlowCompleted)

            case .logout:
                // Step 1: Native Auth0 logout
                try await performNativeLogout()

                // Step 2: Handle native logout completion callback
                await handleNativeAuthCompleted(
                    delayedCompletion: delayedCompletion,
                    onNativeAuthCompleted: onNativeAuthCompleted
                )

                // Step 3: Session cleanup and invisible tab flow
                try await performSessionCleanup(onFlowCompleted: onFlowCompleted)

            case .webSessionRetransfer:
                throw AuthError.authFlowConfigurationError("Web session re-transfer runs through startWebSessionRetransfer()")
            }

            return .success
        } catch {
            let authError = mapToAuthError(error)
            await handleAuthFailure(authError, onError: onError)
            return .failure(error: authError)
        }
    }

    private func performNativeAuthentication(screenHint: AuthScreenHint) async throws {
        // Debug: Simulate auth error if enabled
        if UserDefaults.standard.bool(forKey: SimulateAuthErrorSetting.debugKey) {
            EcosiaLogger.auth.info("🐛 [DEBUG] Simulating login error")
            throw AuthError.authenticationFailed(NSError(domain: "EcosiaDebug", code: -1, userInfo: [NSLocalizedDescriptionKey: "Debug: Simulated authentication error"]))
        }

        EcosiaLogger.auth.info("Performing native Auth0 authentication (\(screenHint.rawValue))")
        switch screenHint {
        case .login:
            try await authService.login()
        case .signUp:
            try await authService.signUp()
        }
        EcosiaLogger.auth.info("Native Auth0 authentication completed")
    }

    private func performNativeLogout() async throws {
        // Debug: Simulate auth error if enabled
        if UserDefaults.standard.bool(forKey: SimulateAuthErrorSetting.debugKey) {
            EcosiaLogger.auth.info("🐛 [DEBUG] Simulating logout error")
            throw AuthError.sessionClearingFailed(NSError(domain: "EcosiaDebug", code: -1, userInfo: [NSLocalizedDescriptionKey: "Debug: Simulated logout error"]))
        }

        EcosiaLogger.auth.info("Performing native Auth0 logout")
        try await authService.logout()
        EcosiaLogger.auth.info("Native Auth0 logout completed")
    }

    private func handleNativeAuthCompleted(delayedCompletion: TimeInterval,
                                           onNativeAuthCompleted: (() -> Void)?) async {
        if delayedCompletion > 0 {
            // Ecosia: Use nanoseconds for iOS 15 compatibility (Task.sleep(for: .seconds) is iOS 16+)
            try? await Task.sleep(nanoseconds: UInt64(delayedCompletion * 1_000_000_000))
            onNativeAuthCompleted?()
        } else {
            onNativeAuthCompleted?()
        }
    }

    private func performSessionTransfer(onFlowCompleted: ((Bool) -> Void)?) async throws {

        guard let browserViewController = browserViewController else {
            throw AuthError.authFlowConfigurationError("BrowserViewController not available")
        }

        EcosiaLogger.session.info("Retrieving session transfer token for SSO")
        await authService.getSessionTransferToken()

        let success = try await runSessionTransferTab(in: browserViewController).landedOnSuccess
        EcosiaLogger.auth.info("Ecosia auth flow completed: \(success)")
        if !success {
            await logOutNativelyAfterFailedSessionTransfer()
        }
        onFlowCompleted?(success)
    }

    private struct SessionTransferTabResult {
        let landedOnSuccess: Bool
        let timedOut: Bool
        let wasStillLoading: Bool
    }

    /// Installs the transfer cookie and waits for the invisible tab to land or time out.
    private func runSessionTransferTab(in browserViewController: BrowserViewController) async throws -> SessionTransferTabResult {
        // Debug hook: loads /accounts/error directly instead of the real sign-up URL.
        logIfSimulatingSessionTransferFailure()
        let signUpURL = SimulateSessionTransferFailureSetting.isEnabled
            ? SimulateSessionTransferFailureSetting.forcedErrorPageURL
            : EcosiaEnvironment.current.urlProvider.signUpURL

        // The web reuses a still-valid session on sign-in, keeping its original 90-day lifetime
        await clearAuthSessionCookies()
        await InvisibleTabSession.installSessionCookie(from: authService)

        EcosiaLogger.invisibleTabs.info("Creating invisible tab session for \(type)")
        let session = try InvisibleTabSession(
            url: signUpURL,
            browserViewController: browserViewController,
            timeout: 10.0
        )

        // Retain session until completion
        activeSession = session

        return await withCheckedContinuation { continuation in
            session.startMonitoring { [weak self] success in
                Task { @MainActor in
                    self?.activeSession = nil
                    continuation.resume(returning: SessionTransferTabResult(landedOnSuccess: success,
                                                                            timedOut: !session.didLand,
                                                                            wasStillLoading: session.isLoading))
                }
            }
        }
    }

    /// There can be more than one, e.g. on another path or a subdomain, and any left behind would be sent along
    private func clearAuthSessionCookies() async {
        let cookieStore = WKWebsiteDataStore.default().httpCookieStore
        let domain = EcosiaEnvironment.current.urlProvider.domain
        let authSessionCookies = await (cookieStore as CookieStoreProtocol).allCookies().filter {
            $0.name == Cookie.authSession.rawValue && ($0.domain == domain || $0.domain.hasSuffix(".\(domain)"))
        }
        for cookie in authSessionCookies {
            await cookieStore.deleteCookie(cookie)
        }
    }

    /// The setting persists across launches, so make a forgotten one obvious in the logs
    private func logIfSimulatingSessionTransferFailure() {
        guard SimulateSessionTransferFailureSetting.isEnabled else { return }
        EcosiaLogger.auth.notice("🐛 [DEBUG] Simulate Session Transfer Failure is on: loading the accounts error page")
    }

    /// A transfer can land on a page that looks fine without the web having set a session.
    private func hasAuthSessionCookie() async -> Bool {
        let cookieStore: CookieStoreProtocol = WKWebsiteDataStore.default().httpCookieStore
        let cookies = await cookieStore.allCookies()
        return Cookie.authSessionCookie(in: cookies) != nil
    }

    /// A failed session transfer means the web session was never actually authenticated,
    /// so clear native credentials too instead of leaving native "logged in" with no working web session.
    /// `triggerWebLogout: false` since the web side already failed to authenticate; nothing there to log out of.
    private func logOutNativelyAfterFailedSessionTransfer() async {
        do {
            try await authService.logout(triggerWebLogout: false)
        } catch {
            EcosiaLogger.auth.error("Native-only logout after failed session transfer also failed: \(error)")
        }
    }

    private func performSessionCleanup(onFlowCompleted: ((Bool) -> Void)?) async throws {

        guard let browserViewController = browserViewController else {
            throw AuthError.authFlowConfigurationError("BrowserViewController not available")
        }

        // Get logout URL
        // Debug hook: loads /accounts/error directly instead of the real sign-up URL.
        logIfSimulatingSessionTransferFailure()
        let logoutURL = SimulateSessionTransferFailureSetting.isEnabled
            ? SimulateSessionTransferFailureSetting.forcedErrorPageURL
            : EcosiaEnvironment.current.urlProvider.logoutURL

        // Create invisible tab session for logout (must be on main thread for UI operations)
        EcosiaLogger.invisibleTabs.info("Creating invisible tab session for logout")
        let session = try await MainActor.run {
            try InvisibleTabSession(
                url: logoutURL,
                browserViewController: browserViewController,
                timeout: 10.0
            )
        }

        // Retain session until completion
        activeSession = session

        // Wait for session completion (startMonitoring is main-actor isolated)
        await withCheckedContinuation { continuation in
            Task { @MainActor in
                session.startMonitoring { [weak self] success in
                    self?.activeSession = nil // Release session
                    EcosiaLogger.auth.info("Ecosia logout flow completed: \(success)")
                    onFlowCompleted?(success)
                    continuation.resume()
                }
            }
        }
    }

    private func handleAuthFailure(_ error: AuthError,
                                   onError: ((AuthError) -> Void)?) async {
        activeSession = nil

        EcosiaLogger.auth.error("Auth flow failed: \(error)")
        onError?(error)
    }

    private func mapToAuthError(_ error: Error) -> AuthError {
        if let authError = error as? AuthError {
            return authError
        }
        return AuthError.authFlowConfigurationError(error.localizedDescription)
    }
}
