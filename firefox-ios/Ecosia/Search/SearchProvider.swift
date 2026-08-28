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
    case bing
    case chatgpt
    case perplexity
}

public extension SearchProvider {

    /// Brand name, shown in Settings and in the file upload redirect. Not localized.
    var displayName: String {
        switch self {
        case .ecosia: return "Ecosia"
        case .google: return "Google"
        case .duckduckgo: return "DuckDuckGo"
        case .bing: return "Bing"
        case .chatgpt: return "ChatGPT"
        case .perplexity: return "Perplexity"
        }
    }

    /// Brand of the provider's AI surface, which is not always the provider's own name.
    var aiDisplayName: String {
        switch self {
        case .google: return "Gemini"
        case .bing: return "Copilot"
        case .ecosia, .duckduckgo, .chatgpt, .perplexity: return displayName
        }
    }

    /// Providers whose results page is already a conversation, so there is no separate
    /// AI entry point to offer.
    var isAINative: Bool {
        switch self {
        case .chatgpt, .perplexity: return true
        case .ecosia, .google, .duckduckgo, .bing: return false
        }
    }

    /// OpenSearch template for the results page.
    var searchTemplate: String {
        switch self {
        case .ecosia:
            return "\(Environment.current.urlProvider.root.absoluteString)/search?q={searchTerms}"
        case .google:
            return "https://www.google.com/search?q={searchTerms}"
        case .duckduckgo:
            return "https://duckduckgo.com/?q={searchTerms}"
        case .bing:
            return "https://www.bing.com/search?q={searchTerms}"
        case .chatgpt:
            return "https://chatgpt.com/?q={searchTerms}&hints=search"
        case .perplexity:
            return "https://www.perplexity.ai/search?q={searchTerms}"
        }
    }

    /// Autocomplete endpoint, or `nil` when the provider has none.
    var suggestTemplate: String? {
        switch self {
        case .ecosia:
            let autocomplete = Environment.current.urlProvider.searchAutocomplete.absoluteString
            return "\(autocomplete)?q={searchTerms}&type=list"
        case .google:
            return "https://suggestqueries.google.com/complete/search?client=firefox&channel=tr&q={searchTerms}"
        case .duckduckgo:
            return "https://duckduckgo.com/ac/?q={searchTerms}&type=list"
        case .bing:
            return "https://www.bing.com/osjson.aspx?query={searchTerms}"
        case .chatgpt, .perplexity:
            return nil
        }
    }

    /// Where to send users who want to upload files. `nil` for Ecosia, which uploads
    /// in-app. Google points at Gemini and Bing at Copilot rather than at search.
    var fileUploadDestination: URL? {
        switch self {
        case .ecosia: return nil
        case .google: return URL(string: "https://gemini.google.com/app")
        case .duckduckgo: return URL(string: "https://duck.ai")
        case .bing: return URL(string: "https://copilot.microsoft.com")
        case .chatgpt: return URL(string: "https://chatgpt.com")
        case .perplexity: return URL(string: "https://www.perplexity.ai")
        }
    }
}
