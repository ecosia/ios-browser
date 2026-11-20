// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Combine
import Foundation

/// Read-only view of the current auth session for consumers that must not depend on `EcosiaAuthenticationService`.
public protocol AuthSessionProviderProtocol: Sendable {
    var isLoggedIn: Bool { get }
    var hasResolvedAuthState: Bool { get }
    var accessToken: String? { get }
    /// The signed-in account's Auth0 `sub`; unlike `accessToken`, it stays the same across credential renewals.
    var userID: String? { get }
    /// One event per auth transition, delivered on the main actor. No replay: subscribe before reading
    /// `isLoggedIn` / `hasResolvedAuthState`, so a transition can't land between the read and the subscription.
    var authEvents: AnyPublisher<AuthEvent, Never> { get }
}
