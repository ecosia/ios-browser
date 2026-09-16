// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Ecosia
import Foundation

/// Records every `registerVisit` call and lets a test script a canned response, a thrown error, or
/// an artificial delay - so tests can race a cancellation or an identity switch against a
/// still-in-flight request.
final class MockAccountsProvider: AccountsProviderProtocol, @unchecked Sendable {
    var result: Result<AccountVisitResponse, Error> = .failure(MockAccountsProviderError.unconfigured)
    private(set) var receivedAccessTokens: [String] = []
    var delayNanoseconds: UInt64 = 0

    func registerVisit(accessToken: String) async throws -> AccountVisitResponse {
        receivedAccessTokens.append(accessToken)
        if delayNanoseconds > 0 {
            try await Task.sleep(nanoseconds: delayNanoseconds)
        }
        return try result.get()
    }
}

enum MockAccountsProviderError: Error {
    case unconfigured
}
