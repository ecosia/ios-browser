// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// Swift Concurrency-safe news manager with @MainActor isolation
/// Follows Swift Concurrency Agent Skill best practices for async data management
@MainActor
public final class News: StatePublisher {
    public var subscriptions = [Subscription<[NewsModel]>]()
    public var state: [NewsModel]? {
        items.sorted { $0.publishDate > $1.publishDate }
    }
    private let characters = ["&#39;": "'"]

    private var decoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }

    private(set) var items = Set<NewsModel>() {
        didSet {
            // Already on MainActor, no need for dispatch
            state.map { send($0) }
        }
    }

    public init() {
        // Initialize with async restoration
        Task {
            await restore()
        }
    }

    var needsUpdate: Bool {
        guard !items.isEmpty else { return true }
        return Calendar.current.dateComponents([.day], from: User.shared.news, to: .init()).day! >= 1
    }

    public func load(session: URLSession, force: Bool = false) {
        guard needsUpdate || force else { return }
        
        Task {
            do {
                let (data, _) = try await session.data(from: EcosiaEnvironment.current.urlProvider.notifications)
                
                guard let new = try? decoder.decode([NewsModel].self, from: data) else {
                    return
                }
                
                let cleaned = new.compactMap { clean($0) }
                items = Set(cleaned + Array(items))
                await save()
            } catch {
                // Load failed, ignore
            }
        }
    }

    private func restore() async {
        // Perform file I/O on background
        let fileURL = FileManager.news
        let currentLanguage = Language.current
        
        await Task.detached {
            guard let news = try? JSONDecoder().decode([NewsModel].self, from: Data(contentsOf: fileURL)) else {
                return []
            }
            return news.filter { $0.language == currentLanguage }
        }.value.map { newsItems in
            await MainActor.run {
                self.items = Set(newsItems)
            }
        }
    }

    private func save() async {
        guard !items.isEmpty else { return }
        
        let itemsToSave = items
        let fileURL = FileManager.news
        
        // Perform file I/O on background
        await Task.detached {
            do {
                try JSONEncoder().encode(itemsToSave).write(to: fileURL, options: .atomic)
                await MainActor.run {
                    User.shared.news = Date()
                }
            } catch {
                // Save failed, ignore
            }
        }.value
    }

    private func clean(_ item: NewsModel) -> NewsModel {
        var item = item
        item.text = item.text.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
        item.text = characters.reduce(item.text) { text, char in
            text.replacingOccurrences(of: char.0, with: char.1)
        }
        return item
    }
}
