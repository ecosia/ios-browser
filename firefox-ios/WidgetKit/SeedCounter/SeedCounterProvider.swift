// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

#if canImport(WidgetKit)
import WidgetKit
import Foundation
import UIKit
import Common
import Shared

struct SeedCounterEntry: TimelineEntry {
    let date: Date
    let seedCount: Int
    /// 0…1, used to set the jar fill height and the progress bar width.
    let levelProgress: Double
    let isSignedIn: Bool
    /// 1-based level number. Only meaningful when signed in.
    let currentLevel: Int
    /// Localized level names resolved app-side, ordered by level; index 0 is level 1.
    let levelNames: [String]
    let growthPointsRemaining: Int
    /// The account avatar, or `nil` when there is none to draw.
    let avatarImage: UIImage?
    /// Drives the redacted state WidgetKit shows before any data is available.
    let isPlaceholder: Bool

    init(
        date: Date,
        seedCount: Int,
        levelProgress: Double,
        isSignedIn: Bool,
        currentLevel: Int = 1,
        levelNames: [String] = [],
        growthPointsRemaining: Int = 0,
        avatarImage: UIImage? = nil,
        isPlaceholder: Bool = false
    ) {
        self.date = date
        self.seedCount = seedCount
        self.levelProgress = levelProgress
        self.isSignedIn = isSignedIn
        self.currentLevel = currentLevel
        self.levelNames = levelNames
        self.growthPointsRemaining = growthPointsRemaining
        self.avatarImage = avatarImage
        self.isPlaceholder = isPlaceholder
    }
}

extension SeedCounterEntry {
    /// The redacted skeleton WidgetKit renders before the widget has data: em dash for the
    /// count, a placeholder capsule, fill 0.35 and skeleton badges. No data access.
    static let placeholder = SeedCounterEntry(
        date: Date(),
        seedCount: 0,
        levelProgress: 0.35,
        isSignedIn: true,
        isPlaceholder: true
    )

    /// Representative state shown in the widget gallery when the app has not written a snapshot
    /// yet. Its level names are sample data and deliberately not localized — a real entry is
    /// preferred whenever one exists.
    static let galleryPreview = SeedCounterEntry(
        date: Date(),
        seedCount: 128,
        levelProgress: 0.62,
        isSignedIn: true,
        currentLevel: 3,
        levelNames: SeedCounterEntry.previewLevelNames,
        growthPointsRemaining: 37
    )

    private static let previewLevelNames = [
        "Ecocurious", "Green explorer", "Planet pal", "Seedling supporter",
        "Biodiversity bestie", "Forest friend", "Wildlife protector", "Eco explorer"
    ]
}

struct SeedCounterProvider: TimelineProvider {
    typealias Entry = SeedCounterEntry

    private let sharedDefaults: UserDefaults? = UserDefaults(suiteName: AppInfo.sharedContainerIdentifier)

    func placeholder(in context: Context) -> SeedCounterEntry {
        .placeholder
    }

    func getSnapshot(in context: Context, completion: @escaping (SeedCounterEntry) -> Void) {
        let entry = makeEntry()
        // In the gallery, prefer the user's own state — it carries the localized level names.
        // The sample entry only stands in before the app has ever written a snapshot.
        completion(context.isPreview && entry.levelNames.isEmpty ? .galleryPreview : entry)
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
            isSignedIn: snapshot?.isSignedIn ?? false,
            currentLevel: snapshot?.currentLevel ?? 1,
            levelNames: snapshot?.levelNames ?? [],
            growthPointsRemaining: snapshot?.growthPointsRemaining ?? 0,
            avatarImage: snapshot.flatMap(loadAvatar)
        )
    }

    private func loadAvatar(for snapshot: SeedWidgetSnapshot) -> UIImage? {
        guard let url = snapshot.avatarFileURL(appGroupIdentifier: AppInfo.sharedContainerIdentifier) else {
            return nil
        }
        return UIImage(contentsOfFile: url.path)
    }
}
#endif
