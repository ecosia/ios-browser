// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
@testable import Client

class MockAppAuthenticator: AppAuthenticationProtocol {
    var authenticationState: AuthenticationState = .deviceOwnerAuthenticated
    var shouldAuthenticateDeviceOwner = true
    var shouldSucceed = true

    func getAuthenticationState(completion: @MainActor @escaping (AuthenticationState) -> Void) {
        let state = authenticationState
        MainActor.assumeIsolated { completion(state) }
    }

    var canAuthenticateDeviceOwner: Bool {
        return shouldAuthenticateDeviceOwner
    }

    func authenticateWithDeviceOwnerAuthentication(
        _ completion: @MainActor @escaping (Result<Void, AuthenticationError>) -> Void
    ) {
        if shouldSucceed {
            MainActor.assumeIsolated { completion(.success(())) }
        } else {
            MainActor.assumeIsolated {
                completion(.failure(.failedAuthentication(message: "Testing mock: failure")))
            }
        }
    }
}
