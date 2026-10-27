// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import JWTDecode

public struct EcosiaAuthSessionProvider: AuthSessionProviderProtocol {

    private let authenticationService: EcosiaAuthenticationService

    public init(authenticationService: EcosiaAuthenticationService = .shared) {
        self.authenticationService = authenticationService
    }

    public var isLoggedIn: Bool { authenticationService.isLoggedIn }
    public var hasResolvedAuthState: Bool { authenticationService.hasResolvedAuthState }
    public var accessToken: String? { authenticationService.accessToken }
    public var userID: String? {
        guard let idToken = authenticationService.idToken else { return nil }
        return try? decode(jwt: idToken).subject
    }
}
