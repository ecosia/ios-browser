import Foundation
@testable import Core

// Needed in spite of the already existing MockURLSession
// since URLSession's async methods are not open
class MockURLSessionProtocol: URLSessionProtocol {
    var data: Data?

    func data(from url: URL) async throws -> (Data, URLResponse) {
        let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)!
        return (data!, response)
    }
}
