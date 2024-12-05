import Foundation

public final class SearchesCounter: StatePublisher {
    public var subscriptions = [Subscription<Int>]()
    public var state: Int? {
        return User.shared.searchCount
    }

    public init() {
        NotificationCenter.default.addObserver(self, selector: #selector(searchesCounterChanged), name: .searchesCounterChanged, object: nil)
    }

    @objc private func searchesCounterChanged() {
        send(state!)
    }
}
