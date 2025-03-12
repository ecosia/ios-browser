import Foundation
import Auth0

public enum Cookie: String {
    case main
    case consent
    case auth

    // MARK: - Init
    /// Initialize Cookie enum based on the name
    init?(_ name: String) {
        switch name {
        case "ECFG":
            self = .main
        case "ECCC":
            self = .consent
        case "EASC":  // Name of the auth cookie
            self = .auth
        default:
            return nil
        }
    }

    // MARK: - Main Specific Properties

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

    // MARK: - Auth Cookie Properties

    private struct AuthCookieProperties {
        static let idToken = "auth0Users"
        static let accessToken = "accessToken"
        static let refreshToken = "refreshToken"
    }

    // MARK: - Common Properties

    var name: String {
        switch self {
        case .main:
            return "ECFG"
        case .consent:
            return "ECCC"
        case .auth:
            return "EASC"
        }
    }

    /// Values for incognito mode cookies.
    static var incognitoValues: [String: String] {
        var values = [String: String]()
        values[MainCookieProperties.adultFilter] = User.shared.adultFilter.rawValue
        values[MainCookieProperties.marketCode] = User.shared.marketCode.rawValue
        values[MainCookieProperties.language] = Language.current.rawValue
        values[MainCookieProperties.suggestions] = .init(NSNumber(value: User.shared.autoComplete).intValue)
        values[MainCookieProperties.personalized] = .init(NSNumber(value: User.shared.personalized).intValue)
        values[MainCookieProperties.marketApplied] = "1"
        values[MainCookieProperties.marketReapplied] = "1"
        values[MainCookieProperties.deviceType] = "mobile"
        values[MainCookieProperties.firstSearch] = "0"
        values[MainCookieProperties.addon] = "1"
        return values
    }

    /// Values for standard mode cookies.
    static var standardValues: [String: String] {
        var values = incognitoValues
        values[MainCookieProperties.userId] = User.shared.id
        values[MainCookieProperties.treeCount] = .init(User.shared.searchCount)
        return values
    }

    // MARK: - Functions

    /// Creates an incognito mode ECFG cookie.
    /// - Parameter urlProvider: Provides the URL information.
    /// - Returns: An HTTPCookie configured for incognito mode.
    public static func makeIncognitoCookie(_ urlProvider: URLProvider = Environment.current.urlProvider) -> HTTPCookie {
        HTTPCookie(properties: [.name: Cookie.main.name,
                                .domain: ".\(urlProvider.domain ?? "")",
                                .path: "/",
                                .value: Cookie.incognitoValues.map { $0.0 + "=" + $0.1 }.joined(separator: ":")])!
    }

    /// Creates a standard mode ECFG cookie.
    /// - Parameter urlProvider: Provides the URL information.
    /// - Returns: An HTTPCookie configured for standard mode.
    public static func makeStandardCookie(_ urlProvider: URLProvider = Environment.current.urlProvider) -> HTTPCookie {
        HTTPCookie(properties: [.name: Cookie.main.name,
                                .domain: ".\(urlProvider.domain ?? "")",
                                .path: "/",
                                .value: Cookie.standardValues.map { $0.0 + "=" + $0.1 }.joined(separator: ":")])!
    }

    public static func makeConsentCookie(_ urlProvider: URLProvider = Environment.current.urlProvider) -> HTTPCookie? {
        guard let cookieConsentValue = User.shared.cookieConsentValue else { return nil }
        return HTTPCookie(properties: [.name: Cookie.consent.name,
                                       .domain: ".\(urlProvider.domain ?? "")",
                                       .path: "/",
                                       .value: cookieConsentValue])
    }

    /// Creates the auth cookie with the Auth0 token.
    public static func makeAuthCookie(from auth: Auth, urlProvider: URLProvider = Environment.current.urlProvider) -> HTTPCookie? {

        // Decode the idToken and accessToken to get their expiration dates
        guard let idToken = auth.idToken,
              let accessToken = auth.accessToken,
              let idTokenExp = getExpirationDate(fromJWT: idToken) else {
            print("👤 Auth - Failed to get expiration dates from tokens.")
            return nil
        }

        // Determine the earliest expiration date
        var earliestExpiration = idTokenExp
        if let accessTokenExp = getExpirationDate(fromJWT: accessToken) {
            earliestExpiration = min(idTokenExp, accessTokenExp)
        }

        var valueDict: [String: String] = [
            AuthCookieProperties.idToken: idToken,
            AuthCookieProperties.accessToken: accessToken
        ]

        if let refreshToken = auth.refreshToken {
            valueDict[AuthCookieProperties.refreshToken] = refreshToken
        }
        // Convert the dictionary to JSON
        guard let jsonData = try? JSONSerialization.data(withJSONObject: valueDict, options: []),
              let jsonString = String(data: jsonData, encoding: .utf8) else {
            return nil
        }
        return HTTPCookie(properties: [
            .name: Cookie.auth.name,
            .domain: ".\(urlProvider.domain ?? "")",
            .path: "/",
            .value: jsonString,
            .secure: "TRUE",
            .expires: earliestExpiration
        ])
    }

    /// Processes received cookies.
    /// - Parameters:
    ///   - cookies: An array of HTTPCookie objects.
    ///   - auth0Provider: Provides the authentication information.
    ///   - urlProvider: Provides the URL information.
    public static func received(_ cookies: [HTTPCookie],
                                auth0Provider: Auth0ProviderProtocol,
                                urlProvider: URLProvider = Environment.current.urlProvider) {
        cookies.forEach { cookie in
            guard let cookieType = Cookie(cookie.name), cookie.domain.contains(".\(urlProvider.domain ?? "")") else { return }
            cookieType.extract(cookie, auth0Provider: auth0Provider)
        }
    }

    /// Processes received cookies from an HTTP response.
    /// - Parameters:
    ///   - response: An HTTPURLResponse object.
    ///   - auth0Provider: Provides the authentication information.
    ///   - urlProvider: Provides the URL information.
    public static func received(_ response: HTTPURLResponse,
                                auth0Provider: Auth0ProviderProtocol,
                                urlProvider: URLProvider = Environment.current.urlProvider) {
        (response.allHeaderFields as? [String: String]).map {
            HTTPCookie.cookies(withResponseHeaderFields: $0, for: urlProvider.root)
        }.map { received($0, auth0Provider: auth0Provider, urlProvider: urlProvider) }
    }

    /// Extracts and handles ECFG specific properties.
    /// - Parameter properties: A dictionary of cookie properties.
    private func extractECFG(_ properties: [String: String]) {
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

        properties[MainCookieProperties.adultFilter].flatMap(AdultFilter.init).map({
            user.adultFilter = $0
        })

        properties[MainCookieProperties.personalized].flatMap(Int.init).flatMap(NSNumber.init).flatMap(Bool.init).map({
            user.personalized = $0
        })

        properties[MainCookieProperties.suggestions].map({
            user.autoComplete = ($0 as NSString).boolValue
        })

        User.shared = user
    }

    /// Extracts and handles ECCC specific properties.
    /// - Parameter value: A string of cookie values expressed by a sequence of letters (e.g. `eampg`)
    private func extractECCC(_ value: String) {
        User.shared.cookieConsentValue = value
    }

    /// Handles the extraction of the auth cookie.
    private func extractAuthCookie(_ cookie: HTTPCookie, auth0Provider: Auth0ProviderProtocol) {
        // Parse the cookie value as JSON
        let cookieValue = cookie.value
        guard let jsonData = cookieValue.data(using: .utf8),
              let tokenDict = try? JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: String] else {
            print("👤 Auth - Failed to parse auth cookie value as JSON.")
            return
        }

        // Extract tokens using AuthCookieProperties
        guard let idToken = tokenDict[AuthCookieProperties.idToken],
              let accessToken = tokenDict[AuthCookieProperties.accessToken] else {
            print("👤 Auth - Missing idToken or accessToken in auth cookie.")
            return
        }

        let refreshToken = tokenDict[AuthCookieProperties.refreshToken]  // Optional

        // Decode accessToken to extract exp and scopes
        guard let expTime = Self.getExpirationDate(fromJWT: accessToken) else {
            print("👤 Auth - Failed to extract expiration time from accessToken.")
            return
        }

        let scopes = Self.getScopes(fromJWT: accessToken)

        // Create Credentials object
        let credentials = Credentials(
            accessToken: accessToken,
            tokenType: "Bearer",
            idToken: idToken,
            refreshToken: refreshToken,
            expiresIn: expTime,
            scope: scopes
        )

        do {
            if try auth0Provider.storeCredentials(credentials) {
                print("👤 Auth - Credentials stored from auth cookie.")
            }
        } catch {
            print("👤 Auth - Failed to store credentials: \(error)")
        }
    }

    /// Extracts properties from a cookie.
    /// - Parameter cookie: An HTTPCookie object.
    private func extract(_ cookie: HTTPCookie, auth0Provider: Auth0ProviderProtocol) {

        switch self {
        case .main:
            let properties = cookie.value.components(separatedBy: ":")
                .map { $0.components(separatedBy: "=") }
                .filter { $0.count == 2 }
                .reduce(into: [:]) { result, item in
                    result[item[0]] = item[1]
                }
            extractECFG(properties)
        case .consent:
            extractECCC(cookie.value)
        case .auth:
            return
//            extractAuthCookie(cookie, auth0Provider: auth0Provider)
        }
    }
}

extension Cookie {

    /// Decodes a JWT token and extracts the payload as a dictionary.
    private static func decodeJWT(_ jwt: String) -> [String: Any]? {
        let segments = jwt.components(separatedBy: ".")
        guard segments.count == 3 else {
            print("Invalid JWT token, expected 3 segments.")
            return nil
        }

        let payloadSegment = segments[1]
        var base64String = payloadSegment
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")

        // Add padding if necessary
        let remainder = base64String.count % 4
        if remainder > 0 {
            base64String = base64String.padding(toLength: base64String.count + 4 - remainder, withPad: "=", startingAt: 0)
        }

        guard let payloadData = Data(base64Encoded: base64String) else {
            print("Failed to base64 decode the payload segment.")
            return nil
        }

        do {
            if let payload = try JSONSerialization.jsonObject(with: payloadData, options: []) as? [String: Any] {
                return payload
            } else {
                print("Failed to parse payload as JSON.")
                return nil
            }
        } catch {
            print("Error parsing payload JSON: \(error)")
            return nil
        }
    }

    /// Extracts the expiration date from a JWT token.
    private static func getExpirationDate(fromJWT jwt: String) -> Date? {
        guard let payload = decodeJWT(jwt),
              let expValue = payload["exp"] as? TimeInterval else {
            return nil
        }
        return Date(timeIntervalSince1970: expValue)
    }

    /// Extracts the scopes from a JWT token.
    private static func getScopes(fromJWT jwt: String) -> String? {
        guard let payload = decodeJWT(jwt),
              let scopes = payload["scopes"] as? String else {
            return nil
        }
        return scopes
    }
}
