// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// Swift Concurrency-safe publisher protocol with @MainActor isolation
/// Follows Swift Concurrency Agent Skill best practices for safe concurrent publishing
@MainActor
public protocol Publisher: AnyObject {
    associatedtype Input: Sendable
    var subscriptions: [Subscription<Input>] { get set }
}

@MainActor
public extension Publisher {
    func send(_ input: Input) {
        subscriptions.removeAll { $0.subscriber == nil }
        subscriptions.forEach { $0.closure(input) }
    }

    func subscribe(_ subscriber: AnyObject, closure: @escaping @Sendable (Input) -> Void) {
        guard !subscriptions.contains(where: { $0.subscriber === subscriber }) else { return }
        subscriptions.append(.init(subscriber: subscriber, closure: closure))
    }

    func unsubscribe(_ subscriber: AnyObject) {
        subscriptions.removeAll { $0.subscriber === subscriber }
    }
}

public struct Subscription<Input: Sendable>: @unchecked Sendable {
    weak var subscriber: AnyObject?
    let closure: @Sendable (Input) -> Void
}

@MainActor
public protocol StatePublisher: Publisher {
    var state: Input? { get }
}

@MainActor
public extension StatePublisher {
    func subscribeAndReceive(_ subscriber: AnyObject, closure: @escaping @Sendable (Input) -> Void) {
        subscribe(subscriber, closure: closure)
        state.map(closure)
    }
}
