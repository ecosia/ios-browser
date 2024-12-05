import Foundation

public final class URLSessionHTTPClient: HTTPClient {

    public init() {}

    public func perform(_ request: BaseRequest) async throws -> HTTPClient.Result {
        let (data, response) = try await URLSession.shared.data(for: request.makeURLRequest())
        return (data, response as? HTTPURLResponse)
    }
}
