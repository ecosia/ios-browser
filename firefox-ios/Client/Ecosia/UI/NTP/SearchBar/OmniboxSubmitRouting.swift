// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared
import Ecosia

/// Resolves omnibox submission URLs for text queries, pasted URLs, and attachment uploads.
enum OmniboxSubmitRouting {
    static func destinationURL(
        query: String,
        chatFiles: [AIChatFileQuery],
        urlProvider: URLProvider = Environment.current.urlProvider
    ) -> URL {
        if chatFiles.isEmpty, let url = URIFixup.getURL(query) {
            return url
        }

        if !chatFiles.isEmpty {
            return urlProvider.aiChat(origin: .omnibox, query: query, files: chatFiles)
        }

        return URL.ecosiaSearchWithQuery(query, autoRedirect: true)
    }
}
