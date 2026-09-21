// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Ecosia
import Foundation

/// Builds `EcosiaAuthenticationService` instances in controlled states for Impact tests, following
/// the same `MockAuth0Provider` + `skipUserInfoFetch` pattern as `AuthWorkflowTests`. Since the real
/// user-info fetch is a live Auth0 network call with no mock seam, `setUserProfileForTesting` fills
/// in the `sub` that call would otherwise have provided.
@MainActor
enum ImpactTestAuth {

    /// A logged-out service. Its `MockAuth0Provider` already has credentials configured, so a later
    /// `logIn(_:sub:)` on this SAME instance (to test a guest-to-logged-in transition within one
    /// session) succeeds without further setup.
    static func makeLoggedOut(accessToken: String = "test-access-token") -> EcosiaAuthenticationService {
        let mockProvider = MockAuth0Provider()
        mockProvider.mockCredentials = ImpactTestFixtures.credentials(accessToken: accessToken)
        let service = EcosiaAuthenticationService(auth0Provider: mockProvider)
        service.skipUserInfoFetch = true
        return service
    }

    /// A logged-in service, reached through a real `login()` call against the mocked provider.
    @discardableResult
    static func makeLoggedIn(sub: String = "auth0|test-user", accessToken: String = "test-access-token") async -> EcosiaAuthenticationService {
        let service = makeLoggedOut(accessToken: accessToken)
        await logIn(service, sub: sub)
        return service
    }

    /// Simulates a cold app launch that already has a valid stored session: pre-seeds the mock
    /// provider with stored credentials *before* constructing the service, so the automatic
    /// `retrieveStoredCredentials()` that `EcosiaAuthenticationService.init` fires reaches a
    /// logged-in state on its own - exactly like a real cold launch with a previous session. The
    /// sleep matches `AuthWorkflowTests.testCompleteAuthenticationLifecycle_persistenceAfterRestart_worksEndToEnd`'s
    /// own settle time for this exact mechanism.
    static func makeColdLaunchLoggedIn(sub: String = "auth0|test-user", accessToken: String = "test-access-token") async -> EcosiaAuthenticationService {
        let mockProvider = MockAuth0Provider()
        mockProvider.hasStoredCredentials = true
        mockProvider.mockCredentials = ImpactTestFixtures.credentials(accessToken: accessToken)
        let service = EcosiaAuthenticationService(auth0Provider: mockProvider)
        service.skipUserInfoFetch = true
        try? await Task.sleep(nanoseconds: 100_000_000)
        service.setUserProfileForTesting(UserProfile(name: "Test User", email: "test@example.com", picture: nil, sub: sub))
        return service
    }

    /// Transitions an existing service into a logged-in state with `sub` - lets a test drive a
    /// guest-to-logged-in or account-switch transition on one persistent `EcosiaAuthenticationService`
    /// instance, the way the real app does, rather than swapping in a fresh instance.
    static func logIn(_ service: EcosiaAuthenticationService, sub: String = "auth0|test-user") async {
        try? await service.login()
        service.setUserProfileForTesting(UserProfile(name: "Test User", email: "test@example.com", picture: nil, sub: sub))
    }
}
