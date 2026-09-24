// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// The authentication state `EcosiaAuthUIStateProvider` reads.
///
/// A seam for tests: `EcosiaAuthenticationService.shared` resolves credentials against the
/// keychain on its own `Task`, so it cannot be stood up per test with a known token or state.
public protocol EcosiaAuthStateReading: Sendable {
    var isLoggedIn: Bool { get }
    var hasResolvedAuthState: Bool { get }
    var accessToken: String? { get }
    var userProfile: UserProfile? { get }
}

extension EcosiaAuthenticationService: EcosiaAuthStateReading {}
