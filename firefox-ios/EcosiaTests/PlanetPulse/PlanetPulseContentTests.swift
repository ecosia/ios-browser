// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Ecosia
import XCTest

final class PlanetPulseContentTests: XCTestCase {
    func testCatalogContainsElevenUniqueCardsAndBothKinds() {
        // Given
        let cards = PlanetPulseContent.cards

        // When
        let ids = Set(cards.map(\.id))
        let kinds = Set(cards.map(\.kind))

        // Then
        XCTAssertEqual(cards.count, 11)
        XCTAssertEqual(ids.count, cards.count)
        XCTAssertEqual(kinds, [.action, .insight])
    }

    func testEveryCardHasDisplayContent() {
        // Given
        let cards = PlanetPulseContent.cards

        // When, Then
        for card in cards {
            XCTAssertFalse(card.id.isEmpty)
            XCTAssertFalse(card.title.isEmpty)
            XCTAssertFalse(card.body.isEmpty)
            XCTAssertFalse(card.callToAction.isEmpty)
        }
    }

    func testEveryArticleUsesHTTPS() {
        // Given
        let destinations = PlanetPulseContent.cards.map(\.destination)

        // When
        let articleURLs = destinations.compactMap { destination -> URL? in
            guard case .article(let url) = destination else { return nil }
            return url
        }

        // Then
        XCTAssertFalse(articleURLs.isEmpty)
        XCTAssertTrue(articleURLs.allSatisfy { $0.scheme == "https" && $0.host != nil })
    }

    func testCatalogDoesNotContainLocationDependentCards() {
        // Given
        let locationDependentIDs = [
            "local-heat-guidance",
            "seasonal-produce",
            "native-plants"
        ]

        // When
        let catalogIDs = Set(PlanetPulseContent.cards.map(\.id))

        // Then
        XCTAssertTrue(catalogIDs.isDisjoint(with: locationDependentIDs))
    }
}
