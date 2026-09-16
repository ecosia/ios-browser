// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

#if canImport(WidgetKit)
import WidgetKit
import Foundation
import Common
import Shared

struct SeedCounterEntry: TimelineEntry {
    let date: Date
    let seedCount: Int
    /// 0…1, used to set the jar fill height.
    let levelProgress: Double
    let isSignedIn: Bool
}

extension SeedCounterEntry {
    /// Shown while WidgetKit renders the redacted placeholder in the gallery.
    static let placeholder = SeedCounterEntry(
        date: Date(),
        seedCount: 128,
        levelProgress: 0.35,
        isSignedIn: false
    )
}

struct SeedCounterProvider: TimelineProvider {
    typealias Entry = SeedCounterEntry

    private let sharedDefaults: UserDefaults? = UserDefaults(suiteName: AppInfo.sharedContainerIdentifier)

    func placeholder(in context: Context) -> SeedCounterEntry {
        .placeholder
    }

    func getSnapshot(in context: Context, completion: @escaping (SeedCounterEntry) -> Void) {
        completion(context.isPreview ? .placeholder : makeEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SeedCounterEntry>) -> Void) {
        let entry = makeEntry()
        // Seed state is push-driven (app calls WidgetCenter.reloadTimelines on every change).
        // The hourly safety refresh ensures the widget never stays stale if a reload was missed.
        let refreshDate = Calendar.current.date(byAdding: .hour, value: 1, to: entry.date) ?? entry.date
        completion(Timeline(entries: [entry], policy: .after(refreshDate)))
    }

    // MARK: - Private

    private func makeEntry() -> SeedCounterEntry {
        let snapshot = sharedDefaults.flatMap { SeedWidgetSnapshot.load(from: $0) }
        return SeedCounterEntry(
            date: snapshot?.updatedAt ?? Date(),
            seedCount: snapshot?.seedCount ?? 0,
            levelProgress: snapshot?.levelProgress ?? 0,
            isSignedIn: snapshot?.isSignedIn ?? false
        )
    }
}
#endif
