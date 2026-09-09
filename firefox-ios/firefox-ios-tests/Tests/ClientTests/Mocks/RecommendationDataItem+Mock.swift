// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import MozillaAppServices

@testable import Client

// Ecosia: Moved here out of `MerinoProviderTests.swift`. `MockMerinoManager` (in
// ClientTests/Frontend/Homepage/Mock/) needs it, and that mock is compiled into EcosiaTests via
// DependencyHelperMock — but EcosiaTests does not compile the whole ClientTests tree, so the helper
// has to live somewhere both targets see. Putting it in Mocks/ avoids pulling upstream's Merino
// tests into EcosiaTests and running them twice.
extension RecommendationDataItem {
    static func makeItem(_ name: String) -> RecommendationDataItem {
        return RecommendationDataItem(
            corpusItemId: "\(name)",
            scheduledCorpusItemId: "\(name)",
            url: "https://\(name).com",
            title: "\(name)",
            excerpt: "Excerpt \(name)",
            publisher: "Publisher \(name)",
            isTimeSensitive: false,
            imageUrl: "https://example\(name).com",
            iconUrl: "https://example\(name).com",
            tileId: 0,
            receivedRank: 0
        )
    }
}
