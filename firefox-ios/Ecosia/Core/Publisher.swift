// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// Publisher protocol for thread-safe UI updates
/// Based on [Swift Concurrency Agent Skill](https://github.com/AvdLee/Swift-Concurrency-Agent-Skill) MainActor patterns
public protocol Publisher: AnyObject {
    associatedtype Input: Sendable
    @MainActor var subscriptions: [Subscription<Input>] { get set }
}

public extension Publisher {
    @MainActor func send(_ input: Input) {
        subscriptions.removeAll { $0.subscriber == nil }
        subscriptions.forEach { $0.closure(input) }
    }

    @MainActor func subscribe(_ subscriber: AnyObject, closure: @escaping @Sendable (Input) -> Void) {
        guard !subscriptions.contains(where: { $0.subscriber === subscriber }) else { return }
        subscriptions.append(.init(subscriber: subscriber, closure: closure))
    }

    @MainActor func unsubscribe(_ subscriber: AnyObject) {
        subscriptions.removeAll { $0.subscriber === subscriber }
    }
}

public struct Subscription<Input: Sendable>: @unchecked Sendable {
    weak var subscriber: AnyObject?
    let closure: @Sendable (Input) -> Void
}

public protocol StatePublisher: Publisher {
    @MainActor var state: Input? { get }
}

public extension StatePublisher {
    @MainActor func subscribeAndReceive(_ subscriber: AnyObject, closure: @escaping @Sendable (Input) -> Void) {
        subscribe(subscriber, closure: closure)
        state.map(closure)
    }
}
