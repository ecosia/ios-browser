// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Ecosia
import XCTest
@testable import Client

final class SearchProviderAIRoutingTests: XCTestCase {

    // MARK: - Destinations

    func testEveryProviderHasAnAIDestination() throws {
        for provider in SearchProvider.allCases {
            XCTAssertNotNil(destination(for: provider), "\(provider) has no AI destination")
        }
    }

    func testEveryDestinationCarriesTheQuery() throws {
        for provider in SearchProvider.allCases {
            let items = try queryItems(for: provider, query: "how do trees grow")
            XCTAssertEqual(items["q"], "how do trees grow", "\(provider) does not carry the query")
        }
    }

    func testGoogleUsesAIModeRatherThanPlainSearch() throws {
        let url = try XCTUnwrap(destination(for: .google))
        let items = try queryItems(for: .google)

        XCTAssertEqual(url.host, "www.google.com")
        XCTAssertEqual(url.path, "/search")
        XCTAssertEqual(items["udm"], "50")
    }

    func testDuckDuckGoUsesDuckAIWithAutoSubmit() throws {
        let url = try XCTUnwrap(destination(for: .duckduckgo))

        XCTAssertEqual(url.host, "duck.ai")
        XCTAssertEqual(try queryItems(for: .duckduckgo)["auto_submit"], "1")
    }

    func testChatGPTUsesSearchHint() throws {
        let url = try XCTUnwrap(destination(for: .chatgpt))

        XCTAssertEqual(url.host, "chatgpt.com")
        XCTAssertEqual(try queryItems(for: .chatgpt)["hints"], "search")
    }

    func testPerplexityUsesItsSearchPath() throws {
        let url = try XCTUnwrap(destination(for: .perplexity))

        XCTAssertEqual(url.host, "www.perplexity.ai")
        XCTAssertEqual(url.path, "/search")
    }

    func testEcosiaUsesAIChatAndHonoursTheOrigin() throws {
        let destination = SearchProviderAIRouting.aiDestinationURL(for: .ecosia,
                                                                   query: "trees",
                                                                   origin: .omnibox)
        let url = try XCTUnwrap(destination)
        let items = try XCTUnwrap(URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems)

        let expectedOrigin = URLQueryItem(name: "origin", value: URLProvider.AIChatOrigin.omnibox.rawValue)

        XCTAssertTrue(url.isEcosiaAIChat)
        XCTAssertTrue(items.contains(expectedOrigin))
    }

    func testQueriesAreEscaped() throws {
        let url = try XCTUnwrap(destination(for: .chatgpt, query: "trees & shrubs"))

        XCTAssertFalse(url.absoluteString.contains("trees & shrubs"))
        XCTAssertEqual(try queryItems(for: .chatgpt, query: "trees & shrubs")["q"], "trees & shrubs")
    }

    // MARK: - Recognising destinations

    func testEveryBuiltDestinationIsRecognised() throws {
        for provider in SearchProvider.allCases {
            let url = try XCTUnwrap(destination(for: provider))
            XCTAssertTrue(SearchProviderAIRouting.isAIDestination(url),
                          "\(provider) destination is not recognised")
        }
    }

    func testUploadDestinationsAreRecognised() throws {
        for provider in SearchProvider.allCases {
            guard let url = provider.fileUploadDestination else { continue }
            XCTAssertTrue(SearchProviderAIRouting.isAIDestination(url),
                          "\(provider) upload destination is not recognised")
        }
    }

    /// A plain Google results page must still go through the normal search pipeline.
    func testPlainGoogleSearchIsNotAnAIDestination() throws {
        let url = try XCTUnwrap(URL(string: "https://www.google.com/search?q=trees"))

        XCTAssertFalse(SearchProviderAIRouting.isAIDestination(url))
    }

    func testUnrelatedURLIsNotAnAIDestination() throws {
        let url = try XCTUnwrap(URL(string: "https://example.com/search?q=trees"))

        XCTAssertFalse(SearchProviderAIRouting.isAIDestination(url))
    }

    // MARK: - Helpers

    private func destination(for provider: SearchProvider, query: String = "trees") -> URL? {
        SearchProviderAIRouting.aiDestinationURL(for: provider, query: query, origin: .autocomplete)
    }

    private func queryItems(for provider: SearchProvider,
                            query: String = "trees") throws -> [String: String] {
        let url = try XCTUnwrap(destination(for: provider, query: query))
        let components = try XCTUnwrap(URLComponents(url: url, resolvingAgainstBaseURL: false))
        return Dictionary(uniqueKeysWithValues: (components.queryItems ?? []).compactMap { item in
            item.value.map { (item.name, $0) }
        })
    }
}
