// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Ecosia
import Foundation
import WidgetKit

@available(iOS 17.0, *)
struct PlanetPulseTimelineProvider: AppIntentTimelineProvider {
#if DEBUG
    private static let demoEntryCount = 8
    private static let demoEntryInterval: TimeInterval = 8
#endif

    private let selector: PlanetPulseSelector
    private let urlBuilder: PlanetPulseURLBuilder

    init(
        selector: PlanetPulseSelector = PlanetPulseSelector(),
        urlBuilder: PlanetPulseURLBuilder = PlanetPulseURLBuilder(scheme: scheme)
    ) {
        self.selector = selector
        self.urlBuilder = urlBuilder
    }

    func placeholder(in context: Context) -> PlanetPulseEntry {
        .preview
    }

    // AppIntentTimelineProvider requires async even though bundled content needs no suspension.
    // swiftlint:disable:next async_without_await
    func snapshot(
        for configuration: PlanetPulseConfigurationIntent,
        in context: Context
    ) async -> PlanetPulseEntry {
        return entry(
            for: configuration,
            at: Date(),
            appearanceOverride: context.isPreview ? .ecosiaClassic : nil
        )
    }

    // AppIntentTimelineProvider requires async even though bundled content needs no suspension.
    // swiftlint:disable:next async_without_await
    func timeline(
        for configuration: PlanetPulseConfigurationIntent,
        in context: Context
    ) async -> Timeline<PlanetPulseEntry> {
        let now = Date()
#if DEBUG
        return demoTimeline(for: configuration, from: now)
#else
        let nextDay = selector.startOfNextDay(after: now)
        return Timeline(
            entries: [
                entry(for: configuration, at: now),
                entry(for: configuration, at: nextDay)
            ],
            policy: .after(nextDay)
        )
#endif
    }

    private func entry(
        for configuration: PlanetPulseConfigurationIntent,
        at date: Date,
        contentDate: Date? = nil,
        appearanceOverride: PlanetPulseWidgetAppearance? = nil
    ) -> PlanetPulseEntry {
        let widgetMode = PlanetPulseWidgetMode(
            rawValue: configuration.mode ?? ""
        ) ?? .smallAction
        let configuredAppearance = PlanetPulseWidgetAppearance(
            rawValue: configuration.appearance ?? ""
        ) ?? .ecosiaClassic
        let appearance = appearanceOverride ?? configuredAppearance
        let mode = widgetMode.planetPulseMode
        let card = selector.card(
            for: mode,
            at: contentDate ?? date,
            from: PlanetPulseContent.cards
        )
        return PlanetPulseEntry(
            date: date,
            mode: widgetMode,
            appearance: appearance,
            card: card,
            destinationURL: try? urlBuilder.url(for: card.destination)
        )
    }

#if DEBUG
    private func demoTimeline(
        for configuration: PlanetPulseConfigurationIntent,
        from date: Date
    ) -> Timeline<PlanetPulseEntry> {
        let entries = (0..<Self.demoEntryCount).map { index in
            let interval = Self.demoEntryInterval * Double(index)
            let entryDate = date.addingTimeInterval(interval)
            let contentDate = Calendar.current.date(
                byAdding: .day,
                value: index,
                to: date
            ) ?? date
            return entry(
                for: configuration,
                at: entryDate,
                contentDate: contentDate
            )
        }
        return Timeline(entries: entries, policy: .atEnd)
    }
#endif
}

@available(iOS 17.0, *)
private extension PlanetPulseWidgetMode {
    var planetPulseMode: PlanetPulseMode {
        switch self {
        case .smallAction:
            return .smallAction
        case .stayInformed:
            return .stayInformed
        case .mixed:
            return .mixed
        }
    }
}
