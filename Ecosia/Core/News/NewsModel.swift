import Foundation

public struct NewsModel: Codable, Hashable {
    let id: Int
    public internal(set) var text: String
    public let language: Language
    public let publishDate: Date
    public let imageUrl: URL
    public let targetUrl: URL
    public let trackingName: String

    public func hash(into: inout Hasher) {
        into.combine(id)
    }

    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id
    }
}
