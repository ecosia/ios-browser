// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Ecosia
import Foundation

/// Builds the AI destination for each provider and recognises those destinations again
/// when they come back through the omnibox submit pipeline.
///
/// Every third-party destination relies on a query parameter that submits the prompt
/// automatically. None of them are published API and any of them can change without
/// notice; each is marked below. Ecosia is the only provider whose destination is a
/// contract we control.
enum SearchProviderAIRouting {

    /// Google Search AI Mode. Community-documented, not official.
    private static let googleAIModeParameter = URLQueryItem(name: "udm", value: "50")

    /// Hosts that serve a provider's AI experience, used to recognise a destination we
    /// built. Derived from the catalog so the two cannot drift: a third party's upload
    /// redirect and its AI home are the same page. Google's plain results page is not
    /// included, since only its `udm` searches are AI.
    private static var aiHosts: Set<String> {
        Set(SearchProvider.allCases.compactMap { $0.fileUploadDestination?.host })
    }

    /// Where the AI entry point should send `query` for the given provider.
    ///
    /// Ecosia passes `mode` to the backend as query items; every other provider has no
    /// mode parameter, so the mode becomes an instruction appended to the prompt. A
    /// provider never gets both.
    static func aiDestinationURL(for provider: SearchProvider,
                                 query: String,
                                 origin: URLProvider.AIChatOrigin,
                                 mode: OmniboxChatMode? = nil) -> URL? {
        switch provider {
        case .ecosia:
            return Environment.current.urlProvider.aiChat(
                origin: origin,
                query: query,
                additionalQueryItems: mode?.aiChatQueryItems ?? []
            )
        case .google:
            return makeURL(host: "www.google.com", path: "/search", items: [
                URLQueryItem(name: "q", value: prompt(query, mode)),
                googleAIModeParameter
            ])
        case .duckduckgo:
            // `auto_submit=1` sends the prompt without a second tap.
            return makeURL(host: "duck.ai", path: "/", items: [
                URLQueryItem(name: "q", value: prompt(query, mode)),
                URLQueryItem(name: "auto_submit", value: "1")
            ])
        case .chatgpt:
            // `hints=search` opens the prompt in search mode and submits it.
            return makeURL(host: "chatgpt.com", path: "/", items: [
                URLQueryItem(name: "q", value: prompt(query, mode)),
                URLQueryItem(name: "hints", value: "search")
            ])
        case .perplexity:
            // Runs the query on load, no extra parameter needed.
            return makeURL(host: "www.perplexity.ai", path: "/search", items: [
                URLQueryItem(name: "q", value: prompt(query, mode))
            ])
        }
    }

    /// The provider's AI with no prompt. For third parties this is the same page their
    /// upload redirect points at; Ecosia's is AI Chat without a seeded query.
    private static func aiHomeURL(for provider: SearchProvider) -> URL? {
        guard provider != .ecosia else {
            return Environment.current.urlProvider.aiChat(origin: .omnibox)
        }
        return provider.fileUploadDestination
    }

    /// The mode carried as a prompt instruction, for providers with no mode parameter.
    private static func prompt(_ query: String, _ mode: OmniboxChatMode?) -> String {
        query + (mode?.promptSuffix ?? "")
    }

    /// Destination for the AI entry point itself, used when the entry point is a plain
    /// redirect. Falls back to the provider's AI home when there is nothing typed.
    static func aiEntryPointURL(for provider: SearchProvider, query: String?) -> URL? {
        guard let trimmed = query?.trimmingCharacters(in: .whitespacesAndNewlines),
              !trimmed.isEmpty
        else { return aiHomeURL(for: provider) }
        return aiDestinationURL(for: provider, query: trimmed, origin: .omnibox)
    }

    /// Whether `url` is already a finalized AI destination and must not be rebuilt as a
    /// plain search by the omnibox submit pipeline.
    static func isAIDestination(_ url: URL) -> Bool {
        if url.isEcosiaAIChat || isGoogleAIMode(url) { return true }
        guard let host = url.host else { return false }
        return aiHosts.contains(host)
    }

    // MARK: - Private

    private static func isGoogleAIMode(_ url: URL) -> Bool {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              components.host == "www.google.com",
              components.path == "/search" else { return false }
        return components.queryItems?.contains(googleAIModeParameter) == true
    }

    private static func makeURL(host: String, path: String, items: [URLQueryItem]) -> URL? {
        var components = URLComponents()
        components.scheme = "https"
        components.host = host
        components.path = path
        components.queryItems = items
        return components.url
    }
}
