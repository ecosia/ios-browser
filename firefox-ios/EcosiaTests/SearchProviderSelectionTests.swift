// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Ecosia
import XCTest
@testable import Client

@MainActor
final class SearchProviderSelectionTests: XCTestCase {

    private var previousEngineID = ""
    private var previousAIFreeSearching: Bool?

    override func setUp() {
        super.setUp()
        previousEngineID = User.shared.selectedSearchEngineID
        previousAIFreeSearching = User.shared.aiFreeSearching
    }

    override func tearDown() {
        User.shared.selectedSearchEngineID = previousEngineID
        User.shared.aiFreeSearching = previousAIFreeSearching
        Unleash.model = Unleash.Model()
        SearchRouterConfiguration.invalidateCache()
        super.tearDown()
    }

    // MARK: - Selected provider

    func testSelectedProviderIsEcosiaWhenRouterIsOff() {
        configureUnleash(routerEnabled: false)
        User.shared.selectedSearchEngineID = "google"

        XCTAssertEqual(SearchProviderSelection.selectedProvider, .ecosia)
        XCTAssertTrue(SearchProviderSelection.isEcosiaDefault)
    }

    func testSelectedProviderFollowsPersistedIdentifier() {
        configureUnleash(routerEnabled: true)
        User.shared.selectedSearchEngineID = "perplexity"

        XCTAssertEqual(SearchProviderSelection.selectedProvider, .perplexity)
        XCTAssertFalse(SearchProviderSelection.isEcosiaDefault)
    }

    /// A persisted identifier we do not offer, for example after a downgrade. Must not be
    /// a name in the catalog.
    func testUnknownPersistedIdentifierFallsBackToEcosia() {
        configureUnleash(routerEnabled: true)
        User.shared.selectedSearchEngineID = "yahoo"

        XCTAssertEqual(SearchProviderSelection.selectedProvider, .ecosia)
    }

    // MARK: - Behaviour matrix

    func testRouterOffAlwaysGivesEcosiaFullStack() {
        configureUnleash(routerEnabled: false)
        User.shared.selectedSearchEngineID = "perplexity"

        XCTAssertEqual(SearchProviderSelection.aiBehavior, .ecosiaFullStack)
    }

    func testFullModeGivesEcosiaFullStackForEcosia() {
        configureUnleash(routerEnabled: true, aiMode: "full")
        User.shared.selectedSearchEngineID = "ecosia"

        XCTAssertEqual(SearchProviderSelection.aiBehavior, .ecosiaFullStack)
        XCTAssertTrue(SearchProviderSelection.usesEcosiaAIBackend)
    }

    func testFullModeGivesProviderAIForThirdParties() {
        configureUnleash(routerEnabled: true, aiMode: "full")

        for provider in SearchProvider.allCases where provider != .ecosia {
            User.shared.selectedSearchEngineID = provider.rawValue
            XCTAssertEqual(SearchProviderSelection.aiBehavior, .providerAI(provider))
            XCTAssertFalse(SearchProviderSelection.usesEcosiaAIBackend)
        }
    }

    func testRedirectModeAppliesToEveryProviderIncludingEcosia() {
        configureUnleash(routerEnabled: true, aiMode: "redirect")

        for provider in SearchProvider.allCases {
            User.shared.selectedSearchEngineID = provider.rawValue
            XCTAssertEqual(SearchProviderSelection.aiBehavior, .redirect(provider))
        }
    }

    func testHiddenModeAppliesToEveryProvider() {
        configureUnleash(routerEnabled: true, aiMode: "hidden")

        for provider in SearchProvider.allCases {
            User.shared.selectedSearchEngineID = provider.rawValue
            XCTAssertEqual(SearchProviderSelection.aiBehavior, .hidden)
        }
    }

    // MARK: - AI-free searching

    func testAIFreeSearchingHidesTheEntryPointForEcosia() {
        configureUnleash(routerEnabled: true, aiMode: "full", aiFreeSearchingEnabled: true)
        User.shared.selectedSearchEngineID = "ecosia"
        AIFreeSearchingSelection.setEnabled(true)

        XCTAssertEqual(SearchProviderSelection.aiBehavior, .hidden)
    }

    /// The AI-free row is hidden for third-party providers, so it must not disable an
    /// entry point the user would have no way to restore.
    func testAIFreeSearchingDoesNotAffectThirdPartyProviders() {
        configureUnleash(routerEnabled: true, aiMode: "full", aiFreeSearchingEnabled: true)
        User.shared.selectedSearchEngineID = "google"
        AIFreeSearchingSelection.setEnabled(true)

        XCTAssertEqual(SearchProviderSelection.aiBehavior, .providerAI(.google))
    }

    func testAIFreeSearchingOffLeavesEcosiaFullStack() {
        configureUnleash(routerEnabled: true, aiMode: "full", aiFreeSearchingEnabled: true)
        User.shared.selectedSearchEngineID = "ecosia"
        AIFreeSearchingSelection.setEnabled(false)

        XCTAssertEqual(SearchProviderSelection.aiBehavior, .ecosiaFullStack)
    }

    // MARK: - Autocomplete row

    func testAutocompleteRowIsHiddenForConversationalProviders() {
        configureUnleash(routerEnabled: true, aiMode: "full")

        User.shared.selectedSearchEngineID = "perplexity"
        XCTAssertFalse(SearchProviderSelection.showsAIAutocompleteRow)

        User.shared.selectedSearchEngineID = "perplexity"
        XCTAssertFalse(SearchProviderSelection.showsAIAutocompleteRow)
    }

    func testAutocompleteRowIsShownForSearchProviders() {
        configureUnleash(routerEnabled: true, aiMode: "full")

        for id in ["ecosia", "google", "duckduckgo"] {
            User.shared.selectedSearchEngineID = id
            XCTAssertTrue(SearchProviderSelection.showsAIAutocompleteRow, "expected a row for \(id)")
        }
    }

    /// Hiding the omnibox entry point does not remove the suggestion row: it stays wherever
    /// the provider has a separate AI to offer.
    func testAutocompleteRowSurvivesHiddenMode() {
        configureUnleash(routerEnabled: true, aiMode: "hidden")

        for id in ["ecosia", "google", "duckduckgo", "bing"] {
            User.shared.selectedSearchEngineID = id
            XCTAssertTrue(SearchProviderSelection.showsAIAutocompleteRow, "expected a row for \(id)")
        }

        User.shared.selectedSearchEngineID = "perplexity"
        XCTAssertFalse(SearchProviderSelection.showsAIAutocompleteRow,
                       "conversational providers never get a separate row")
    }

    /// AI-free searching is the user's own opt-out, so it does remove the row.
    func testAutocompleteRowIsHiddenWhenAIFreeSearchingIsActive() {
        configureUnleash(routerEnabled: true, aiMode: "full", aiFreeSearchingEnabled: true)
        User.shared.selectedSearchEngineID = "ecosia"
        User.shared.aiFreeSearching = true

        XCTAssertFalse(SearchProviderSelection.showsAIAutocompleteRow)
    }

    // MARK: - Omnibox upload control

    func testUploadControlIsHiddenInHiddenMode() {
        configureUnleash(routerEnabled: true, aiMode: "hidden")
        User.shared.selectedSearchEngineID = "ecosia"

        XCTAssertFalse(SearchProviderSelection.showsOmniboxAIFeatures)
    }

    func testUploadControlIsShownForThirdPartyProviders() {
        configureUnleash(routerEnabled: true, aiMode: "full")
        User.shared.selectedSearchEngineID = "duckduckgo"

        XCTAssertTrue(SearchProviderSelection.showsOmniboxAIFeatures)
    }

    /// Ecosia's control depends on its own two feature flags rather than on the router.
    func testEcosiaUploadControlFollowsItsOwnFeatureFlags() {
        User.shared.selectedSearchEngineID = "ecosia"

        configureUnleash(routerEnabled: true, aiMode: "full", fileUploadEnabled: false, chatModesEnabled: false)
        XCTAssertFalse(SearchProviderSelection.showsOmniboxAIFeatures)

        configureUnleash(routerEnabled: true, aiMode: "full", fileUploadEnabled: true, chatModesEnabled: false)
        XCTAssertTrue(SearchProviderSelection.showsOmniboxAIFeatures)
    }

    // MARK: - Ecosia-only settings

    func testEcosiaSettingsAreHiddenForThirdPartyProviders() {
        configureUnleash(routerEnabled: true)
        User.shared.selectedSearchEngineID = "google"

        XCTAssertFalse(SearchProviderSelection.showsEcosiaSearchSettings)
    }

    func testEcosiaSettingsStayVisibleWhenRouterIsOff() {
        configureUnleash(routerEnabled: false)
        User.shared.selectedSearchEngineID = "google"

        XCTAssertTrue(SearchProviderSelection.showsEcosiaSearchSettings)
    }

    func testPrepareSearchSettingsSectionResetsEngineIDWhenRouterIsOff() {
        configureUnleash(routerEnabled: false)
        User.shared.selectedSearchEngineID = "google"

        SearchProviderSelection.prepareSearchSettingsSection(defaultEngineID: "google")

        XCTAssertEqual(User.shared.selectedSearchEngineID, SearchProviderSelection.ecosiaEngineID)
    }

    func testPrepareSearchSettingsSectionSyncsDefaultEngineWhenRouterIsOn() {
        configureUnleash(routerEnabled: true)
        User.shared.selectedSearchEngineID = "ecosia"

        SearchProviderSelection.prepareSearchSettingsSection(defaultEngineID: "google")

        XCTAssertEqual(User.shared.selectedSearchEngineID, "google")
        XCTAssertFalse(SearchProviderSelection.showsEcosiaSearchSettings)
    }

    // MARK: - Helpers

    private func configureUnleash(routerEnabled: Bool,
                                  aiMode: String = "full",
                                  aiFreeSearchingEnabled: Bool = false,
                                  fileUploadEnabled: Bool = true,
                                  chatModesEnabled: Bool = true) {
        var model = Unleash.Model()
        model.toggles.insert(makeToggle(.customSearchProvider,
                                        enabled: routerEnabled,
                                        payload: "{\"aiMode\": \"\(aiMode)\"}"))
        model.toggles.insert(makeToggle(.aiFreeSearching, enabled: aiFreeSearchingEnabled))
        model.toggles.insert(makeToggle(.fileUpload, enabled: fileUploadEnabled))
        model.toggles.insert(makeToggle(.chatModes, enabled: chatModesEnabled))
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
