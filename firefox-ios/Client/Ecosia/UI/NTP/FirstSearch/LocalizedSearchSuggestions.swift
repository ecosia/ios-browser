// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

/// Utility for providing region and language specific search suggestions
struct LocalizedSearchSuggestions {

    /// Represents a region and language combination
    enum RegionLanguage {
        case franceFrench
        case franceEnglish
        case germanyGerman
        case germanyEnglish
        case ukEnglish
        case usEnglish
        case `default`

        private static let localeMapping: [String: RegionLanguage] = [
            "fr_FR": .franceFrench,
            "en_FR": .franceEnglish,
            "de_DE": .germanyGerman,
            "en_DE": .germanyEnglish,
            "en_GB": .ukEnglish,
            "en_US": .usEnglish
        ]

        static func current() -> RegionLanguage {
            return from(locale: Locale.current)
        }

        static func from(locale: Locale) -> RegionLanguage {
            let identifier = locale.identifier
            return localeMapping[identifier] ?? .default
        }
    }

    /// Returns localized search suggestions based on the user's region and language
    static func suggestions(for regionLanguage: RegionLanguage = .current()) -> [String] {
        switch regionLanguage {
        case .franceFrench:
            return [
                "Météo Toulouse",
                "Notre-Dame de Paris",
                "Quelle est la hauteur de la tour Eiffel ?",
                "\"Bonne journée\" en espagnol",
                "Activités à Marseille"
            ]
        case .franceEnglish:
            return [
                "Weather in Toulouse",
                "Notre-Dame of Paris",
                "What is the height of the Eiffel Tower?",
                "\"Have a nice day\" in Spanish",
                "Things to do in Marseille"
            ]
        case .germanyGerman:
            return [
                "Wetter Berlin",
                "Neuschwanstein",
                "Wie hoch ist der Berliner Fernsehturm?",
                "\"Hab einen schönen Tag\" auf Spanisch",
                "Aktivitäten in München"
            ]
        case .germanyEnglish:
            return [
                "Weather in Berlin",
                "Neuschwanstein Castle",
                "How tall is the Berlin TV Tower?",
                "\"Have a nice day\" in Spanish",
                "Things to do in Munich",
            ]
        case .ukEnglish:
            return [
                "Weather in London",
                "Palace of Westminster",
                "How to see the Northern Lights?",
                "\"Have a nice day\" in Spanish",
                "Things to do in London"
            ]
        case .usEnglish:
            return [
                "New York City",
                "Things to do in Miami",
                "Weather in San Francisco",
                "How long is the Rio Grande?",
                "\"Have a nice day\" in Spanish"
            ]
        case .default:
            return [
                "Time in New York",
                "Climate change",
                "How to see the Northern Lights?",
                "Solar System",
                "100 USD to EUR"
            ]
        }
    }
}
