// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// Swift Concurrency-safe image loader with @MainActor isolation
/// Follows Swift Concurrency Agent Skill best practices for async image loading
@MainActor
public final class Images: Publisher {
    public var subscriptions = [Subscription<Item>]()
    private var items = Set<Item>()
    private let session: URLSession
    private var activeTasks: [URL: Task<Void, Never>] = [:]

    public init(_ session: URLSession) {
        self.session = session
    }

    public func load(_ subscriber: AnyObject, url: URL, closure: @escaping @Sendable (Input) -> Void) {
        subscribe(subscriber, closure: closure)
        guard let item = items.first(where: { $0.url == url })
        else {
            download(url)
            return
        }
        send(item)
    }

    public func cancellAll() {
        activeTasks.values.forEach { $0.cancel() }
        activeTasks.removeAll()
        session.getAllTasks { tasks in
            tasks.forEach { $0.cancel() }
        }
    }

    public func cancel(_ url: URL) {
        activeTasks[url]?.cancel()
        activeTasks.removeValue(forKey: url)
        session.getAllTasks { tasks in
            tasks.first { $0.originalRequest?.url == url }?.cancel()
        }
    }

    private func download(_ url: URL) {
        // Cancel any existing task for this URL
        activeTasks[url]?.cancel()

        // Create new download task
        let task = Task { @MainActor in
            do {
                let (data, _) = try await session.data(from: url)
                let item = Item(url, data)
                self.send(item)
                self.items.insert(item)
                self.activeTasks.removeValue(forKey: url)
            } catch {
                // Download failed or was cancelled
                self.activeTasks.removeValue(forKey: url)
            }
        }

        activeTasks[url] = task
    }

    public struct Item: Hashable, Sendable {
        public let url: URL
        public let data: Data

        init(_ url: URL, _ data: Data) {
            self.url = url
            self.data = data
        }

        public func hash(into hasher: inout Hasher) {
            hasher.combine(url)
        }

        public static func == (lhs: Self, rhs: Self) -> Bool {
            lhs.url == rhs.url
        }
    }
}
