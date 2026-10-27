// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Ecosia

final class MockAuthSessionProvider: AuthSessionProviderProtocol, @unchecked Sendable {

    var isLoggedIn: Bool
    var hasResolvedAuthState: Bool
    var accessToken: String?
    var userID: String?

    init(isLoggedIn: Bool = false, hasResolvedAuthState: Bool = false, accessToken: String? = nil, userID: String? = nil) {
        self.isLoggedIn = isLoggedIn
        self.hasResolvedAuthState = hasResolvedAuthState
        self.accessToken = accessToken
        self.userID = userID
    }
}
