// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

public enum PlanetPulseURLBuilderError: Error, Equatable {
    case invalidScheme
    case emptySearchQuery
    case invalidArticleURL
    case unableToBuildURL
}

public struct PlanetPulseURLBuilder: Sendable {
    private let scheme: String
    private let urlProvider: URLProvider

    public init(scheme: String, urlProvider: URLProvider = .production) {
        self.scheme = scheme
        self.urlProvider = urlProvider
    }

    public func url(for destination: PlanetPulseDestination) throws -> URL {
        guard isValidScheme else {
            throw PlanetPulseURLBuilderError.invalidScheme
        }

        switch destination {
        case .search(let query):
            return try searchURL(query: query)
        case .article(let url):
            return try articleURL(url)
        }
    }

    private var isValidScheme: Bool {
        guard let firstCharacter = scheme.first, firstCharacter.isLetter else { return false }
        let allowedCharacters = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "+-."))
        return scheme.unicodeScalars.allSatisfy(allowedCharacters.contains)
    }

    private func searchURL(query: String) throws -> URL {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw PlanetPulseURLBuilderError.emptySearchQuery
        }
        return try articleURL(
            urlProvider.aiChat(origin: .planetPulse, query: query)
        )
    }

    private func articleURL(_ url: URL) throws -> URL {
        guard url.scheme == "https", url.host != nil else {
            throw PlanetPulseURLBuilderError.invalidArticleURL
        }
        return try internalURL(
            host: "open-url",
            queryItem: URLQueryItem(name: "url", value: url.absoluteString)
        )
    }

    private func internalURL(host: String, queryItem: URLQueryItem) throws -> URL {
        var components = URLComponents()
        components.scheme = scheme
        components.host = host

        guard let baseURL = components.url else {
            throw PlanetPulseURLBuilderError.unableToBuildURL
        }
        return baseURL.appendingPercentEncodedQueryItems([queryItem])
    }
}
