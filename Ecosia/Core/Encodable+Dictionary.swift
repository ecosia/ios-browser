import Foundation

extension Encodable {
    public var dictionary: [String: String] {
        (try? JSONSerialization.jsonObject(with: JSONEncoder().encode(self))).flatMap { $0 as? [String: String] } ?? [String: String]()
    }
}
