// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// Search router configuration, carried in the `mob_ios_custom_search_provider`
/// Unleash variant payload:
///
/// ```json
/// { "aiMode": "full", "providers": ["ecosia", "google", "duckduckgo"] }
/// ```
///
/// The payload is hand-edited with no schema validation, so decoding is lenient and
/// unrecognised values fall back rather than failing. See `SearchRouterConfiguration`.
public struct SearchRouterConfig: Codable, Equatable, Sendable {

    /// How the AI entry point (the + control and the AI suggestion row) behaves.
    public enum AIMode: String, Codable, Sendable {
        /// Chat modes and file upload, simplified for non-Ecosia providers.
        case full
        /// The entry point redirects straight to the provider's AI. No modes, no upload.
        case redirect
        /// No AI entry point for any provider.
        case hidden
    }

    public let aiMode: AIMode
    /// Providers offered in Settings, in payload order. Always contains `.ecosia`.
    public let providers: [SearchProvider]

    public init(aiMode: AIMode, providers: [SearchProvider]) {
        self.aiMode = aiMode
        self.providers = Self.normalized(providers)
    }

    /// Used when the payload is absent or unusable.
    public static let `default` = SearchRouterConfig(aiMode: .full,
                                                     providers: SearchProvider.allCases)

    /// Used while the Unleash toggle is off: Ecosia only, with its full AI stack.
    public static let routerDisabled = SearchRouterConfig(aiMode: .full,
                                                          providers: [.ecosia])

    public func offers(_ provider: SearchProvider) -> Bool {
        providers.contains(provider)
    }

    // MARK: - Decoding

    private enum CodingKeys: String, CodingKey {
        case aiMode
        case providers
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        aiMode = (try? container.decode(AIMode.self, forKey: .aiMode)) ?? .full

        // Absent key means no opinion, so offer everything. A present key is
        // authoritative, including when it filters down to nothing. Unknown ids are
        // dropped rather than failing the whole payload.
        if container.contains(.providers),
           let rawProviders = try? container.decode([String].self, forKey: .providers) {
            providers = Self.normalized(rawProviders.compactMap(SearchProvider.init(rawValue:)))
        } else {
            providers = SearchProvider.allCases
        }
    }

    /// Deduplicates in payload order. Ecosia is always offered.
    private static func normalized(_ providers: [SearchProvider]) -> [SearchProvider] {
        var seen = Set<SearchProvider>()
        var result = providers.filter { seen.insert($0).inserted }
        if !result.contains(.ecosia) {
            result.insert(.ecosia, at: 0)
        }
        return result
    }
}

extension SearchRouterConfig {
    /// Decodes a raw Unleash payload. `nil` for anything unusable, so callers fall back
    /// to `default`.
    init?(payload: String?) {
        guard let payload,
              let data = payload.data(using: .utf8),
              let decoded = try? JSONDecoder().decode(SearchRouterConfig.self, from: data)
        else { return nil }
        self = decoded
    }
}
