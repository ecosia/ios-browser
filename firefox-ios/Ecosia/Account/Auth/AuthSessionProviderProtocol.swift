// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// Read-only view of the current auth session for consumers that must not depend on `EcosiaAuthenticationService`.
public protocol AuthSessionProviderProtocol: Sendable {
    var isLoggedIn: Bool { get }
    var hasResolvedAuthState: Bool { get }
    var accessToken: String? { get }
}
