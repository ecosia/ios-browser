// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

extension URL {

    public enum EcosiaQueryItemName: String {
        case
        autoRedirect = "ar",
        page = "p",
        query = "q",
        typeTag = "tt",
        userId = "_sp"
    }

    public enum EcosiaSearchVertical: String, CaseIterable {
        case search
        case images
        case news
        case videos

        init?(path: String) {
            let pathWithNoLeadingSlash = String(path.dropFirst())
            self.init(rawValue: pathWithNoLeadingSlash)
        }

        init?(url: URL, urlProvider: URLProvider = EcosiaEnvironment.current.urlProvider) {
            guard url.isEcosia(urlProvider),
                  let path = URLComponents(url: url, resolvingAgainstBaseURL: false)?.path else {
                return nil
            }
            self.init(path: path)
        }
    }

    /// Builds the Ecosia SERP URL for a typed query.
    /// - Parameters:
    ///   - query: The user's search term.
    ///   - vertical: The search vertical to target. Defaults to `.search` (text results).
    ///   - urlProvider: Provider supplying the search root URL. Defaults to the current environment.
    ///   - autoRedirect: When `true`, appends the `ar=1` query parameter so the backend can decide
    ///     whether the request lands on AI search or the standard SERP. Use this for entry points
    ///     where the routing decision belongs to the backend (e.g. the NTP omnibox).
    public static func ecosiaSearchWithQuery(
        _ query: String,
        vertical: EcosiaSearchVertical = .search,
        urlProvider: URLProvider = EcosiaEnvironment.current.urlProvider,
        autoRedirect: Bool = false
    ) -> URL {
        var components = URLComponents(url: urlProvider.root, resolvingAgainstBaseURL: false)!
        components.path = "/\(vertical.rawValue)"
        var queryItems = [item(name: .query, value: query), item(name: .typeTag, value: "iosapp")]
        if autoRedirect {
            queryItems.append(item(name: .autoRedirect, value: "1"))
        }
        components.queryItems = queryItems
        return components.url!
    }

    /// Builds a SERP URL for `query`, keeping the search vertical of `currentPageURL` when the user
    /// is already on Images, Videos, or News. Falls back to the text SERP for other pages.
    public static func ecosiaSearchWithQuery(
        _ query: String,
        preservingVerticalFrom currentPageURL: URL?,
        urlProvider: URLProvider = EcosiaEnvironment.current.urlProvider,
        autoRedirect: Bool = false
    ) -> URL {
        let vertical = currentPageURL?.ecosiaSearchVerticalForPreservation(urlProvider: urlProvider) ?? .search
        return ecosiaSearchWithQuery(
            query,
            vertical: vertical,
            urlProvider: urlProvider,
            autoRedirect: autoRedirect
        )
    }

    /// Search vertical on `currentPageURL`, or `.search` when not on a SERP vertical.
    func ecosiaSearchVerticalForPreservation(
        urlProvider: URLProvider = EcosiaEnvironment.current.urlProvider
    ) -> EcosiaSearchVertical {
        EcosiaSearchVertical(url: self, urlProvider: urlProvider) ?? .search
    }

    /// Rewrites a default text SERP (`/search?q=…`) to the vertical of `currentPageURL`.
    /// Returns `nil` when no rewrite is needed (already on the right vertical, or not a text SERP URL).
    public func ecosiaSearchURLPreservingVertical(
        from currentPageURL: URL?,
        urlProvider: URLProvider = EcosiaEnvironment.current.urlProvider
    ) -> URL? {
        guard isEcosiaSearchQuery(urlProvider), let query = getEcosiaSearchQuery(urlProvider) else {
            return nil
        }
        let vertical = currentPageURL?.ecosiaSearchVerticalForPreservation(urlProvider: urlProvider) ?? .search
        guard vertical != .search else { return nil }
        let rewritten = URL.ecosiaSearchWithQuery(query, vertical: vertical, urlProvider: urlProvider)
        return rewritten.absoluteString == absoluteString ? nil : rewritten
    }

    /// Check whether the URL being browsed will present the SERP out of a search or a search suggestion
    public func isEcosiaSearchQuery(_ urlProvider: URLProvider = EcosiaEnvironment.current.urlProvider) -> Bool {
        guard isEcosia(urlProvider),
              let components = URLComponents(url: self, resolvingAgainstBaseURL: false) else {
            return false
        }
        return components.path == "/search"
    }

    public func isEcosiaSearchVertical(_ urlProvider: URLProvider = EcosiaEnvironment.current.urlProvider) -> Bool {
        getEcosiaSearchVerticalPath(urlProvider) != nil
    }

    public func getEcosiaSearchVerticalPath(_ urlProvider: URLProvider = EcosiaEnvironment.current.urlProvider) -> String? {
        EcosiaSearchVertical(url: self, urlProvider: urlProvider)?.rawValue
    }

    public func getEcosiaSearchQuery(_ urlProvider: URLProvider = EcosiaEnvironment.current.urlProvider) -> String? {
        guard isEcosia(urlProvider),
              let components = components else {
            return nil
        }
        return components.queryItems?.first(where: {
            $0.name == EcosiaQueryItemName.query.rawValue
        })?.value
    }

    public func getEcosiaSearchPage(_ urlProvider: URLProvider = EcosiaEnvironment.current.urlProvider) -> Int? {
        guard isEcosia(urlProvider),
              let components = components else {
            return nil
        }
        if let pageNumber = components.queryItems?.first(where: {
            $0.name == EcosiaQueryItemName.page.rawValue
        })?.value {
            return Int(pageNumber)
        }
        return nil
    }

    /// Check whether the URL should be Ecosified. At the moment this is true for every Ecosia URL.
    public func shouldEcosify(_ urlProvider: URLProvider = EcosiaEnvironment.current.urlProvider) -> Bool {
        return isEcosia(urlProvider)
    }

    public func ecosified(isIncognitoEnabled: Bool, urlProvider: URLProvider = EcosiaEnvironment.current.urlProvider) -> URL {
        guard isEcosia(urlProvider),
              var components = components
        else { return self }

        // Remove existing userId if present
        components.queryItems?.removeAll(where: { $0.name == EcosiaQueryItemName.userId.rawValue })

        /*
         The `sendAnonymousUsageData` is set by the native UX component in settings
         that determines whether the app would send the events to Snowplow.
         To align the business logic, this parameter will also function as a condition
         that decides whether we would send our AnalyticsID as query paramter for
         searches. In this scenario thuogh, the naming is a bit misleanding, thus
         checking for the negative evaluation of it.
         */
        let shouldAnonymizeUserId = isIncognitoEnabled ||
                                    !User.shared.hasAnalyticsCookieConsent ||
                                    !User.shared.sendAnonymousUsageData
        let userId = shouldAnonymizeUserId ? UUID(uuid: UUID_NULL).uuidString : User.shared.analyticsId.uuidString

        guard let urlWithoutUserId = components.url else { return self }
        return urlWithoutUserId.appendingQueryItems([Self.item(name: .userId, value: userId)])
    }

    public var policy: Scheme.Policy {
        (scheme
            .flatMap(Scheme.init(rawValue:)) ?? .other)
            .policy
    }

    private subscript(_ itemName: EcosiaQueryItemName) -> String? {
        components?.queryItems?.first { $0.name == itemName.rawValue }?.value
    }

    public func isBrowser() -> Bool {
        scheme.flatMap(Scheme.init(rawValue:))?.isBrowser ?? false
    }

    public func isEcosia(_ urlProvider: URLProvider = EcosiaEnvironment.current.urlProvider) -> Bool {
        let hasURLProviderDomainSuffix = host?.hasSuffix(urlProvider.domain) == true
        return isBrowser() && hasURLProviderDomainSuffix
    }

    private var components: URLComponents? {
        URLComponents(url: self, resolvingAgainstBaseURL: false)
    }

    private static func item(name: EcosiaQueryItemName, value: String) -> URLQueryItem {
        .init(name: name.rawValue, value: value)
    }

    /// Appends query items to a URL in a version-safe way.
    /// - Parameter queryItems: The query items to append to the URL
    /// - Returns: A new URL with the query items appended
    /// - Note: This method can be removed once the minimum deployment target is iOS 16+,
    ///         as URL.append(queryItems:) is available natively from iOS 16.
    public func appendingQueryItems(_ queryItems: [URLQueryItem]) -> URL {
        if #available(iOS 16.0, *) {
            var url = self
            url.append(queryItems: queryItems)
            return url
        } else {
            guard var components = URLComponents(url: self, resolvingAgainstBaseURL: false) else {
                return self
            }
            if components.queryItems == nil {
                components.queryItems = []
            }
            components.queryItems?.append(contentsOf: queryItems)
            return components.url ?? self
        }
    }
}
