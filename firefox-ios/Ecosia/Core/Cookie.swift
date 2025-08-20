// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

public enum Cookie: String {
    // https://ecosia.atlassian.net/wiki/spaces/DEV/pages/4128796/Cookies#ECFG
    case main = "ECFG"
    // https://ecosia.atlassian.net/wiki/spaces/DEV/pages/4128796/Cookies#ECCC
    case consent = "ECCC"
    // https://ecosia.atlassian.net/wiki/spaces/DEV/pages/4128796/Cookies#ECUNL
    case unleash = "ECUNL"

    // MARK: - Init
    /// Initialized enum using HTTPCookie object's name. Also checks domain matches Ecosia.
    /// - Parameters:
    ///   - cookie: HTTPCookie
    ///   - urlProvider: Provides the URL information. Default: Current environment
    init?(_ cookie: HTTPCookie, urlProvider: URLProvider = Environment.current.urlProvider) {
        let ecosiaDomain = urlProvider.domain ?? ""
        guard cookie.domain.contains("/\(ecosiaDomain)") else {
            return nil
        }
        self.init(cookie.name)
    }

    init?(_ name: String) {
        self.init(rawValue: name)
    }

    var name: String {
        rawValue
    }

    // MARK: - Handle received cookies

    /// Processes received cookies.
    /// - Parameters:
    ///   - cookies: An array of HTTPCookie objects.
    ///   - urlProvider: Provides the URL information. Default: Current environment
    public static func received(_ cookies: [HTTPCookie], urlProvider: URLProvider = Environment.current.urlProvider) {
        cookies.forEach { cookie in
            guard let cookieType = Cookie(cookie, urlProvider: urlProvider) else { return }
            cookieType.extract(cookie)
        }
    }

    /// Extracts properties from a cookie.
    /// - Parameter cookie: An HTTPCookie object.
    private func extract(_ cookie: HTTPCookie) {
        switch self {
        case .main:
            let properties = cookie.value.components(separatedBy: ":")
                .map { $0.components(separatedBy: "=") }
                .filter { $0.count == 2 }
                .reduce(into: [:]) { result, item in
                    result[item[0]] = item[1]
                }
            extractMain(properties)
        case .consent:
            extractConsent(cookie.value)
        case .unleash:
            extractUnleash(cookie.value)
        }
    }

    // MARK: - Main Cookie helpers

    private struct MainCookieProperties {
        static let userId = "cid"
        static let suggestions = "as"
        static let personalized = "pz"
        static let customSettings = "cs"
        static let adultFilter = "f"
        static let marketCode = "mc"
        static let treeCount = "t"
        static let language = "l"
        static let marketApplied = "ma"
        static let marketReapplied = "mr"
        static let deviceType = "dt"
        static let firstSearch = "fs"
        static let addon = "a"
    }

    /// Values for standard Main Cookie.
    private static var standardMainValues: [String: String] {
        var values = incognitoMainValues
        values[MainCookieProperties.userId] = User.shared.id
        values[MainCookieProperties.treeCount] = .init(User.shared.searchCount)
        return values
    }

    /// Creates a standard Main Cookie.
    /// - Parameter urlProvider: Provides the URL information.
    /// - Returns: An HTTPCookie configured for standard mode.
    public static func makeStandardMain(_ urlProvider: URLProvider = Environment.current.urlProvider) -> HTTPCookie {
        HTTPCookie(properties: [.name: Cookie.main.name,
                                .domain: ".\(urlProvider.domain ?? "")",
                                .path: "/",
                                .value: Cookie.standardMainValues.map { $0.0 + "=" + $0.1 }.joined(separator: ":")])!
    }

    /// Values for incognito Main Cookie.
    private static var incognitoMainValues: [String: String] {
        var values = [String: String]()
        values[MainCookieProperties.adultFilter] = User.shared.adultFilter.rawValue
        values[MainCookieProperties.marketCode] = User.shared.marketCode.rawValue
        values[MainCookieProperties.language] = Language.current.rawValue
        values[MainCookieProperties.suggestions] = .init(User.shared.autoComplete ? 1 : 0)
        values[MainCookieProperties.personalized] = .init(User.shared.personalized ? 1 : 0)
        values[MainCookieProperties.marketApplied] = "1"
        values[MainCookieProperties.marketReapplied] = "1"
        values[MainCookieProperties.deviceType] = "mobile"
        values[MainCookieProperties.firstSearch] = "0"
        values[MainCookieProperties.addon] = "1"
        return values
    }

    /// Creates an incognito Main Cookie.
    /// - Parameter urlProvider: Provides the URL information. Default: Current environment
    /// - Returns: An HTTPCookie configured for incognito mode.
    public static func makeIncognitoMain(_ urlProvider: URLProvider = Environment.current.urlProvider) -> HTTPCookie {
        HTTPCookie(properties: [.name: Cookie.main.name,
                                .domain: ".\(urlProvider.domain ?? "")",
                                .path: "/",
                                .value: Cookie.incognitoMainValues.map { $0.0 + "=" + $0.1 }.joined(separator: ":")])!
    }

    /// Extracts and handles Main Cookie specific properties.
    /// - Parameter properties: A dictionary of cookie properties.
    private func extractMain(_ properties: [String: String]) {
        var user = User.shared

        properties[MainCookieProperties.userId].map {
            user.id = $0
        }

        properties[MainCookieProperties.treeCount].flatMap(Int.init).map {
            // tree count should only increase or be reset to 0 on logout
            if $0 == 0 || $0 > user.searchCount {
                user.searchCount = $0
            }
        }

        properties[MainCookieProperties.marketCode].flatMap(Local.init).map {
            user.marketCode = $0
        }

        properties[MainCookieProperties.adultFilter].flatMap(AdultFilter.init).map {
            user.adultFilter = $0
        }

        properties[MainCookieProperties.personalized].flatMap(Int.init).map { NSNumber(value: $0) }.flatMap(Bool.init).map {
            user.personalized = $0
        }

        properties[MainCookieProperties.suggestions].map {
            user.autoComplete = ($0 as NSString).boolValue
        }

        User.shared = user
    }

    // MARK: - Consent Cookie helpers
    
    /// Creates a Consent Cookie.
    /// - Parameter urlProvider: Provides the URL information. Default: Current environment
    /// - Returns: An HTTPCookie with the consent value.
    public static func makeConsent(_ urlProvider: URLProvider = Environment.current.urlProvider) -> HTTPCookie? {
        guard let cookieConsentValue = User.shared.cookieConsentValue else { return nil }
        return HTTPCookie(properties: [.name: Cookie.consent.name,
                                       .domain: ".\(urlProvider.domain ?? "")",
                                       .path: "/",
                                       .value: cookieConsentValue])
    }

    /// Extracts and handles Consent Cookie.
    /// - Parameter value: A string of cookie values expressed by a sequence of letters (e.g. `eampg`)
    private func extractConsent(_ value: String) {
        User.shared.cookieConsentValue = value
    }

    // MARK: - Unleash Cookie helpers
    
    /// Creates a Consent Cookie.
    /// - Parameter urlProvider: Provides the URL information. Default: Current environment
    /// - Returns: An HTTPCookie with the consent value.
    public static func makeUnleash(_ urlProvider: URLProvider = Environment.current.urlProvider) -> HTTPCookie? {
        // TODO: Ensure Unleash has been loaded when getting id
        let unleashUserId = Unleash.model.id.uuidString.lowercased()
        return HTTPCookie(properties: [.name: Cookie.unleash.name,
                                       .domain: ".\(urlProvider.domain ?? "")",
                                       .path: "/",
                                       .value: unleashUserId])
    }

    /// Extracts and handles Unleash Cookie.
    /// - Parameter value: A string with the cookie value representing the user Id
    private func extractUnleash(_ value: String) {
        // No need to extract since we override the value
        // TODO: Do we need to force override again here if changed? Or is the one on `LegacyTabManager.makeWebViewConfig` enough?
    }
}
