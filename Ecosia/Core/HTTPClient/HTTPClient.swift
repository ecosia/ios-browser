import Foundation

public protocol HTTPClient {

    typealias Result = (Data, HTTPURLResponse?)

    func perform(_ request: BaseRequest) async throws -> Result
}
