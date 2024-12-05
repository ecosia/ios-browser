import Foundation

public protocol Requestable {

    var method: HTTPMethod { get }

    var baseURL: URL { get }

    var path: String { get }

    var environment: Environment { get }

    var queryParameters: [String: String]? { get set }

    var additionalHeaders: [String: String]? { get }

    var body: Data? { get set }

    func makeURLRequest() throws -> URLRequest
}
