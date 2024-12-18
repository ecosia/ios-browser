@testable import Ecosia
import Foundation

class HTTPClientMock: HTTPClient {

    var requests: [BaseRequest] = []
    var response: HTTPURLResponse?
    var data = Data()
    var executeBeforeResponse: (() -> Void)?

    func perform(_ request: BaseRequest) async throws -> (Data, HTTPURLResponse?) {
        requests.append(request)
        executeBeforeResponse?()
        return (data, response)
    }
}
