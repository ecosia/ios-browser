// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// Routes omnibox and autocomplete AI actions to Google Gemini when Google is the
/// active default search provider.
enum GeminiSearchRouting {

    private static let aiModeParameter = URLQueryItem(name: "udm", value: "50")

    /// Google Search AI Mode URL for a prefilled query (`udm=50`).
    static func aiModeSearchURL(query: String) -> URL {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "www.google.com"
        components.path = "/search"
        components.queryItems = [
            URLQueryItem(name: "q", value: query),
            aiModeParameter
        ]
        return components.url ?? geminiAppURL
    }

    /// Gemini web app entry point (no prefilled query support).
    static let geminiAppURL = URL(string: "https://gemini.google.com/app")!

    /// Whether `url` is a finalized Google Gemini destination that must not be
    /// rebuilt through the omnibox submit pipeline.
    static func isAIDestination(_ url: URL) -> Bool {
        if url == geminiAppURL { return true }
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              components.host == "www.google.com",
              components.path == "/search" else {
            return false
        }
        return components.queryItems?.contains { $0.name == aiModeParameter.name && $0.value == aiModeParameter.value } == true
    }
}
