// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Ecosia
import XCTest

final class PlanetPulseURLBuilderTests: XCTestCase {
    func testSearchDestinationOpensSeededEcosiaAIChatInApp() throws {
        // Given
        let query = "repair café & tools near me?"
        let builder = PlanetPulseURLBuilder(scheme: "ecosia", urlProvider: .production)

        // When
        let url = try builder.url(for: .search(query: query))
        let components = try XCTUnwrap(URLComponents(url: url, resolvingAgainstBaseURL: false))

        // Then
        XCTAssertEqual(components.scheme, "ecosia")
        XCTAssertEqual(components.host, "open-url")
        XCTAssertEqual(url.absoluteString.filter { $0 == "?" }.count, 1)
        XCTAssertTrue(
            url.absoluteString.contains(
                "%3Forigin%3Dplanet_pulse_widget%26q%3D"
            )
        )

        let destinationValue = try XCTUnwrap(
            components.queryItems?.first(where: { $0.name == "url" })?.value
        )
        let destination = try XCTUnwrap(URL(string: destinationValue))
        let aiChatComponents = try XCTUnwrap(
            URLComponents(url: destination, resolvingAgainstBaseURL: false)
        )
        XCTAssertEqual(aiChatComponents.host, "www.ecosia.org")
        XCTAssertEqual(aiChatComponents.path, "/ai-chat")
        XCTAssertEqual(
            aiChatComponents.queryItems,
            [
                URLQueryItem(name: "origin", value: "planet_pulse_widget"),
                URLQueryItem(name: "q", value: query)
            ]
        )
    }

    func testArticleURLPreservesHTTPSQueryItems() throws {
        // Given
        let article = try XCTUnwrap(URL(string: "https://blog.ecosia.org/story/?source=widget&mode=mixed"))
        let builder = PlanetPulseURLBuilder(scheme: "ecosia")

        // When
        let url = try builder.url(for: .article(article))
        let components = try XCTUnwrap(URLComponents(url: url, resolvingAgainstBaseURL: false))

        // Then
        XCTAssertEqual(components.host, "open-url")
        XCTAssertEqual(components.queryItems, [URLQueryItem(name: "url", value: article.absoluteString)])
    }

    func testInvalidSchemeThrows() {
        // Given
        let builder = PlanetPulseURLBuilder(scheme: "1 invalid scheme")

        // When, Then
        XCTAssertThrowsError(try builder.url(for: .search(query: "trees"))) { error in
            XCTAssertEqual(error as? PlanetPulseURLBuilderError, .invalidScheme)
        }
    }

    func testEmptySearchQueryThrows() {
        // Given
        let builder = PlanetPulseURLBuilder(scheme: "ecosia")

        // When, Then
        XCTAssertThrowsError(try builder.url(for: .search(query: "  \n"))) { error in
            XCTAssertEqual(error as? PlanetPulseURLBuilderError, .emptySearchQuery)
        }
    }

    func testNonHTTPSArticleThrows() throws {
        // Given
        let article = try XCTUnwrap(URL(string: "http://blog.ecosia.org/story"))
        let builder = PlanetPulseURLBuilder(scheme: "ecosia")

        // When, Then
        XCTAssertThrowsError(try builder.url(for: .article(article))) { error in
            XCTAssertEqual(error as? PlanetPulseURLBuilderError, .invalidArticleURL)
        }
    }
}
