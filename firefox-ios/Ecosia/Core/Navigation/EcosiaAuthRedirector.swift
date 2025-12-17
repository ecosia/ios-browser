// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

public struct EcosiaAuthRedirector {

    private static let returnToParameterName = "returnTo"

    public static func redirectURLForSignIn(_ url: URL, redirectURLString: String?) -> URL? {
        guard isSignInURL(url) else { return nil }
        return redirectURL(for: url, redirectURLString: redirectURLString)
    }

    public static func redirectURL(for url: URL, redirectURLString: String?) -> URL? {
        guard shouldRewrite(url),
              let redirectURLString,
              let redirectURL = URL(string: redirectURLString)
        else {
            return nil
        }

        return urlWithRedirectParameter(url, redirectURL: redirectURL)
    }

    private static func isSignInURL(_ url: URL) -> Bool {
        url == Environment.current.urlProvider.signInURL
    }

    private static func shouldRewrite(_ url: URL) -> Bool {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return false
        }
        return components.queryItems?.contains(where: { $0.name == returnToParameterName }) == nil
    }

    private static func urlWithRedirectParameter(_ url: URL, redirectURL: URL) -> URL {
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false) ?? URLComponents()
        var queryItems = components.queryItems ?? []
        queryItems.append(URLQueryItem(name: returnToParameterName, value: redirectURL.absoluteString))
        components.queryItems = queryItems
        return components.url ?? url
    }
}
