import Foundation

public final class Favourites {
    public var items = [Page]() {
        didSet {
            PageStore.save(favourites: items)
        }
    }

    public init() {
        items = PageStore.favourites
    }
}
