// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Ecosia
import XCTest

final class SearchRouterConfigTests: XCTestCase {

    override func setUp() {
        super.setUp()
        resetUnleash()
    }

    override func tearDown() {
        resetUnleash()
        super.tearDown()
    }

    // MARK: - Decoding

    func testDecodesFullPayload() {
        let config = SearchRouterConfig(payload: """
        {"aiMode": "redirect", "providers": ["ecosia", "google", "chatgpt"]}
        """)

        XCTAssertEqual(config?.aiMode, .redirect)
        XCTAssertEqual(config?.providers, [.ecosia, .google, .chatgpt])
    }

    func testDecodesEveryAIMode() {
        XCTAssertEqual(SearchRouterConfig(payload: #"{"aiMode": "full"}"#)?.aiMode, .full)
        XCTAssertEqual(SearchRouterConfig(payload: #"{"aiMode": "redirect"}"#)?.aiMode, .redirect)
        XCTAssertEqual(SearchRouterConfig(payload: #"{"aiMode": "hidden"}"#)?.aiMode, .hidden)
    }

    func testPreservesPayloadProviderOrder() {
        let config = SearchRouterConfig(payload: """
        {"providers": ["ecosia", "perplexity", "google"]}
        """)

        XCTAssertEqual(config?.providers, [.ecosia, .perplexity, .google])
    }

    func testDeduplicatesProviders() {
        let config = SearchRouterConfig(payload: """
        {"providers": ["ecosia", "google", "google", "ecosia"]}
        """)

        XCTAssertEqual(config?.providers, [.ecosia, .google])
    }

    // MARK: - Lenient decoding

    func testUnknownAIModeFallsBackToFull() {
        let config = SearchRouterConfig(payload: """
        {"aiMode": "something-new", "providers": ["ecosia"]}
        """)

        XCTAssertEqual(config?.aiMode, .full)
    }

    func testUnknownProviderIsDropped() {
        let config = SearchRouterConfig(payload: """
        {"providers": ["ecosia", "google", "askjeeves"]}
        """)

        XCTAssertEqual(config?.providers, [.ecosia, .google])
    }

    func testAbsentAIModeDefaultsToFull() {
        XCTAssertEqual(SearchRouterConfig(payload: #"{"providers": ["ecosia"]}"#)?.aiMode, .full)
    }

    /// Absent means no opinion; an empty list is a deliberate restriction.
    func testAbsentProvidersKeyOffersEveryProvider() {
        let config = SearchRouterConfig(payload: #"{"aiMode": "hidden"}"#)

        XCTAssertEqual(config?.providers, SearchProvider.allCases)
    }

    func testExplicitlyEmptyProvidersCollapsesToEcosiaOnly() {
        let config = SearchRouterConfig(payload: #"{"providers": []}"#)

        XCTAssertEqual(config?.providers, [.ecosia])
    }

    func testEcosiaIsAlwaysOffered() {
        let config = SearchRouterConfig(payload: #"{"providers": ["google", "chatgpt"]}"#)

        XCTAssertEqual(config?.providers.first, .ecosia)
        XCTAssertTrue(config?.offers(.ecosia) == true)
    }

    func testMalformedPayloadFailsDecoding() {
        XCTAssertNil(SearchRouterConfig(payload: "not json"))
        XCTAssertNil(SearchRouterConfig(payload: #"{"aiMode": "full""#))
        XCTAssertNil(SearchRouterConfig(payload: "[]"))
        XCTAssertNil(SearchRouterConfig(payload: nil))
    }

    func testEmptyObjectDecodesToDefault() {
        XCTAssertEqual(SearchRouterConfig(payload: "{}"), .default)
    }

    // MARK: - Defaults

    func testDefaultIsFullAIModeWithEveryProvider() {
        XCTAssertEqual(SearchRouterConfig.default.aiMode, .full)
        XCTAssertEqual(SearchRouterConfig.default.providers, SearchProvider.allCases)
    }

    func testRouterDisabledIsEcosiaOnly() {
        XCTAssertEqual(SearchRouterConfig.routerDisabled.providers, [.ecosia])
        XCTAssertEqual(SearchRouterConfig.routerDisabled.aiMode, .full)
    }

    // MARK: - Resolution from Unleash

    func testResolvesConfigFromVariantPayload() {
        setCustomSearchProviderToggle(enabled: true,
                                      payload: #"{"aiMode": "hidden", "providers": ["ecosia", "duckduckgo"]}"#)

        let config = CustomSearchProviderFeatureFlag.config
        XCTAssertEqual(config.aiMode, .hidden)
        XCTAssertEqual(config.providers, [.ecosia, .duckduckgo])
    }

    func testFlagOffReturnsEcosiaOnlyRegardlessOfPayload() {
        setCustomSearchProviderToggle(enabled: false,
                                      payload: #"{"aiMode": "hidden", "providers": ["ecosia", "google"]}"#)

        XCTAssertEqual(CustomSearchProviderFeatureFlag.config, .routerDisabled)
    }

    func testMissingToggleReturnsEcosiaOnly() {
        XCTAssertEqual(CustomSearchProviderFeatureFlag.config, .routerDisabled)
    }

    func testMissingPayloadFallsBackToDefault() {
        setCustomSearchProviderToggle(enabled: true, payload: nil)

        XCTAssertEqual(CustomSearchProviderFeatureFlag.config, .default)
    }

    func testMalformedPayloadFallsBackToDefault() {
        setCustomSearchProviderToggle(enabled: true, payload: "{ nope }")

        XCTAssertEqual(CustomSearchProviderFeatureFlag.config, .default)
    }

    func testNonJSONPayloadTypeIsIgnored() {
        setCustomSearchProviderToggle(enabled: true,
                                      payload: #"{"aiMode": "hidden"}"#,
                                      payloadType: "string")

        XCTAssertEqual(CustomSearchProviderFeatureFlag.config, .default)
    }

    // MARK: - Caching

    /// A remote refresh must be picked up without an explicit invalidation.
    func testCachedConfigIsRecomputedWhenPayloadChangesWithoutInvalidation() {
        setCustomSearchProviderToggle(enabled: true, payload: #"{"aiMode": "full"}"#)
        XCTAssertEqual(CustomSearchProviderFeatureFlag.config.aiMode, .full)

        setCustomSearchProviderToggle(enabled: true,
                                      payload: #"{"aiMode": "redirect"}"#,
                                      invalidatingCache: false)
        XCTAssertEqual(CustomSearchProviderFeatureFlag.config.aiMode, .redirect)
    }

    func testRepeatedReadsReturnEqualConfig() {
        setCustomSearchProviderToggle(enabled: true, payload: #"{"providers": ["ecosia", "google"]}"#)

        XCTAssertEqual(CustomSearchProviderFeatureFlag.config, CustomSearchProviderFeatureFlag.config)
    }

    // MARK: - Helpers

    private func resetUnleash() {
        Unleash.model = Unleash.Model()
        SearchRouterConfiguration.invalidateCache()
    }

    private func setCustomSearchProviderToggle(enabled: Bool,
                                               payload: String?,
                                               payloadType: String = "json",
                                               invalidatingCache: Bool = true) {
        var model = Unleash.Model()
        model.toggles.insert(
            Unleash.Toggle(name: Unleash.Toggle.Name.customSearchProvider.rawValue,
                           enabled: enabled,
                           variant: .init(name: "config",
                                          enabled: true,
                                          payload: payload.map { .init(type: payloadType, value: $0) }))
        )
        Unleash.model = model
        if invalidatingCache {
            SearchRouterConfiguration.invalidateCache()
        }
    }
}
