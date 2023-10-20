// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

#if canImport(WidgetKit)
import SwiftUI
import WidgetKit

struct QuickLinkWithCounterIntentProvider: IntentTimelineProvider {
    typealias Intent = QuickActionIntent
    typealias Entry = QuickLinkWithCounterEntry

    func getSnapshot(for configuration: QuickActionIntent, in context: Context, completion: @escaping (QuickLinkWithCounterEntry) -> Void) {
        let widgetKitInfoModel = WidgetKitInfoModel.get()
        let entry = QuickLinkWithCounterEntry(date: Date(), link: .search, infoModel: widgetKitInfoModel)
        completion(entry)
    }

    func getTimeline(for configuration: QuickActionIntent, in context: Context, completion: @escaping (Timeline<QuickLinkWithCounterEntry>) -> Void) {
        getSnapshot(for: configuration, in: context) { entry in
            let timeline = Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(7200)))
            completion(timeline)
        }
    }

    func placeholder(in context: Context) -> QuickLinkWithCounterEntry {
        return QuickLinkWithCounterEntry(date: Date(), link: .search, infoModel: WidgetKitInfoModel())
    }
}

struct QuickLinkWithCounterEntry: TimelineEntry {
    public let date: Date
    let link: QuickLink
    let infoModel: WidgetKitInfoModel
}

#endif
