// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Ecosia
import XCTest

final class SearchProviderCatalogTests: XCTestCase {

    // MARK: - Identity

    func testEngineIdentifiersAreStable() {
        XCTAssertEqual(SearchProvider.allCases.map(\.rawValue),
                       ["ecosia", "google", "duckduckgo", "chatgpt", "perplexity"])
    }

    func testEveryProviderHasADisplayName() {
        for provider in SearchProvider.allCases {
            XCTAssertFalse(provider.displayName.isEmpty, "\(provider) has no display name")
        }
    }

    // MARK: - AI-native providers

    func testOnlyConversationalProvidersAreAINative() {
        XCTAssertTrue(SearchProvider.chatgpt.isAINative)
        XCTAssertTrue(SearchProvider.perplexity.isAINative)
        XCTAssertFalse(SearchProvider.ecosia.isAINative)
        XCTAssertFalse(SearchProvider.google.isAINative)
        XCTAssertFalse(SearchProvider.duckduckgo.isAINative)
    }

    // MARK: - Search templates

    func testEverySearchTemplateCarriesTheSearchTermsPlaceholder() {
        for provider in SearchProvider.allCases {
            XCTAssertTrue(provider.searchTemplate.contains("{searchTerms}"),
                          "\(provider) template is missing the placeholder")
        }
    }

    func testThirdPartySearchTemplates() {
        XCTAssertEqual(SearchProvider.google.searchTemplate,
                       "https://www.google.com/search?q={searchTerms}")
        XCTAssertEqual(SearchProvider.duckduckgo.searchTemplate,
                       "https://duckduckgo.com/?q={searchTerms}")
    }

    /// Affiliate and client parameters are deliberately absent from the results URLs.
    func testSearchTemplatesCarryNoClientParameters() {
        for provider in SearchProvider.allCases {
            XCTAssertFalse(provider.searchTemplate.contains("client="),
                           "\(provider) template carries a client parameter")
            XCTAssertFalse(provider.searchTemplate.contains("channel="),
                           "\(provider) template carries a channel parameter")
        }
    }

    func testEcosiaSearchTemplateFollowsTheEnvironment() {
        let root = Environment.current.urlProvider.root.absoluteString
        XCTAssertEqual(SearchProvider.ecosia.searchTemplate, "\(root)/search?q={searchTerms}")
    }

    /// For these providers the results page is the conversation, so the search template
    /// doubles as the AI destination.
    func testAINativeSearchTemplatesPointAtTheConversation() {
        XCTAssertTrue(SearchProvider.chatgpt.searchTemplate.hasPrefix("https://chatgpt.com/"))
        XCTAssertTrue(SearchProvider.perplexity.searchTemplate.hasPrefix("https://www.perplexity.ai/search"))
    }

    // MARK: - Suggest templates

    func testSuggestTemplatesExistOnlyForSearchProviders() {
        XCTAssertNotNil(SearchProvider.ecosia.suggestTemplate)
        XCTAssertNotNil(SearchProvider.google.suggestTemplate)
        XCTAssertNotNil(SearchProvider.duckduckgo.suggestTemplate)
        XCTAssertNil(SearchProvider.chatgpt.suggestTemplate)
        XCTAssertNil(SearchProvider.perplexity.suggestTemplate)
    }

    func testSuggestTemplatesCarryTheSearchTermsPlaceholder() {
        for provider in SearchProvider.allCases {
            guard let template = provider.suggestTemplate else { continue }
            XCTAssertTrue(template.contains("{searchTerms}"),
                          "\(provider) suggest template is missing the placeholder")
        }
    }

    func testEcosiaSuggestTemplateFollowsTheEnvironment() {
        let autocomplete = Environment.current.urlProvider.searchAutocomplete.absoluteString
        XCTAssertEqual(SearchProvider.ecosia.suggestTemplate, "\(autocomplete)?q={searchTerms}&type=list")
    }

    // MARK: - File upload destinations

    func testEcosiaHasNoUploadRedirect() {
        XCTAssertNil(SearchProvider.ecosia.fileUploadDestination)
    }

    func testEveryThirdPartyProviderHasAnUploadRedirect() {
        for provider in SearchProvider.allCases where provider != .ecosia {
            XCTAssertNotNil(provider.fileUploadDestination, "\(provider) has no upload destination")
        }
    }

    /// Google uploads go to Gemini rather than to search.
    func testGoogleUploadRedirectsToGemini() {
        XCTAssertEqual(SearchProvider.google.fileUploadDestination?.absoluteString,
                       "https://gemini.google.com/app")
    }

    // MARK: - Icons

    func testEveryProviderResolvesAnIcon() {
        for provider in SearchProvider.allCases {
            let width = SearchProviderIcons.image(for: provider).size.width
            XCTAssertGreaterThan(width, 0, "\(provider) resolved an empty icon")
        }
    }

    /// Engine identifiers arrive from Remote Settings and from the Unleash payload, so an
    /// unknown one must not crash.
    func testUnknownEngineIdentifierFallsBackInsteadOfCrashing() {
        let image = SearchProviderIcons.image(for: "not-a-real-provider")

        XCTAssertGreaterThan(image.size.width, 0)
    }

    /// `OpenSearchEngine` asserts the icon is PNG-encodable when it archives.
    func testFallbackIconIsPNGEncodable() {
        XCTAssertNotNil(SearchProviderIcons.image(for: "not-a-real-provider").pngData())
    }
}
