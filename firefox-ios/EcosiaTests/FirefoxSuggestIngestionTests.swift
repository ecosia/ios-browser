// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import MozillaAppServices
import Shared
import Storage
import XCTest
@testable import Client

/// Ecosia ships Firefox Suggest off, so the app must not ingest Mozilla's `quicksuggest-*`
/// Remote Settings data on foreground.
@MainActor
final class FirefoxSuggestIngestionTests: XCTestCase {
    private let firefoxSuggest = SpyFirefoxSuggest()
    private lazy var profile = MockProfile(firefoxSuggest: firefoxSuggest)

    override func tearDown() {
        DependencyHelperMock().reset()
        super.tearDown()
    }

    func testFirefoxSuggestIsOffByDefault() {
        DependencyHelperMock().bootstrapDependencies(
            injectedProfile: profile,
            injectedFeatureFlagProvider: FeatureFlagsProvider(prefs: profile.prefs)
        )

        XCTAssertFalse(AppDelegate().isFirefoxSuggestIngestionEnabled)
    }

    func testIngestFirefoxSuggestions_withFeatureOff_doesNotIngest() {
        let subject = makeSubject(backendLayer: AllFlagsOffNimbusLayer())
        let ingested = expectation(description: "ingest")
        ingested.isInverted = true
        firefoxSuggest.onIngest = { _ in ingested.fulfill() }

        subject.ingestFirefoxSuggestions(in: .shared)

        wait(for: [ingested], timeout: 0.5)
        XCTAssertTrue(firefoxSuggest.ingestCalls.isEmpty)
    }

    func testIngestFirefoxSuggestions_withFeatureOn_ingestsEmptyStoreOnly() {
        let subject = makeSubject(backendLayer: AllFlagsOnNimbusLayer())
        let ingested = expectation(description: "ingest")
        firefoxSuggest.onIngest = { _ in ingested.fulfill() }

        subject.ingestFirefoxSuggestions(in: .shared)

        wait(for: [ingested], timeout: 2)
        XCTAssertEqual(firefoxSuggest.ingestCalls, [true])
    }

    private func makeSubject(backendLayer: NimbusFeatureFlagLayerProviding) -> AppDelegate {
        DependencyHelperMock().bootstrapDependencies(
            injectedProfile: profile,
            injectedFeatureFlagProvider: FeatureFlagsProvider(prefs: profile.prefs, backendLayer: backendLayer)
        )
        let appDelegate = AppDelegate()
        appDelegate.profile = profile
        return appDelegate
    }
}

/// A Nimbus layer that reports every feature flag as off.
private struct AllFlagsOffNimbusLayer: NimbusFeatureFlagLayerProviding {
    func checkNimbusConfigFor(_ featureID: FeatureFlagID, with prefs: Prefs) -> Bool { false }
    func checkStartAtHomeConfiguration() -> StartAtHome { .afterFourHours }
}

private final class SpyFirefoxSuggest: RustFirefoxSuggestProtocol, @unchecked Sendable {
    private(set) var ingestCalls: [Bool] = []
    var onIngest: ((Bool) -> Void)?

    func ingest(emptyOnly: Bool) async throws {
        ingestCalls.append(emptyOnly)
        onIngest?(emptyOnly)
    }

    func query(
        _ keyword: String,
        providers: [SuggestionProvider],
        limit: Int32
    ) async throws -> [RustFirefoxSuggestion] {
        []
    }

    func interruptReader() {}

    func interruptEverything() {}
}
