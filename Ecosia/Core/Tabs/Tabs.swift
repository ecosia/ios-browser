// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// Swift Concurrency-safe tabs manager with async file operations
@MainActor
public final class Tabs {
    public var current: Int? {
        didSet {
            Task {
                await PageStore.save(currentTab: current)
            }
        }
    }

    public private(set) var items = [Tab]() {
        didSet {
            Task {
                await PageStore.save(tabs: items)
            }
        }
    }

    public init() {
        items = PageStore.tabs
        if let current = PageStore.currentTab {
            self.current = current < items.count ? current : nil
        }
    }

    public func new(_ url: URL?) {
        var items = self.items
        items.removeAll { $0.page == nil }
        let new = Tab(page: url.map { .init(url: $0, title: "") })
        current = items.count
        items.append(new)
        self.items = items
    }

    public func close(_ id: UUID) {
        guard let index = items.firstIndex(where: { $0.id == id }) else { return }
        if current != nil {
            if current == index {
                current = nil
            } else if index < current! {
                current = current! - 1
            }
        }
        deleteSnapshot(items[index].id)
        items.remove(at: index)
    }

    public func clear() {
        items = []
        current = nil

        Task.detached {
            if FileManager.default.fileExists(atPath: FileManager.snapshots.path) {
                try? FileManager.default.removeItem(at: FileManager.snapshots)
            }
        }
    }

    public func update(_ tab: UUID, page: Page) {
        items.firstIndex { $0.id == tab }.map {
            items[$0].page = page
        }
    }

    public func page(_ tab: UUID) -> Page? {
        items.first { $0.id == tab }?.page
    }

    public func image(_ id: UUID) async -> Data? {
        await Task.detached {
            try? Data(contentsOf: FileManager.snapshots.appendingPathComponent(id.uuidString))
        }.value
    }

    public func image(_ id: UUID, completion: @escaping @Sendable (Data?) -> Void) {
        Task {
            let data = await image(id)
            await MainActor.run {
                completion(data)
            }
        }
    }

    public func save(_ image: Data, with id: UUID) {
        Task.detached {
            let snapshotsURL = FileManager.snapshots
            if !FileManager.default.fileExists(atPath: snapshotsURL.path) {
                var url = snapshotsURL
                var resources = URLResourceValues()
                resources.isExcludedFromBackup = true
                try? url.setResourceValues(resources)
                try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
            }
            try? image.write(to: snapshotsURL.appendingPathComponent(id.uuidString), options: .atomic)
        }
    }

    func deleteSnapshot(_ id: UUID) {
        Task.detached {
            let fileURL = FileManager.snapshots.appendingPathComponent(id.uuidString)
            if FileManager.default.fileExists(atPath: fileURL.path) {
                try? FileManager.default.removeItem(at: fileURL)
            }
        }
    }
}
