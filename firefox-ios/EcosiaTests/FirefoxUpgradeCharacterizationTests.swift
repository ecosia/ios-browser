// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import XCTest
@testable import Client
@testable import Ecosia

/// Characterization tests for the Ecosia behaviors carrying the most business risk across a Firefox
/// upgrade. Written against the pre-upgrade tree and re-run unchanged afterwards: a failure here means
/// the upgrade changed Ecosia behavior, not that the test needs updating.
///
@MainActor
final class FirefoxUpgradeCharacterizationTests: XCTestCase {

    private var previousUnleashModel = Unleash.Model()

    override func setUp() {
        super.setUp()
        previousUnleashModel = Unleash.model
        InvisibleTabManager.shared.clearAllInvisibleTabs()
    }

    override func tearDown() {
        InvisibleTabManager.shared.clearAllInvisibleTabs()
        Unleash.model = previousUnleashModel
        SearchRouterConfiguration.invalidateCache()
        super.tearDown()
    }

    // MARK: - 1. Default search engine identity

    func testDefaultEngineIsEcosiaAndFailsUpstreamGoogleIdentityCheck() throws {
        setCustomSearchProvider(enabled: false)

        let engines = try orderedEngines(from: SearchEngineProviderFactory.defaultSearchEngineProvider)
        let defaultEngine = try XCTUnwrap(engines.first, "A default engine must always resolve")

        XCTAssertEqual(
            defaultEngine.engineID,
            "ecosia",
            "Ecosia must resolve as the default engine on every locale/region"
        )
        XCTAssertFalse(defaultEngine.isGoogleEngine,
                       "The default engine must fail upstream's Google identity check — that check is what "
                       + "keeps the Google Lens entry point hidden for Ecosia users")
        XCTAssertFalse(defaultEngine.isCustomEngine,
                       "Ecosia's own engine must not be classified as a user-added custom engine")
    }

    /// The curated provider is the other branch of `SearchEngineProviderFactory`; whichever branch the flag
    /// selects, the default must never satisfy upstream's Google check.
    func testCuratedProviderDefaultEngineAlsoFailsUpstreamGoogleIdentityCheck() throws {
        setCustomSearchProvider(enabled: true)

        let engines = try orderedEngines(from: SearchEngineProviderFactory.defaultSearchEngineProvider)
        let defaultEngine = try XCTUnwrap(engines.first, "A default engine must always resolve")

        XCTAssertFalse(defaultEngine.isGoogleEngine,
                       "Google must never be the default engine, on either provider branch")
    }

    // MARK: - 2. Invisible tab / auth session flow

    /// The invariant the auth flow depends on: the tab it opens to transfer the web session must never be
    /// counted or listed anywhere the user can see it. These accessors read `TabManager.tabs`/`normalTabs`/
    /// `privateTabs`, all Firefox-core surfaces, so an upstream change to them silently breaks this.
    func testInvisibleTabsAreExcludedFromEveryVisibleTabCollection() {
        let tabManager = MockTabManager()
        let visible = makeTab(windowUUID: tabManager.windowUUID)
        let authTab = makeTab(windowUUID: tabManager.windowUUID)
        let privateTab = makeTab(windowUUID: tabManager.windowUUID, isPrivate: true)
        tabManager.tabs = [visible, authTab, privateTab]
        tabManager.normalTabs = [visible, authTab]
        tabManager.privateTabs = [privateTab]

        authTab.isInvisible = true

        XCTAssertEqual(tabManager.visibleTabCount, 2)
        XCTAssertEqual(tabManager.invisibleTabCount, 1)
        XCTAssertEqual(tabManager.visibleNormalTabs.map { $0.tabUUID }, [visible.tabUUID])
        XCTAssertEqual(tabManager.visiblePrivateTabs.map { $0.tabUUID }, [privateTab.tabUUID])
        XCTAssertEqual(tabManager.invisibleTabs.map { $0.tabUUID }, [authTab.tabUUID])
        XCTAssertFalse(tabManager.visibleTabs.contains { $0.tabUUID == authTab.tabUUID },
                       "The auth transfer tab must never appear in the visible tab list")
    }

    /// `Tab.isInvisible` is the bridge core code reads; it must round-trip through the registry rather than
    /// storing state on the tab, because the tab is torn down before the session's completion handler runs.
    func testTabInvisibleFlagRoundTripsThroughTheRegistry() {
        let tab = makeTab()

        XCTAssertFalse(tab.isInvisible)

        tab.markAsInvisible()
        XCTAssertTrue(tab.isInvisible)
        XCTAssertTrue(InvisibleTabManager.shared.isTabInvisible(tab))

        tab.markAsVisible()
        XCTAssertFalse(tab.isInvisible)
        XCTAssertFalse(InvisibleTabManager.shared.isTabInvisible(tab))
    }

    /// Without this pruning the registry leaks UUIDs of closed auth tabs, and a later tab that reuses a
    /// UUID would be invisible to the user for no reason.
    func testClosingAnInvisibleTabPrunesItFromTheRegistry() {
        let tabManager = MockTabManager()
        let kept = makeTab(windowUUID: tabManager.windowUUID)
        let closed = makeTab(windowUUID: tabManager.windowUUID)
        kept.isInvisible = true
        closed.isInvisible = true
        tabManager.tabs = [kept]

        tabManager.cleanupInvisibleTabTracking()

        XCTAssertTrue(InvisibleTabManager.shared.isTabInvisible(kept))
        XCTAssertFalse(InvisibleTabManager.shared.isTabInvisible(closed))
    }

    // MARK: - 3. NTP impact counter

    /// Counter values are formatted with a forced "," grouping separator and an explicit currency symbol,
    /// so the rendered figures are stable regardless of device locale.
    func testImpactCounterFormatsValuesWithStableGroupingAndCurrencySymbol() {
        let treesTitle = ClimateImpactInfo.totalTrees(value: 1234).title
        let investedTitle = ClimateImpactInfo.totalInvested(value: 1234).title

        XCTAssertTrue(treesTitle.contains("1,234"), "Got \(treesTitle)")
        XCTAssertFalse(treesTitle.contains("€"), "The tree counter must not render a currency symbol")
        XCTAssertTrue(investedTitle.contains("1,234"), "Got \(investedTitle)")
        XCTAssertTrue(investedTitle.contains("€"), "The invested counter must render the euro symbol")
        XCTAssertEqual(ClimateImpactInfo.referral(value: 7).title, "7")
    }

    /// UI tests and snapshot references key off these identifiers, and the deep links are the counters' only
    /// user-facing action. Both are pure Ecosia contract, easy to lose in a merge of the surrounding cell code.
    func testImpactCounterIdentifiersAndDeepLinksAreStable() {
        let urlProvider = EcosiaEnvironment.current.urlProvider

        XCTAssertEqual(ClimateImpactInfo.totalTrees(value: 0).accessibilityIdentifier,
                       EcosiaAccessibilityIdentifiers.NTP.ClimateImpact.totalTreesCount)
        XCTAssertEqual(ClimateImpactInfo.totalInvested(value: 0).accessibilityIdentifier,
                       EcosiaAccessibilityIdentifiers.NTP.ClimateImpact.totalInvestedCount)
        XCTAssertEqual(ClimateImpactInfo.referral(value: 0).accessibilityIdentifier,
                       EcosiaAccessibilityIdentifiers.NTP.ClimateImpact.friendsAndTreesInvitesCounter)

        XCTAssertEqual(ClimateImpactInfo.totalTrees(value: 0).destinationURL, urlProvider.trees)
        XCTAssertEqual(ClimateImpactInfo.totalInvested(value: 0).destinationURL, urlProvider.financialReports)
        XCTAssertNil(ClimateImpactInfo.referral(value: 0).destinationURL,
                     "The referral tile opens the invite flow, not a URL")
    }

    /// `rawValue` is how the cell matches a refresh to a row without comparing associated values; a reordering
    /// would silently route tree updates into the invested row.
    func testImpactCounterRowOrderingIsStable() {
        XCTAssertEqual(ClimateImpactInfo.referral(value: 0).rawValue, 0)
        XCTAssertEqual(ClimateImpactInfo.totalTrees(value: 0).rawValue, 1)
        XCTAssertEqual(ClimateImpactInfo.totalInvested(value: 0).rawValue, 2)
    }

    // MARK: - Helpers

    private func orderedEngines(from provider: SearchEngineProvider) throws -> [OpenSearchEngine] {
        let expectation = expectation(description: "getOrderedEngines completes")
        var result: [OpenSearchEngine] = []
        provider.getOrderedEngines(
            customEngines: [],
            engineOrderingPrefs: SearchEnginePrefs(engineIdentifiers: nil, disabledEngines: nil, version: .v2),
            prefsMigrator: DefaultSearchEnginePrefsMigrator()
        ) { _, engines in
            result = engines
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 5)
        return result
    }

    private func makeTab(windowUUID: WindowUUID = .XCTestDefaultUUID, isPrivate: Bool = false) -> Client.Tab {
        Client.Tab(profile: MockProfile(), isPrivate: isPrivate, windowUUID: windowUUID)
    }

    private func setCustomSearchProvider(enabled: Bool) {
        var model = Unleash.Model()
        model.toggles.insert(
            Unleash.Toggle(name: Unleash.Toggle.Name.customSearchProvider.rawValue,
                           enabled: enabled,
                           variant: .init(name: "config", enabled: true, payload: nil))
        )
        Unleash.model = model
        SearchRouterConfiguration.invalidateCache()
    }
}
