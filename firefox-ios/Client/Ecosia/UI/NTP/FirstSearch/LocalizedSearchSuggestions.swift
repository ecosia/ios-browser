// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

/// Utility for providing region and language specific search suggestions
struct LocalizedSearchSuggestions {

    /// Represents a region and language combination
    enum RegionLanguage {
        case franceFrench
        case germanyGerman
        case ukEnglish
        case usEnglish
        case `default`

        static func current() -> RegionLanguage {
            return from(locale: Locale.current)
        }

        static func from(locale: Locale) -> RegionLanguage {
            let languageCode = locale.languageIdentifier ?? ""
            let regionCode = locale.regionIdentifier ?? ""

            switch (languageCode, regionCode) {
            case ("fr", "FR"):
                return .franceFrench
            case ("de", "DE"):
                return .germanyGerman
            case ("en", "GB"):
                return .ukEnglish
            case ("en", "US"):
                return .usEnglish
            default:
                return .default
            }
        }
    }

    /// Returns localized search suggestions based on the user's region and language
    static func suggestions(for regionLanguage: RegionLanguage = .current()) -> [String] {
        switch regionLanguage {
        case .franceFrench:
            return [
                "Météo Toulouse",
                "Quelle est la hauteur de la tour Eiffel ?",
                "Notre-Dame de Paris",
                "\"Bonne journée\" en espagnol",
                "Activités à Marseille"
            ]
        case .germanyGerman:
            return [
                "Wetter Berlin",
                "Wie hoch ist der Berliner Fernsehturm?",
                "Neuschwanstein",
                "\"Hab einen schönen Tag\" auf Spanisch",
                "Aktivitäten in München"
            ]
        case .ukEnglish:
            return [
                "Weather in London",
                "How to see the Northern Lights?",
                "Palace of Westminster",
                "\"Have a nice day\" in Spanish",
                "Things to do in London"
            ]
        case .usEnglish:
            return [
                "Weather in San francisco",
                "How long is the Rio Grande",
                "New York City",
                "Things to do in Miami",
                "\"Have a nice day\" in Spanish"
            ]
        case .default:
            return [
                "Time in New York",
                "Climate change"
            ]
        }
    }
}
