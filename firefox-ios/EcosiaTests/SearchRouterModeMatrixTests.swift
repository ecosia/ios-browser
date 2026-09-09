// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Ecosia
import XCTest
@testable import Client

/// Covers the supported combinations of router state and AI entry point mode.
@MainActor
final class SearchRouterModeMatrixTests: XCTestCase {

    private var previousEngineID = ""
    private var previousAIFreeSearching: Bool?
    private var previousAIOverviews = true

    override func setUp() {
        super.setUp()
        previousEngineID = User.shared.selectedSearchEngineID
        previousAIFreeSearching = User.shared.aiFreeSearching
        previousAIOverviews = User.shared.aiOverviews
    }

    override func tearDown() {
        User.shared.selectedSearchEngineID = previousEngineID
        User.shared.aiFreeSearching = previousAIFreeSearching
        User.shared.aiOverviews = previousAIOverviews
        Unleash.model = Unleash.Model()
        SearchRouterConfiguration.invalidateCache()
        // Drain async `searchSettingsChanged` posts, or they land in whichever
        // suite counts notifications next.
        RunLoop.main.run(until: Date().addingTimeInterval(0.05))
        super.tearDown()
    }

    // MARK: - Router off, Ecosia AI on

    func testRouterOffKeepsEcosiaFullStack() {
        configureUnleash(routerEnabled: false)
        User.shared.selectedSearchEngineID = "google"

        XCTAssertEqual(SearchProviderSelection.aiBehavior, .ecosiaFullStack)
        XCTAssertTrue(SearchProviderSelection.showsOmniboxAIFeatures)
        XCTAssertTrue(SearchProviderSelection.showsAIAutocompleteRow)
        XCTAssertTrue(SearchProviderSelection.allowsChatModes)
    }

    // MARK: - Router on, AI capabilities on

    func testFullModeKeepsModesSelectableForEveryProvider() {
        configureUnleash(routerEnabled: true, aiMode: "full")

        for provider in SearchProvider.allCases {
            User.shared.selectedSearchEngineID = provider.rawValue
            XCTAssertTrue(SearchProviderSelection.allowsChatModes, "\(provider) cannot select modes")
            XCTAssertTrue(SearchProviderSelection.showsOmniboxAIFeatures, "\(provider) has no entry point")
        }
    }

    // MARK: - Router on, entry point redirects

    func testRedirectModeDisablesModesButKeepsTheEntryPoint() {
        configureUnleash(routerEnabled: true, aiMode: "redirect")

        for provider in SearchProvider.allCases {
            User.shared.selectedSearchEngineID = provider.rawValue
            XCTAssertEqual(SearchProviderSelection.aiBehavior, .redirect(provider))
            XCTAssertTrue(SearchProviderSelection.showsOmniboxAIFeatures, "\(provider) lost its entry point")
            XCTAssertFalse(SearchProviderSelection.allowsChatModes, "\(provider) can still select modes")
        }
    }

    func testRedirectModeResolvesAnEntryPointForEveryProvider() {
        for provider in SearchProvider.allCases {
            XCTAssertNotNil(SearchProviderAIRouting.aiEntryPointURL(for: provider, query: "trees"),
                            "\(provider) has no entry point destination")
        }
    }

    /// Tapping the entry point with nothing typed opens the provider's AI home.
    func testRedirectModeFallsBackToTheAIHomeWhenNothingIsTyped() throws {
        for provider in SearchProvider.allCases {
            let url = try XCTUnwrap(SearchProviderAIRouting.aiEntryPointURL(for: provider, query: "   "))
            XCTAssertNil(URLComponents(url: url, resolvingAgainstBaseURL: false)?
                .queryItems?.first { $0.name == "q" },
                         "\(provider) carried an empty query")
        }
    }

    /// The omnibox text is optional, so an absent value behaves like an empty one.
    func testRedirectModeFallsBackToTheAIHomeWhenThereIsNoText() throws {
        for provider in SearchProvider.allCases {
            let url = try XCTUnwrap(SearchProviderAIRouting.aiEntryPointURL(for: provider, query: nil))
            XCTAssertNil(URLComponents(url: url, resolvingAgainstBaseURL: false)?
                .queryItems?.first { $0.name == "q" },
                         "\(provider) carried a query with no text")
        }
    }

    func testRedirectModeCarriesTypedTextThrough() throws {
        let url = try XCTUnwrap(SearchProviderAIRouting.aiEntryPointURL(for: .perplexity, query: "trees"))
        let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems

        XCTAssertEqual(items?.first { $0.name == "q" }?.value, "trees")
    }

    // MARK: - Router on, entry point hidden

    /// Hidden mode removes the omnibox entry point. The suggestion row is not part of it and
    /// is covered separately in `SearchProviderSelectionTests`.
    func testHiddenModeRemovesTheOmniboxEntryPoint() {
        configureUnleash(routerEnabled: true, aiMode: "hidden")

        for provider in SearchProvider.allCases {
            User.shared.selectedSearchEngineID = provider.rawValue
            XCTAssertEqual(SearchProviderSelection.aiBehavior, .hidden)
            XCTAssertFalse(SearchProviderSelection.showsOmniboxAIFeatures)
            XCTAssertFalse(SearchProviderSelection.allowsChatModes)
        }
    }

    /// Hiding the entry point is a remote switch, not the user-facing AI-free preference:
    /// it must not touch Overviews or the stored opt-out.
    func testHiddenModeLeavesTheAIFreePreferenceAlone() {
        User.shared.aiFreeSearching = nil
        User.shared.aiOverviews = true
        configureUnleash(routerEnabled: true, aiMode: "hidden")
        User.shared.selectedSearchEngineID = "ecosia"

        XCTAssertEqual(SearchProviderSelection.aiBehavior, .hidden)
        XCTAssertNil(User.shared.aiFreeSearching)
        XCTAssertTrue(User.shared.aiOverviews)
    }

    /// AI-free searching drops `ar=1`; hiding the entry point must not.
    func testHiddenModeKeepsBackendAutorouting() {
        User.shared.aiFreeSearching = nil
        configureUnleash(routerEnabled: true, aiMode: "hidden")
        User.shared.selectedSearchEngineID = "ecosia"

        let url = SearchProviderRouting.omniboxSearchURL(forQuery: "trees", engineID: "ecosia")

        XCTAssertTrue(url.absoluteString.contains("ar=1"))
    }

    // MARK: - Helpers

    private func configureUnleash(routerEnabled: Bool,
                                  aiMode: String = "full",
                                  aiFreeSearchingEnabled: Bool = false) {
        var model = Unleash.Model()
        model.toggles.insert(makeToggle(.customSearchProvider,
                                        enabled: routerEnabled,
                                        payload: "{\"aiMode\": \"\(aiMode)\"}"))
        model.toggles.insert(makeToggle(.aiFreeSearching, enabled: aiFreeSearchingEnabled))
        model.toggles.insert(makeToggle(.fileUpload, enabled: true))
        model.toggles.insert(makeToggle(.chatModes, enabled: true))
        Unleash.model = model
        SearchRouterConfiguration.invalidateCache()
    }

    private func makeToggle(_ name: Unleash.Toggle.Name,
                            enabled: Bool,
                            payload: String? = nil) -> Unleash.Toggle {
        Unleash.Toggle(name: name.rawValue,
                       enabled: enabled,
                       variant: .init(name: "config",
                                      enabled: true,
                                      payload: payload.map { .init(type: "json", value: $0) }))
    }
}
