// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// Represents types of Ecosia URLs that are intercepted for native handling
public enum EcosiaInterceptedURLType {
    case signUp
    case signIn
    case signOut
    case profile
    case none

    /// Determines the intercepted URL type based on the path
    /// - Parameters:
    ///   - path: The URL path (lowercased recommended)
    ///   - urlProvider: The URL provider containing path patterns
    public init(path: String, urlProvider: URLProvider) {
        if urlProvider.signUpURL.relativePath == path {
            self = .signUp
        } else if urlProvider.signInURL.relativePath == path {
            self = .signIn
        } else if urlProvider.logoutURL.relativePath == path {
            self = .signOut
        } else if urlProvider.profileURL.relativePath == path {
            self = .profile
        } else {
            self = .none
        }
    }
}

/// Handles detection and classification of Ecosia URLs that should be intercepted
/// for native handling instead of web navigation
public struct EcosiaURLInterceptor {
    private let urlProvider: URLProvider
    private let isAccountsDisabled: Bool

    /// Creates a new URL interceptor
    /// - Parameters:
    ///   - urlProvider: The URL provider to use for path matching. Defaults to current environment.
    ///   - isAccountsDisabled: Whether Accounts URL interception is disabled. Defaults to `AccountsDisabled.isActive`.
    public init(urlProvider: URLProvider = Environment.current.urlProvider,
                isAccountsDisabled: Bool = AccountsDisabled.isActive) {
        self.urlProvider = urlProvider
        self.isAccountsDisabled = isAccountsDisabled
    }

    /// Determines if a URL should be intercepted and returns its type
    /// - Parameter url: The URL to check
    /// - Returns: The intercepted URL type, or `.none` if it shouldn't be intercepted
    public func interceptedType(for url: URL) -> EcosiaInterceptedURLType {
        guard !isAccountsDisabled else { return .none }
        guard url.isEcosia(urlProvider) else { return .none }

        let path = url.path.lowercased()
        return EcosiaInterceptedURLType(path: path, urlProvider: urlProvider)
    }

    /// Checks if a URL should be intercepted
    /// - Parameter url: The URL to check
    /// - Returns: `true` if the URL should be intercepted, `false` otherwise
    public func shouldIntercept(_ url: URL) -> Bool {
        interceptedType(for: url) != .none
    }
}
