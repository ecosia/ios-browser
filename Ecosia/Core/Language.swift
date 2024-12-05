import Foundation

public enum Language: String, Codable, CaseIterable {
    case
    de,
    en,
    es,
    it,
    fr,
    nl,
    sv

    public internal(set) static var current = make(for: .current)

    var locale: Local {
        switch self {
        case .de: return .de_de
        case .en: return .en_us
        case .es: return .es_es
        case .it: return .it_it
        case .fr: return .fr_fr
        case .nl: return .nl_nl
        case .sv: return .sv_se
        }
    }

    static func make(for locale: Locale) -> Self {
        locale.withLanguage ?? .en
    }
}

private extension Locale {
    var withLanguage: Ecosia.Language? {
        languageCode.flatMap {
            Ecosia.Language(rawValue: $0.lowercased())
        }
    }
}
