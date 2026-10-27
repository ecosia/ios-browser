// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Shared
import XCTest
@testable import Client

/// Page summaries run on-device only (upgrade ticket 07, MOB-5033). Every summaries entry point
/// (shake, toolbar button, main menu, reader-mode buttons) reads `DefaultSummarizerNimbusUtils`,
/// so a device that cannot summarize on-device must get no entry point, even when Nimbus switches
/// every hosted-summarizer flag on.
@MainActor
final class OnDeviceSummariesTests: XCTestCase {

    private let profile = MockProfile()

    override func setUp() {
        super.setUp()
        DependencyHelperMock().bootstrapDependencies(
            injectedProfile: profile,
            injectedFeatureFlagProvider: FeatureFlagsProvider(prefs: profile.prefs, backendLayer: AllFlagsOnNimbusLayer())
        )
    }

    override func tearDown() {
        DependencyHelperMock().reset()
        super.tearDown()
    }

    /// Covers devices without Apple Intelligence, iOS before 26, and the `SKIP_APPLE_INTELLIGENCE`
    /// launch argument: all of them leave `appleIntelligenceAvailable` false.
    func testUnsupportedDeviceHasNoSummariesEntryPoint() {
        let subject = makeSubject(appleIntelligenceAvailable: false)

        XCTAssertFalse(subject.isSummarizeFeatureEnabled, "Settings rows")
        XCTAssertFalse(subject.isSummarizeFeatureToggledOn, "Main menu, reader mode, presenting the panel")
        XCTAssertFalse(subject.isToolbarButtonEnabled, "Address-bar button")
        XCTAssertFalse(subject.isShakeGestureEnabled, "Shake gesture")
    }

    func testHostedSummarizerStaysOffWhenNimbusEnablesIt() {
        let subject = makeSubject(appleIntelligenceAvailable: false)

        XCTAssertFalse(subject.isHostedSummarizerEnabled())
    }

    /// Guards the test above against passing for the wrong reason.
    func testSupportedDeviceHasSummariesEntryPoints() {
        let subject = makeSubject(appleIntelligenceAvailable: true)

        XCTAssertTrue(subject.isSummarizeFeatureToggledOn)
        XCTAssertTrue(subject.isToolbarButtonEnabled)
        XCTAssertTrue(subject.isShakeGestureEnabled)
    }

    // MARK: - Helpers

    private func makeSubject(appleIntelligenceAvailable: Bool) -> DefaultSummarizerNimbusUtils {
        .make(profile: profile, appleIntelligenceAvailable: appleIntelligenceAvailable)
    }
}
