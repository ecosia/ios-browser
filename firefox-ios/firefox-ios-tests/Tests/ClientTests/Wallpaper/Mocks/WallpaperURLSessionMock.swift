// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

@testable import Client

class WallpaperURLSessionDataTaskMock: URLSessionDataTaskProtocol {
    private(set) var resumeWasCalled = false

    func resume() {
        resumeWasCalled = true
    }
}

final class WallpaperURLSessionMock: URLSessionProtocol, @unchecked Sendable {
    var dataTask = WallpaperURLSessionDataTaskMock()
    private let data: Data?
    private let response: URLResponse?
    private let error: Error?

    init(
        with data: Data? = nil,
        response: URLResponse? = nil,
        and error: Error? = nil
    ) {
        self.data = data
        self.response = response
        self.error = error
    }

    func data(from url: URL) async throws -> (Data, URLResponse) {
        if let error = error {
            throw error
        }

        return (data ?? Data(), response ?? URLResponse())
    }

    func data(from urlRequest: URLRequest) async throws -> (Data, URLResponse) {
        if let error = error {
            throw error
        }
        return (data ?? Data(), response ?? URLResponse())
    }

    func dataTaskWith(_ url: URL,
                      completionHandler completion: @escaping @Sendable DataTaskResult
    ) -> URLSessionDataTaskProtocol {
        completion(data, response, error)
        return dataTask
    }

    func dataTaskWith(
        request: URLRequest,
        completionHandler: @escaping @Sendable (Data?, URLResponse?, Error?) -> Void
    ) -> URLSessionDataTaskProtocol {
        return MockURLSessionDataTaskProtocol()
    }

    func uploadTaskWith(
        with request: URLRequest,
        from bodyData: Data?,
        completionHandler: @escaping @Sendable (Data?, URLResponse?, (any Error)?) -> Void
    ) -> URLSessionUploadTaskProtocol {
        completionHandler(data, response, error)
        return MockURLSessionUploadTaskProtocol()
    }
}

final class MockURLSessionDataTaskProtocol: URLSessionDataTaskProtocol {
    func resume() {}
}

final class MockURLSessionUploadTaskProtocol: URLSessionUploadTaskProtocol {
    var countOfBytesClientExpectsToSend: Int64 = 0
    var countOfBytesClientExpectsToReceive: Int64 = 0
    func resume() {}
}