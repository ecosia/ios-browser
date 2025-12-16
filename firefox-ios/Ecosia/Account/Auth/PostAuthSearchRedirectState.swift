// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// Stores the search URL that should be restored after a post-auth redirect.
public final class PostAuthSearchRedirectState {

    private var pendingURLString: String?

    public init() {}

    /// Captures a valid search URL string if nothing is pending yet.
    /// - Parameter searchURLString: The raw search URL to store.
    public func capture(searchURLString: String?) {
        guard pendingURLString == nil,
              let searchURLString,
              !searchURLString.isEmpty,
              URL(string: searchURLString) != nil
        else {
            return
        }

        pendingURLString = searchURLString
    }

    /// Returns the pending search URL and clears the stored value.
    public func consumePendingURL() -> URL? {
        defer { pendingURLString = nil }
        guard let urlString = pendingURLString else { return nil }
        return URL(string: urlString)
    }

    /// Returns the pending search URL without clearing it.
    public func peekPendingURL() -> URL? {
        guard let urlString = pendingURLString else { return nil }
        return URL(string: urlString)
    }

    /// Indicates whether a pending search URL is stored.
    public var hasPendingURL: Bool {
        pendingURLString != nil
    }

    /// Clears any stored pending URL without returning it.
    public func reset() {
        pendingURLString = nil
    }
}
