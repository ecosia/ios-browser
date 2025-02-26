// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Ecosia

final class MockHTTPClient: HTTPClient {

    var performCalled = false
    var performRequest: BaseRequest?
    var performResult: HTTPClient.Result?
    var performError: Error?

    func perform(_ request: BaseRequest) async throws -> HTTPClient.Result {
        performCalled = true
        performRequest = request

        if let error = performError {
            throw error
        }

        return performResult ?? (Data(), HTTPURLResponse())
    }
}
