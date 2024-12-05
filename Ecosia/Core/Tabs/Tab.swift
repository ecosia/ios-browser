import Foundation

public struct Tab: Codable, Identifiable {
    public var page: Page?
    public let id: UUID

    public init(page: Page?) {
        self.page = page
        id = .init()
    }
}

public extension Tab {
    var snapshot: Data? {
        return try? Data(contentsOf: FileManager.snapshots.appendingPathComponent(id.uuidString))
    }
}
