// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import AppIntents
import Ecosia
import SwiftUI
import WidgetKit

@available(iOS 17.0, *)
struct PlanetPulseWidget: Widget {
    static let kind = "com.ecosia.widget.planet-pulse.v9"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: Self.kind,
            intent: PlanetPulseConfigurationIntent.self,
            provider: PlanetPulseTimelineProvider()
        ) { entry in
            PlanetPulseView(entry: entry)
        }
        .configurationDisplayName(String.localized(.planetPulseTitle))
        .description(String.localized(.planetPulseDescription))
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
