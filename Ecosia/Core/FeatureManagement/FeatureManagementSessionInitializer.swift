import Foundation

public protocol FeatureManagementSessionInitializer {

    func startSession<T: Decodable>() async throws -> T?
}
