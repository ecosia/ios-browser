// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Shared
import XCTest
@testable import Client
@testable import Ecosia

/// AI-free searching replaces Firefox's AI controls hub: while it is on, Firefox's page
/// summaries and translations are switched off (upgrade ticket 09, MOB-5035).
@MainActor
final class AIFreeSearchingBrowserAITests: XCTestCase {

    private let profile = MockProfile()

    override func setUp() {
        super.setUp()
        DependencyHelperMock().bootstrapDependencies(injectedProfile: profile)
        User.shared.aiFreeSearching = nil
        User.shared.selectedSearchEngineID = SearchProvider.ecosia.rawValue
        Unleash.clearInstanceModel()
    }

    override func tearDown() {
        User.shared.aiFreeSearching = nil
        User.shared.selectedSearchEngineID = SearchProvider.ecosia.rawValue
        Unleash.clearInstanceModel()
        DependencyHelperMock().reset()
        super.tearDown()
    }

    // MARK: - Translations

    func testTranslationsFollowNimbusWhileAIFreeIsOff() {
        setAIFreeSearching(flag: true, userValue: false)

        XCTAssertTrue(makeFeatureFlags().isEnabled(.translation))
    }

    func testTranslationsAreOffWhileAIFreeIsOn() {
        setAIFreeSearching(flag: true, userValue: true)

        XCTAssertFalse(makeFeatureFlags().isEnabled(.translation))
    }

    func testTranslationsFollowNimbusWhenTheToggleIsNotOffered() {
        setAIFreeSearching(flag: false, userValue: true)

        XCTAssertTrue(makeFeatureFlags().isEnabled(.translation))
    }

    func testAIFreeLeavesOtherFlagsAlone() {
        setAIFreeSearching(flag: true, userValue: true)

        XCTAssertTrue(makeFeatureFlags().isEnabled(.translationLanguagePicker))
    }

    // MARK: - Page summaries

    func testSummariesAreOnWhileAIFreeIsOff() {
        setAIFreeSearching(flag: true, userValue: false)

        XCTAssertTrue(makeSummarizerUtils().isSummarizeFeatureToggledOn)
    }

    func testSummariesAreOffWhileAIFreeIsOn() {
        setAIFreeSearching(flag: true, userValue: true)
        let subject = makeSummarizerUtils()

        XCTAssertFalse(subject.isSummarizeFeatureToggledOn)
        XCTAssertFalse(subject.isToolbarButtonEnabled)
        XCTAssertFalse(subject.isShakeGestureEnabled)
    }

    /// Where the toggle is not offered, Settings shows Firefox's Summarize row instead, which
    /// needs the device check alone.
    func testSummariesStayAvailableForTheirOwnSettingsRowWhileAIFreeIsOn() {
        setAIFreeSearching(flag: true, userValue: true)

        XCTAssertTrue(makeSummarizerUtils().isSummarizeFeatureEnabled)
    }

    // MARK: - Helpers

    private func makeFeatureFlags() -> FeatureFlagsProvider {
        FeatureFlagsProvider(prefs: profile.prefs, backendLayer: AllFlagsOnNimbusLayer())
    }

    /// A device that can summarize on-device, in English.
    private func makeSummarizerUtils() -> DefaultSummarizerNimbusUtils {
        .make(profile: profile, appleIntelligenceAvailable: true)
    }

    private func setAIFreeSearching(flag: Bool, userValue: Bool) {
        let toggle = Unleash.Toggle(
            name: Unleash.Toggle.Name.aiFreeSearching.rawValue,
            enabled: flag,
            variant: Unleash.Variant(name: "", enabled: false, payload: nil)
        )
        Unleash.model = Unleash.Model(toggles: Set([toggle]))
        User.shared.aiFreeSearching = userValue
    }
}
