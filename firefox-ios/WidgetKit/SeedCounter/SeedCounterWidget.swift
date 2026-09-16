// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

#if canImport(WidgetKit)
import SwiftUI
import WidgetKit

struct SeedCounterWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: SeedCounterWidgetKind, provider: SeedCounterProvider()) { entry in
            SeedCounterEntryView(entry: entry)
        }
        .contentMarginsDisabled()
        .supportedFamilies([.systemSmall])
        .configurationDisplayName(String.SeedCounterWidgetTitle)
        .description(String.SeedCounterWidgetDescription)
    }
}

// MARK: - Localized strings

extension String {
    static let SeedCounterWidgetTitle = NSLocalizedString(
        "Widget.SeedCounter.Title",
        tableName: "Localizable",
        value: "Your seeds",
        comment: "Display name for the seed counter home screen widget shown in the widget gallery."
    )

    static let SeedCounterWidgetDescription = NSLocalizedString(
        "Widget.SeedCounter.Description",
        tableName: "Localizable",
        value: "See your seed collection and progress to the next level.",
        comment: "Description for the seed counter home screen widget shown in the widget gallery."
    )
}
#endif
