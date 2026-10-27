// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Redux
import XCTest
@testable import Client
@testable import Ecosia

/// AI-free searching applies only with Ecosia, so changing the search provider can switch page
/// summaries and translations on or off. The open window's toolbar must hear about it, as it
/// does when the toggle itself changes (MOB-5035).
@MainActor
final class BrowserAIRefreshTests: XCTestCase, StoreTestUtility {
    // swiftlint:disable:next implicitly_unwrapped_optional
    private var mockStore: MockStoreForMiddleware<AppState>!
    private let profile = MockProfile()

    override func setUp() async throws {
        try await super.setUp()
        DependencyHelperMock().bootstrapDependencies()
        setupStore()
        Unleash.model = Unleash.Model(toggles: Set([
            makeToggle(.aiFreeSearching),
            makeToggle(.customSearchProvider)
        ]))
        User.shared.selectedSearchEngineID = SearchProvider.ecosia.rawValue
    }

    override func tearDown() async throws {
        Unleash.clearInstanceModel()
        User.shared.aiFreeSearching = nil
        User.shared.selectedSearchEngineID = SearchProvider.ecosia.rawValue
        resetStore()
        DependencyHelperMock().reset()
        try await super.tearDown()
    }

    func testLeavingEcosiaWithAIFreeSearchingOnRefreshesTheToolbar() {
        User.shared.aiFreeSearching = true

        switchProvider(to: .duckduckgo)

        XCTAssertEqual(dispatchedRefreshes, [.didSummarizeSettingsChange, .didTranslationSettingsChange])
    }

    func testReturningToEcosiaWithAIFreeSearchingOnRefreshesTheToolbar() {
        User.shared.aiFreeSearching = true
        User.shared.selectedSearchEngineID = SearchProvider.duckduckgo.rawValue

        switchProvider(to: .ecosia)

        XCTAssertEqual(dispatchedRefreshes, [.didSummarizeSettingsChange, .didTranslationSettingsChange])
    }

    /// The refresh also resets the window's translation target language, so it is not sent
    /// when nothing changes for page summaries and translations.
    func testSwitchingProviderWithAIFreeSearchingOffSendsNothing() {
        User.shared.aiFreeSearching = false

        switchProvider(to: .duckduckgo)

        XCTAssertTrue(mockStore.dispatchedActions.isEmpty)
    }

    func testSwitchingBetweenOtherProvidersSendsNothing() {
        User.shared.aiFreeSearching = true
        User.shared.selectedSearchEngineID = SearchProvider.duckduckgo.rawValue

        switchProvider(to: .perplexity)

        XCTAssertTrue(mockStore.dispatchedActions.isEmpty)
    }

    // MARK: - Helpers

    private enum Refresh: Equatable {
        case didSummarizeSettingsChange, didTranslationSettingsChange, other
    }

    private var dispatchedRefreshes: [Refresh] {
        mockStore.dispatchedActions.map { action in
            switch action.actionType {
            case ToolbarActionType.didSummarizeSettingsChange: return .didSummarizeSettingsChange
            case TranslationsActionType.didTranslationSettingsChange: return .didTranslationSettingsChange
            default: return .other
            }
        }
    }

    private func switchProvider(to provider: SearchProvider) {
        BrowserAIRefresh.dispatchIfChanged(prefs: profile.prefs, windowUUID: .XCTestDefaultUUID) {
            User.shared.selectedSearchEngineID = provider.rawValue
        }
    }

    private func makeToggle(_ name: Unleash.Toggle.Name) -> Unleash.Toggle {
        Unleash.Toggle(name: name.rawValue,
                       enabled: true,
                       variant: Unleash.Variant(name: "", enabled: false, payload: nil))
    }

    // MARK: - StoreTestUtility

    func setupAppState() -> AppState {
        AppState()
    }

    func setupStore() {
        mockStore = MockStoreForMiddleware(state: setupAppState())
        StoreTestUtilityHelper.setupStore(with: mockStore)
    }

    func resetStore() {
        StoreTestUtilityHelper.resetStore()
    }
}
