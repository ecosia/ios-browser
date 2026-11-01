// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

extension AppDelegate {
    /// Whether the app may build the Firefox Suggest store and ingest suggestions.
    ///
    /// Upstream ingests on every foreground whatever the flag says, which downloads Mozilla's
    /// `quicksuggest-*` collections and their attachments from Remote Settings. Ecosia ships
    /// Firefox Suggest off, so ingestion follows the same flag as the search UI and the
    /// background ingest task.
    var isFirefoxSuggestIngestionEnabled: Bool {
        featureFlagsProvider.isEnabled(.firefoxSuggestFeature)
    }
}
