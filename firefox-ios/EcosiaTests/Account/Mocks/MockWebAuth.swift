// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Auth0
import Combine
@testable import Ecosia
/// Mock implementation of WebAuth protocol for testing protocol default implementations
class MockWebAuth: WebAuth {

    // MARK: - Required Properties
    var clientId: String = "test-client-id"
    var url = URL(string: "https://test.auth0.com")!
    var telemetry = Telemetry()
    var logger: Logger?
    var session = URLSession.shared

    // MARK: - Test Control Properties
    var shouldFailStart = false
    var shouldFailClearSession = false
    var mockError: Error?
    var mockCredentials: Credentials?

    // MARK: - Call Tracking
    var startCallCount = 0
    var clearSessionCallCount = 0

    // MARK: - Mock Implementation
    func start() async throws -> Credentials {
        startCallCount += 1

        if shouldFailStart {
            throw mockError ?? NSError(domain: "MockWebAuth", code: 3001, userInfo: [NSLocalizedDescriptionKey: "Mock start failure"])
        }

        return mockCredentials ?? createMockCredentials()
    }

    func clearSession() async throws {
        clearSessionCallCount += 1

        if shouldFailClearSession {
            throw mockError ?? NSError(domain: "MockWebAuth", code: 3002, userInfo: [NSLocalizedDescriptionKey: "Mock clear session failure"])
        }
    }

    // MARK: - Required Methods (unused in our tests but required by protocol)
    func connectionScope(_ connectionScope: String) -> Self { return self }
    func headers(_ headers: [String: String]) -> Self { return self }
    func authorizeURL(_ authorizeURL: URL) -> Self { return self }
    func nonce(_ nonce: String) -> Self { return self }
    func issuer(_ issuer: String) -> Self { return self }
    func leeway(_ leeway: Int) -> Self { return self }
    func useEphemeralSession() -> Self { return self }
    func onClose(_ callback: (() -> Void)?) -> Self { return self }
    func audience(_ audience: String) -> Self { return self }
    func scope(_ scope: String) -> Self { return self }
    func connection(_ connection: String) -> Self { return self }
    func state(_ state: String) -> Self { return self }
    func parameters(_ parameters: [String: String]) -> Self { return self }
    func provider(_ provider: WebAuthProvider) -> Self { return self }
    func logging(enabled: Bool) -> Self { return self }
    func useHTTPS() -> Self { return self }
    func useUniversalLink() -> Self { return self }
    func redirectURL(_ redirectURL: URL) -> Self { return self }
    func organization(_ organization: String) -> Self { return self }
    func invitationURL(_ invitationURL: URL) -> Self { return self }
    func maxAge(_ maxAge: Int) -> Self { return self }

    // MARK: - Required callback and publisher methods
    func start(_ callback: @escaping (WebAuthResult<Credentials>) -> Void) {
        // Not used in our tests, but required by protocol
    }

    func start() -> AnyPublisher<Credentials, WebAuthError> {
        // Not used in our tests, but required by protocol
        return Empty<Credentials, WebAuthError>().eraseToAnyPublisher()
    }

    // MARK: - Helper Methods
    private func createMockCredentials() -> Credentials {
        return Credentials(
            accessToken: "mock-web-access-token",
            tokenType: "Bearer",
            idToken: "mock-web-id-token",
            refreshToken: "mock-web-refresh-token",
            expiresIn: Date().addingTimeInterval(3600),
            scope: "openid profile email"
        )
    }

    func reset() {
        shouldFailStart = false
        shouldFailClearSession = false
        mockError = nil
        mockCredentials = nil
        startCallCount = 0
        clearSessionCallCount = 0
    }
}
