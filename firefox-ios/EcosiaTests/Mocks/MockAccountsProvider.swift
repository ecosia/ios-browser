// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
@testable import Ecosia

final class MockAccountsProvider: AccountsProviderProtocol, @unchecked Sendable {

    private let lock = NSLock()
    private var _result: Result<AccountVisitResponse, Error>
    private var _onRegisterVisit: (@Sendable () -> Void)?
    private var _receivedAccessTokens: [String] = []

    init(result: Result<AccountVisitResponse, Error>) {
        _result = result
    }

    var result: Result<AccountVisitResponse, Error> {
        get { lock.withLock { _result } }
        set { lock.withLock { _result = newValue } }
    }

    /// Runs before `result` is returned, e.g. to change the session while the request is in flight.
    var onRegisterVisit: (@Sendable () -> Void)? {
        get { lock.withLock { _onRegisterVisit } }
        set { lock.withLock { _onRegisterVisit = newValue } }
    }

    var receivedAccessTokens: [String] {
        lock.withLock { _receivedAccessTokens }
    }

    func registerVisit(accessToken: String) async throws -> AccountVisitResponse {
        let (result, onRegisterVisit) = lock.withLock {
            _receivedAccessTokens.append(accessToken)
            return (_result, _onRegisterVisit)
        }
        onRegisterVisit?()
        return try result.get()
    }
}
