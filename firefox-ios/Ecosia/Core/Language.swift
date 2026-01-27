// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

public enum Language: String, Codable, CaseIterable, Sendable {
    case
    de,
    en,
    es,
    it,
    fr,
    nl,
    sv

    /// Thread-safe access to current language
    /// Note: Since Language is Sendable (simple enum), direct static var access is safe
    /// The actor provides thread-safe access for mutable state
    public static var current: Language {
        get { LanguageManager.shared.unsafeCurrent }
        set { LanguageManager.shared.unsafeCurrent = newValue }
    }

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

/// Thread-safe language manager
/// Note: Using a simple class with @unchecked Sendable since Language enum is Sendable
/// and we're replacing DispatchQueue pattern with simpler direct access
private final class LanguageManager: @unchecked Sendable {
    static let shared = LanguageManager()

    private let lock = NSLock()
    private var _current: Language

    init() {
        self._current = Language.make(for: .current)
    }

    var unsafeCurrent: Language {
        get {
            lock.lock()
            defer { lock.unlock() }
            return _current
        }
        set {
            lock.lock()
            defer { lock.unlock() }
            _current = newValue
        }
    }
}

private extension Locale {
    var withLanguage: Ecosia.Language? {
        languageCode.flatMap {
            Ecosia.Language(rawValue: $0.lowercased())
        }
    }
}
