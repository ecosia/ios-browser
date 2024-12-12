import Foundation

public final class History {
    public var items: [(Date, Page)] {
        get { dictionary.sorted { $0.0 < $1.0 }.map { ($0.0, $0.1) } }
        set { dictionary = .init(uniqueKeysWithValues: newValue) }
    }

    private(set) var dictionary = [Date: Page]() {
        didSet {
            PageStore.save(history: dictionary)
        }
    }

    public init() {
        dictionary = PageStore.history
    }

    public func add(_ page: Page) {
        dictionary[Date()] = page
    }

    public func delete(_ at: Date) {
        dictionary.removeValue(forKey: at)
    }

    public func deleteAll() {
        dictionary = [:]
    }
}
