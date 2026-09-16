// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Ecosia
import Foundation
import WidgetKit

@available(iOS 17.0, *)
struct PlanetPulseEntry: TimelineEntry {
    let date: Date
    let mode: PlanetPulseWidgetMode
    let appearance: PlanetPulseWidgetAppearance
    let card: PlanetPulseCard
    let destinationURL: URL?

    static var preview: PlanetPulseEntry {
        let card = PlanetPulseContent.fallbackAction
        let destinationURL = try? PlanetPulseURLBuilder(scheme: "ecosia").url(for: card.destination)
        return PlanetPulseEntry(
            date: Date(),
            mode: .smallAction,
            appearance: .ecosiaClassic,
            card: card,
            destinationURL: destinationURL
        )
    }
}
