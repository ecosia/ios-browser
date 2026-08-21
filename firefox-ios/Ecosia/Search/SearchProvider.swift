// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// Selectable search providers. The raw value is the engine identifier used by the
/// Unleash payload, `User.selectedSearchEngineID`, analytics, and icon lookup.
public enum SearchProvider: String, Codable, CaseIterable, Sendable {
    case ecosia
    case google
    case duckduckgo
    case chatgpt
    case perplexity
}
