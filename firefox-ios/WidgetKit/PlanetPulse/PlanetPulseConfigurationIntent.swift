// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import AppIntents
import Ecosia

@available(iOS 17.0, *)
enum PlanetPulseWidgetMode: String, CaseIterable, Sendable {
    case smallAction = "Take a small action"
    case stayInformed = "Stay informed"
    case mixed = "A bit of both"

    var title: LocalizedStringResource {
        switch self {
        case .smallAction:
            return LocalizedStringResource(
                "Take a small action",
                table: "Ecosia",
                bundle: Bundle.ecosia
            )
        case .stayInformed:
            return LocalizedStringResource(
                "Stay informed",
                table: "Ecosia",
                bundle: Bundle.ecosia
            )
        case .mixed:
            return LocalizedStringResource(
                "A bit of both",
                table: "Ecosia",
                bundle: Bundle.ecosia
            )
        }
    }
}

@available(iOS 17.0, *)
enum PlanetPulseWidgetAppearance: String, CaseIterable, Sendable {
    case ecosiaClassic = "Ecosia Classic"
    case planetMix = "Planet Mix"
    case forest = "Forest"
    case ocean = "Ocean"
    case sunrise = "Sunrise"
    case meadow = "Pastel Meadow"
    case lavender = "Lavender Haze"
    case softSky = "Soft Sky"

    var title: LocalizedStringResource {
        switch self {
        case .planetMix:
            return localizedTitle("Planet Mix")
        case .ecosiaClassic:
            return localizedTitle("Ecosia Classic")
        case .forest:
            return localizedTitle("Forest")
        case .ocean:
            return localizedTitle("Ocean")
        case .sunrise:
            return localizedTitle("Sunrise")
        case .meadow:
            return localizedTitle("Pastel Meadow")
        case .lavender:
            return localizedTitle("Lavender Haze")
        case .softSky:
            return localizedTitle("Soft Sky")
        }
    }

    private func localizedTitle(_ value: String.LocalizationValue) -> LocalizedStringResource {
        LocalizedStringResource(
            value,
            table: "Ecosia",
            bundle: Bundle.ecosia
        )
    }
}

@available(iOS 17.0, *)
struct PlanetPulseModeOptionsProvider: DynamicOptionsProvider {
    // DynamicOptionsProvider requires async even though these options are local.
    // swiftlint:disable:next async_without_await
    func results() async throws -> ItemCollection<String> {
        ItemCollection(sections: [
            IntentItemSection(
                items: PlanetPulseWidgetMode.allCases.map {
                    IntentItem($0.rawValue, title: $0.title)
                }
            )
        ])
    }

    // DynamicOptionsProvider requires async even though the default is local.
    // swiftlint:disable:next async_without_await
    func defaultResult() async -> String? {
        PlanetPulseWidgetMode.smallAction.rawValue
    }
}

@available(iOS 17.0, *)
struct PlanetPulseAppearanceOptionsProvider: DynamicOptionsProvider {
    // DynamicOptionsProvider requires async even though these options are local.
    // swiftlint:disable:next async_without_await
    func results() async throws -> ItemCollection<String> {
        ItemCollection(sections: [
            IntentItemSection(
                items: PlanetPulseWidgetAppearance.allCases.map {
                    IntentItem($0.rawValue, title: $0.title)
                }
            )
        ])
    }

    // DynamicOptionsProvider requires async even though the default is local.
    // swiftlint:disable:next async_without_await
    func defaultResult() async -> String? {
        PlanetPulseWidgetAppearance.ecosiaClassic.rawValue
    }
}

@available(iOS 17.0, *)
struct PlanetPulseConfigurationIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource {
        LocalizedStringResource(
            "Planet Pulse",
            table: "Ecosia",
            bundle: Bundle.ecosia
        )
    }

    static var description: IntentDescription {
        IntentDescription(
            LocalizedStringResource(
                "Choose what Planet Pulse shows.",
                table: "Ecosia",
                bundle: Bundle.ecosia
            )
        )
    }

    @Parameter(
        title: LocalizedStringResource(
            "Show",
            table: "Ecosia",
            bundle: Bundle.ecosia
        ),
        optionsProvider: PlanetPulseModeOptionsProvider()
    )
    var mode: String?

    @Parameter(
        title: LocalizedStringResource(
            "Appearance",
            table: "Ecosia",
            bundle: Bundle.ecosia
        ),
        optionsProvider: PlanetPulseAppearanceOptionsProvider()
    )
    var appearance: String?
}
