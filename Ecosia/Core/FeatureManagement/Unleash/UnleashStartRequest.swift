import Foundation

public struct UnleashStartRequest: BaseRequest {

    public var method: HTTPMethod {
        .get
    }

    public var path: String {
        "/v2/toggles"
    }

    var etag: String

    public var queryParameters: [String: String]?

    public var additionalHeaders: [String: String]? {
        ["If-None-Match": etag]
    }

    public var body: Data?
}
